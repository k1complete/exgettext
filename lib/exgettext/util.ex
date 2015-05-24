defmodule Exgettext.Util do
  def pot_path(app, file) do
    Path.join(["priv", "po", app, file, Path.basename(file) <> ".pot"])
  end
  def popath(suffix \\ "") do
    Path.join(["priv", "po", suffix])
  end
  def poxfile_base(lang) do
    "#{lang}.pox"
  end
  def poxfile(_app, lang) do
    popath("#{lang}.pox")
  end
  def pofile_base(lang) do
    "#{lang}.po"
  end
  def pofile(_app, lang) do
    popath("#{lang}.po")
  end
  def pofiles(lang) do
    Path.wildcard(Path.join([popath("**"), pofile_base(lang)]))
  end
  def pot_file(app) do
    popath("#{app}.pot")
  end
  def relative(file, path) do
    Path.relative_to(file, path)
  end
  def pathescape(path) do
    Regex.replace(~r/ /, path, "\\\\ ", [:global])
  end
  def get_app(mod) do
    r = :application.get_application(mod)
#    raise(ArgumentError, message: "bad mod #{mod}, cannot load app")
#    :error_logger.info_report [mod: mod, app: r]
    case r do
      {:ok, app} -> app
      :undefined -> 
        Code.ensure_loaded(mod)
        case :code.is_loaded(mod) do
          false -> :iex
          {_, path} -> 
            app = Path.dirname(path) |>
              Path.join("*.app") |>
              Path.wildcard |>
              Path.basename(".app") |>
              String.to_atom
            :application.load(app)
            app
        end
    end
  end

  def defdelegate_filter(src, target, func) do
    target.module_info(:exports) |> 
      Stream.filter(fn({ff, a}) ->
                      func.({ff, a}) && 
                        (not ff in [:__info__, :module_info])
                    end) |>
      Stream.map(fn({ff, a}) ->
                   args1 = :lists.seq(1,a)
                   {ff, Enum.map(args1, 
                                 fn(x) -> 
                                   {:"a#{x}", [], nil} 
                                 end)}
                 end) |>
      Enum.map(fn({ff, a}) ->
                 # IO.inspect ff
                 r = {{:., [], [Kernel, :defdelegate]}, [],
                      [{ff, [], a}, [{:to, target}]]}
                 # IO.puts Macro.to_string(r)
                 Module.eval_quoted(src,r)
               end)
  end
end
