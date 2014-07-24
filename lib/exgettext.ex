defmodule Exgettext do
  defmacro __using__(_opt \\ :dummy ) do
    module = __CALLER__.module
    put_dets(:module, module)
    :ok
  end

  defp get_app() do
    Mix.Project.config[:app]
  end
  defp put_dets(s, reference) do
    app_pot_db = "#{get_app()}.pot_db"
    {:ok, dets} = :dets.open_file(app_pot_db, [])
    k = s
    case :dets.lookup(dets, k) do
      [] -> :dets.insert(dets, {k, [reference]})
      [{^k, v}] ->
        :dets.insert(dets, {k, [reference | v]})
    end
    :dets.close(dets)
  end
  @doc """
  ~T is detect to translate target string.
  """
  defmacro sigil_T({:<<>>, _line, [string]}, []) when is_binary(string) do
#  def sigil_T(string, []) when is_binary(string) do
    binary = Macro.unescape_string(string)
    quote do: txt(unquote(binary))
  end
  defmacro txt(s) do
    r = __CALLER__
    path = System.get_env("PWD")
    app = get_app()
    put_dets(s, %{line: r.line, file: Exgettext.Util.relative(r.file, path), function: r.function })
    quote do: Exgettext.Runtime.gettext(unquote(app), unquote(s))
  end

  defmacro txt2(s, lang) do
    app = get_app()
    quote do
      Exgettext.Runtime.gettext(unquote(app), unquote(s), unquote(lang))
    end
  end
end

