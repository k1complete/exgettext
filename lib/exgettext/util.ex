defmodule Exgettext.Util do
  def popath(suffix \\ "") do
    Path.join(["priv", "po", suffix])
  end
  def poxfile(_app, lang) do
    popath("#{lang}.pox")
  end
  def pofile(_app, lang) do
    popath("#{lang}.po")
  end
  def pot_file(app) do
    popath("#{app}.pot")
  end
  def relative(file, path) do
    Path.relative_to(file, path)
  end
  def get_app(mod) do
    r = :application.get_application(mod) 
#    raise(ArgumentError, message: "bad mod #{mod}, cannot load app")
    :error_logger.info_report [mod: mod, app: r]
    case r do
      {:ok, app} -> app
      :undefined -> :iex
    end
  end

  def defdelegate_filter(src, target, func) do
    target.module_info(:exports) |> 
      Stream.filter(fn({ff, a}) ->
                      func.({ff, a}) && (not ff in [:__info__, :module_info])
                    end) |>
      Stream.map(fn({ff, a}) ->
                   args1 = :lists.seq(1,a)
                   {ff, Enum.map(args1, fn(x) -> {:"a#{x}", [], nil} end)}
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
