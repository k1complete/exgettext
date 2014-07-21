# ?\x0ab
# ?\08
# ?\n
# ?a
defmodule Exgettext.Tool do
  def escape(s) do
    s3 = for <<c <- s>>, into: "" do
      case c do
        ?\\ ->
          "\\\\"
        ?\t -> 
          "\\t"
        ?\n -> 
          "\\n"
        ?\" ->
          "\\\""
        _ -> <<c>>
      end
    end
    s3
  end
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
  def modules(app) when is_binary(app) do
    pot_db = potdb(app)
    {:ok, dets} = :dets.open_file(pot_db, [])
    r =  case :dets.lookup(dets, :module) do
           [{:module, r}] -> r
           _other -> []
         end
    :io.format("modules ~p", [r])
    r
  end
  def modules_app(app) when is_binary(app) do
    app = String.to_atom(app)
    :application.load(app)
    case :application.get_key(app, :modules) do
      {:ok, mods} -> mods
      r -> 
        :error_logger.error_report([{:get_key, [app, :module]}, 
                                    {:result, r}])
        []
    end
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
  def doc(c) do
    mod = modules_app(c)
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
  def potdb(app) do
    "#{app}.pot_db"
  end
  def clean(app) do
    pot_db = potdb(app)
    IO.puts "clean #{pot_db}\n"
    case :dets.open_file(pot_db, []) do
      {:ok, dets} -> 
        :dets.delete_all_objects(dets)
        :dets.close(dets)
      err -> 
        IO.puts "clean #{err}\n"
        :ok
    end
  end

  def xgettext(app, opt \\ []) do
    apps = [app | Enum.map(opt, &(&1))]
    pot_db = potdb(app)
    pot = Exgettext.pot_file(app)
    IO.puts "xgettext #{pot_db} --output=#{pot}\n"
    :ok = File.mkdir_p(Exgettext.popath())
    {:ok, dets} = :dets.open_file(pot_db, [])
    r = :dets.foldl(fn({k, v}, acc) when not(is_atom(k)) -> 
                        [{k, v}|acc] 
                      ({_k,_v}, acc) -> 
                        acc
                    end, [], dets) |>
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
    Enum.map(apps,
             fn(x) ->
               :io.format("doc ~p~n", [x])
               s = doc(x)
               output(fh, s)
             end)
    File.close(fh)
    :ok
  end

end
