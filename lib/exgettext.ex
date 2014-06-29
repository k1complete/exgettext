defmodule Exgettext do
  def __using__(_opt) do
    :ok
  end
  def basedir() do
    "lang"
  end
  def pofile(_app, lang) do
    "#{lang}.po"
  end
  def mofile(app, lang) do
    "#{basedir()}/#{lang}/#{app}.exmo"
  end
  defmacro get_app( param \\ "" ) do
    to_string(Mix.Project.config[:app]) <> param
  end
  def locale_to_lang("C") do
    "en"
  end
  def locale_to_lang(nil) do
    "en"
  end
  def locale_to_lang(locale) do
    case Regex.run(~r/([^._]+)_([^._]+)\.([^.])+/, locale) do
      nil -> locale
      [^locale, lang, _country, _encoding] -> 
        lang
    end
  end
  def getlang() do
    locale_to_lang(System.get_env("LANG"))
  end
  def encode(s) do
    #:unicode.characters_to_list(s, :unicode)
    s
  end
  def put_dets(s, reference) do
    app_pot_db = get_app(".pot_db")
    {:ok, dets} = :dets.open_file(app_pot_db, [])
    k = encode(s)
    case :dets.lookup(dets, k) do
      [] -> :dets.insert(dets, {k, [reference]})
      [{^k, v}] ->
        :dets.insert(dets, {k, [reference | v]})
    end
    :dets.close(dets)
  end
  def relative(file, path) do
    Path.relative_to(file, path)
  end
  def getpath(lang) do
    mofile(get_app(), lang)
  end
  def gettext(key, lang) do
    dets_file = getpath(lang)
    case :dets.open_file(dets_file) do
      {:ok, dets} ->
        r = case :dets.lookup(dets, key) do
              [] -> key
              [{^key, ""}] -> key
              [{^key, value}] -> value
              {:error, _reason} -> key
            end
        :dets.close(dets)
        r
      {:error, _reason} ->
        key
    end
  end
  def gettext(key) do
    gettext(key, getlang())
  end
  @doc """
  ~T is detect to translate target string.
  """
  defmacro sigil_T({:<<>>, _line, [string]}, []) when is_binary(string) do
    binary = Macro.unescape_string(string)
    quote do: txt(unquote(binary))
  end
  defmacro txt(s) do
    r = __CALLER__
    path = System.get_env("PWD")
    put_dets(s, %{line: r.line, file: relative(r.file, path), function: r.function })
    quote do: Exgettext.gettext(unquote(s))
  end

  defmacro txt2(s, lang), do: quote do: Exgettext.gettext(unquote(s), unquote(lang))
end
defmodule Exgettext.Tool do
  def get_app() do
    Mix.Project.config[:app]
  end
  def get_app(type) do
    app = get_app()
    "#{app}.#{type}"
  end
  def escape(s) do
    s0 = Regex.replace(~r/\\/, s,~S(\\\\))
    s1 = Regex.replace(~r/\t/, s0, ~S(\\t))
    s2 = Regex.replace(~r/\n/, s1, ~S(\\n))
    s3 = Regex.replace(~r/\"/, s2,~S(\\\"))
    s3
  end
  @doc """
  parse po file, return maps %{msgid => msgstr}
  """
  def parse(_fh, :eof, ac) do
    ac
  end
  def parse(fh, r, ac) do
    r = skip_comment(fh, r)
    case r do 
      :eof ->
           ac
      r ->
        %{line: r, str: i} = get_msgid(fh, r)
        if (i) do
          %{line: r, str: str} = get_msgstr(fh, r)
          if (str) do
            ac = if (i != "") do
                   Map.put(ac, Macro.unescape_string(i), 
                                     Macro.unescape_string(str))
                 else
                   ac
                 end
            parse(fh, r, ac)
          end
        end
    end
  end
  @doc """
  parse skip comment (#, whitespaces line)
  """
  def skip_comment(_fh, :eof) do
    :eof
  end
  def skip_comment(fh, r) do
    case Regex.named_captures(~r/^(?<m>\s*|\#.*)$/, r) do
      nil -> r
      %{"m" => _m} -> 
        r = IO.binread(fh, :line)
        skip_comment(fh, r)
    end
  end
                                    
  def get_strline(_fh, :eof, ac) do
    %{line: :eof, str: ac}
  end                                   
  def get_strline(fh, r, ac) do
    case Regex.named_captures ~r/^\s*"(?<str>.*)"$/, r do
      nil -> %{line: r, str: ac}
      %{"str" => str} ->
        r = IO.binread(fh, :line)
        get_strline(fh, r, ac <> str)
    end
  end
  def get_msgid(fh, r) do
    %{"str" => str} = Regex.named_captures ~r/^\s*msgid\s+"(?<str>.*)"$/, r
    r = IO.binread(fh, :line)
    get_strline(fh, r, str)
  end
  def get_msgstr(fh, r) do
    %{"str" => str} = Regex.named_captures ~r/^\s*msgstr\s+"(?<str>.*)"$/, r
    r = IO.binread(fh, :line)
    get_strline(fh, r, str)
  end

  def convert_po(pfile) do
    {:ok, fh} = File.open(pfile)
    r = IO.binread(fh, :line)
    r = parse(fh, r, %{})
    File.close(fh)
    r
  end
  def msgfmt(pfile, outfile) do
    r = convert_po(pfile)
    {:ok, dets} = :dets.open_file(outfile,[])
    :dets.delete_all_objects(dets)
    :dets.insert(dets, (Enum.map Map.keys(r), &({&1, Map.get(r, &1)})))
    :dets.close(dets)
  end

  def line_split(s) do
    km = Enum.reverse String.split(s, "\n")
    [h | t] = km
    r = if (h === "") do
          Enum.map(t, fn(x) -> x <> "\n" end)
        else
          [h | Enum.map(t, fn(x) -> x <> "\n" end)]
        end
    Enum.reverse r
  end
  def modules(criteria) do
    :code.all_loaded |> Enum.filter_map fn({m, beam}) ->
                                            criteria.({m, beam})
                                        end,
                                        fn({m, _x}) -> m end
  end
  def moduledoc(modules) do
    result =modules |> Enum.map fn(x) ->
                                    case Code.get_docs(x, :moduledoc) do
                                      nil -> nil
                                      {l, d} ->
                                        ref = %{file: "#{x}",
                                                line: l}
                                        %{module: x, 
                                          name: "", 
                                          msgid: d,
                                          references: [ref],
                                          comment: "#{x} Summary"
                                         }
                                    end
                                end
    Enum.filter(result, fn(x) -> is_map(x) and is_binary(x.msgid) end) |> Enum.sort &(&1 < &2)
  end
  def funcdoc(modules) do
    r = modules |> List.foldr [], 
                        fn(m, a) ->
                            d = Code.get_docs(m, :docs)
                            case d do
                                  nil -> a
                                  d -> a ++ Enum.map d, 
                                            fn(x) -> 
                                                {{name, arity},line, type, arg, doc} = x
                                                ref = %{file: "#{m}.#{name}/#{arity}",
                                                        line: line}
                                                com = Macro.to_string {{:".", 
                                                                        [], 
                                                                        [m, name]}, 
                                                                       [], arg}
                                                %{module: m, 
                                                  name: name,
                                                  msgid: doc,
                                                  references: [ref],
                                                  comment: "#{type} #{com}"
                                                 }
                                            end
                            end

                        end 
    Enum.filter(r, fn(x) -> is_map(x) and is_binary(x.msgid) end) |> Enum.sort &(&1 < &2)
  end
  def doc(c \\ ~r/#{__MODULE__}/) do
    criteria = fn({m, _beam}) ->  Regex.match? c, Atom.to_string(m) end
    mod = modules(criteria)
    m = moduledoc(mod)
    f = funcdoc(mod)
    o = f ++ m|> Enum.sort &( &1.module < &2.module && &1.name < &2.name )
    Enum.map o, fn(x) -> %{x | msgid: line_split(x.msgid) } end
  end
  defp output(fh, r) do
    Enum.map(r, 
             fn(e) -> 
                 if (t = e[:comment]) do
                   IO.binwrite(fh, "#. TRANSLATORS: #{t}\n")
                 end
                 m = e[:references]
                 if ((length(m)) > 0) do
                   IO.binwrite(fh, "#: ")
                   Enum.map(m, fn(x) -> 
                                   IO.binwrite(fh, "#{x[:file]}:#{x[:line]} ") 
                               end)
                   IO.binwrite(fh, "\n")
                 end
                 IO.binwrite(fh, "msgid \"\"\n")
                 m = e[:msgid]
                 Enum.map(m, fn(x) -> 
                                 s = escape(x)
                                 IO.binwrite(fh, "\"")
                                 IO.binwrite(fh, s)
                                 IO.binwrite(fh, "\"\n") 
                             end)
                 IO.binwrite(fh, "msgstr \"\"\n")
             end)
  end
  def clean() do
    pot_db = get_app(:pot_db)
    {:ok, dets} = :dets.open_file(pot_db, [])
    :dets.delete_all_objects(dets)
    :dets.close(dets)
  end
  def xgettext() do
    pot_db = get_app(:pot_db)
    pot = get_app(:pot)
    {:ok, dets} = :dets.open_file(pot_db, [])
    r = :dets.foldl(fn(e, acc) -> [e|acc] end, [], dets) |>
      Enum.sort( fn({_k1, v1}, {_k2, v2}) -> v1 < v2 end)
    r2 = r |> Enum.map(fn({k, v}) -> km = line_split(k)
                      %{msgid: km, references: v}
                  end)
    :dets.close(dets)
    r3 = Enum.map(r2, fn(e) ->
                     %{msgid: e[:msgid],
                       references: Enum.map(e[:references], 
                                            fn(x) ->
                                                %{file: x[:file], 
                                                  line: x[:line]}
                                            end)
                      } end)
    {:ok, fh} = File.open(pot, [:write])
    output(fh, r3)
    s = doc()
    output(fh, s)
    File.close(fh)
    :ok
  end

end
