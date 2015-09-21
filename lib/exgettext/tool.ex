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

  def convert_po(pfile, acc \\ %{}) do
    {:ok, fh} = File.open(pfile)
    r = IO.binread(fh, :line)
    r = parse(fh, r, acc)
    File.close(fh)
    r
  end
  def msgfmt(pfiles, outfile) do
    r = Enum.reduce(pfiles, 
                    %{}, 
                    fn(x, acc) ->
                      convert_po(x, acc)
                    end)
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
#    :io.format("modules ~p", [r])
    r
  end
  def modules_app(app) when is_atom(app) do
    :application.load(app)
    case :application.get_key(app, :modules) do
      {:ok, mods} -> Enum.filter(mods, fn(x) ->
                                         Regex.match?(~r/^Elixir\./, 
                                                      Atom.to_string(x))
                                 end)
      r -> 
        :error_logger.error_report([{:get_key, [app, :module]}, 
                                    {:result, r}])
        []
    end
  end
  def module_to_file(module, src_root) do
    module.__info__(:compile)[:source]
    file = module.__info__(:compile)[:source]
    m = Exgettext.Util.relative(file, src_root)
#    IO.inspect [file: file, src_root: src_root, relative: m]
    m
  end
  def moduledoc(modules, src_root) do
    result = modules |> 
      Enum.map fn(x) ->
                 case Code.get_docs(x, :moduledoc) do
                   nil -> nil
                   {l, d} ->
                     ref = %{file: module_to_file(x, src_root),
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
  def funcdoc(modules, src_root) do
    r = modules |>
      List.foldr [], 
    fn(m, a) ->
      d = Code.get_docs(m, :docs)
      file = module_to_file(m, src_root)
      case d do
        nil -> a
        d -> 
          a ++ Enum.map d, 
          fn(x) -> 
            {{name, _arity}, 
             line, type, arg, doc} = x
            ref = %{file: file, line: line}
            com = Macro.to_string({{:".", 
                                    [], 
                                    [m, name]}, 
                                   [], arg},
                                  fn(_ast, s) ->
                                    Regex.replace(~R/\n/, s, ";", [:g])
                                  end)
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
  def typedoc(modules, src_root) do
    r = List.foldr(modules, [],
                   fn(m, a) ->
                     d = Code.get_docs(m, :type_docs)
                     file = module_to_file(m, src_root)
                     case d do
                       nil -> a
                       d -> a ++ Enum.map d, 
                            fn(x) ->
                              {{ty, _ar}, line, type, doc} = x
                              ref = %{file: file, line: line}
                              %{module: m, 
                                name: ty, 
                                msgid: doc,
                                references: [ref],
                                comment: "@#{type} #{ty}"}
                            end
                     end
                   end)
    Enum.filter(r, fn(x) -> is_map(x) and is_binary(x.msgid) end) |>
      Enum.sort &(&1 < &2)
  end
  def callbackdoc(modules, src_root) do
    r = List.foldr(modules, [],
                   fn(m, a) ->
                     d = Code.get_docs(m, :callback_docs)
                     file = module_to_file(m, src_root)
                     case d do
                       nil -> a
                       d -> a ++ Enum.map d, 
                            fn(x) ->
                              {{ty, ar}, line, :callback, doc} = x
                              ref = %{file: file, line: line}
                              %{module: m, 
                                name: ty, 
                                msgid: doc,
                                references: [ref],
                                comment: "@callback #{ty}/#{ar}"}
                            end
                     end
                   end)
    Enum.filter(r, fn(x) -> is_map(x) and is_binary(x.msgid) end) |>
      Enum.sort &(&1 < &2)
  end
  def redup(m) do
    r = List.foldl(m, %{}, fn(x, a) -> 
                         k = x[:msgid]
                         Dict.put(a, k, x)
               end)
    Enum.map(r, fn({_k,v}) -> v end)
  end
  def ensure_load(root, app) do
    case Path.wildcard(Path.join(root, "ebin")) do
      [] ->
        case Path.wildcard(Path.join(root, "_build/**/#{app}/ebin")) do
          [] ->
            root
           x -> hd(x)
        end
      x ->
        hd(x)
    end
  end
  def doc(app, opts) do
    src_root = Path.expand(Keyword.get(opts, app, System.get_env("PWD")))
    ebin = ensure_load(src_root, app)
    Code.prepend_path(ebin)
    mod = modules_app(app)

    m = moduledoc(mod, src_root)
    f = funcdoc(mod, src_root)
    t = typedoc(mod, src_root)
    c = callbackdoc(mod, src_root)
    o = redup(f ++ m ++ t ++ c)
    o = o |> Enum.sort &( &1.module < &2.module && &1.name < &2.name )
    Enum.map o, fn(x) -> %{x | msgid: line_split(x.msgid) } end
  end
  defp output_msg(fh, r) do
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
  defp output_doc(r, fdict, app) do
    Enum.map(r, 
             fn(e) -> 
               [mh|_mt] = e[:references]
               basename = mh[:file]
               pofile = Exgettext.Util.pot_path(app, basename)
#               IO.inspect [pofile: pofile]
               if (:ets.insert_new(fdict, {pofile, basename})) do
                 :ok = File.mkdir_p(Path.dirname(pofile))
                 {:ok, fh} = File.open(pofile, [:write])
               else
                 {:ok, fh} = File.open(pofile, [:write, :append])
               end
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
               File.close(fh)
             end)
  end
  def potdb(app) do
    "#{app}.pot_db"
  end
  def clean(app) do
    pot_db = potdb(app)
    Mix.shell.info "clean #{pot_db}\n"
    case :dets.open_file(pot_db, []) do
      {:ok, dets} -> 
        :dets.delete_all_objects(dets)
        :dets.close(dets)
      err -> 
        Mix.shell.info "clean #{err}\n"
        :ok
    end
  end

  def xgettext(app, opt) do
    {opt, _args, _rest} = if ([] == opt)  do
                            {[], [], []}
                          else
                            OptionParser.parse(opt)
                          end
    apps = [String.to_atom(app) | Keyword.keys(opt)]
    pot_db = potdb(app)
    pot = Exgettext.Util.pot_file(app)
    Mix.shell.info "xgettext #{pot_db} --output=#{pot}"
    dir = Exgettext.Util.popath()
    Mix.shell.info "path #{dir}"
    :ok = File.mkdir_p(dir)
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
    files = :ets.new(:symtable, [])
    output_msg(fh, r3)
    File.close(fh)
    Enum.map(apps,
             fn(x) ->
               Mix.shell.info("collecting document for #{x}")
               s = doc(x, opt)
               output_doc(s, files, Atom.to_string(x))
             end)
    :ets.delete(files)
    :ok
  end

end
