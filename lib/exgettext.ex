defmodule Exgettext do
  @moduledoc """
  ** Localization package for Elixir
  
  *** target
  
  1. ~T sigil quoted string literal
  2. @moduledoc
  3. @doc
  
  *** example
    example for the :app application:

    ```
    use Exgettext
    def hello do
      ~T "Hello, World."
    end
    ```

    ~T macro expanded to

    ```
    def hello do
      Exgettext.Runtime.gettext(:app, "Hello, World.")
    end
    ```
  """
  defmacro __using__(_opt \\ :dummy ) do
    module = __CALLER__.module
    put_dets(:module, module)
    :ok
    quote do: import Exgettext
  end

  @doc nil
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
    binary = Macro.unescape_string(string)
    quote do: txt(unquote(binary))
  end
  @doc """
  translate target string by LANG environment.
  """
  defmacro txt(s) do
    r = __CALLER__
    path = System.get_env("PWD")
    app = get_app()
    put_dets(s, %{line: r.line, file: Exgettext.Util.relative(r.file, path), function: r.function })
    quote do: Exgettext.Runtime.gettext(unquote(app), unquote(s))
  end
  @doc """
  translate target string by lang.
  """
  defmacro txt(s, lang) do
    r = __CALLER__
    path = System.get_env("PWD")
    app = get_app()
    put_dets(s, %{line: r.line, file: Exgettext.Util.relative(r.file, path), function: r.function })
    quote do
      Exgettext.Runtime.gettext(unquote(app), unquote(s), unquote(lang))
    end
  end
end

