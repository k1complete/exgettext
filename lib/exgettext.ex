defmodule Exgettext do
  @moduledoc """
  ## Localization package for Elixir
  
  ### target
  0. setlocale() 
  1. ~L sigil quoted string literal
  2. @moduledoc
  3. @doc
  
  ### example
    example for the :app application:

    ```
    use Exgettext
    def hello do
      setlocale()  
      ~L "Hello, World."
    end
    ```

    ~L macro expanded to

    ```
    def hello do
      Exgettext.setlocale()
      Exgettext.Runtime.gettext(:app, "Hello, World.")
    end
    ```
  """
  defmacro __using__(_opt \\ :dummy ) do
    module = __CALLER__.module
    put_dets(:module, module)
    quote do
      alias Exgettext.Typespec, as: Typespec
      alias Exgettext.Code, as: Code
      import Exgettext
    end
  end
  @lang :"Exgettext.Lang"

  @doc """
  get current 2byte language code from LANG environment variable format.
  """
  def lang(<<a,b>> <> _ = _lang) do
    <<a,b>>
  end
  def lang(lang) do
    lang
  end
  @doc """
  set locale to Process dictionary :'Exgettext.Lang' 
  from lang or LANG environment.
  """
  def setlocale(lang) when is_binary(lang) do
    Process.put(@lang, lang(lang))
  end
  def setlocale() do
    setlocale(System.get_env("LANG"))
  end
  @doc """
  get locale from Process dictionary :'Exgettext.Lang'
  """
  def getlocale() do
    Process.get(@lang)
  end
  @doc nil
  defp get_app() do
    Mix.Project.config[:app]
  end
  defp put_dets(s, reference) do
    app_pot_db = '#{get_app()}.pot_db'
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
  ~L is detect to translate target string.
  """
  defmacro sigil_L({:<<>>, _line, [string]}, options) when is_binary(string) do
    binary = Macro.unescape_string(string)
    case  options do
      [] -> 
        quote do: txt(unquote(binary))
      options ->
        options = List.to_atom(options)
        v = {:var!, [], [{options, [], nil}]}
        quote do
          txt(unquote(binary), unquote(v))
        end
    end
  end
  @doc """
  translate target string by LANG environment.
  """
  defmacro txt(s) do
    r = __CALLER__
    path = System.get_env("PWD")
    app = get_app()
    put_dets(s, %{line: r.line, file: Exgettext.Util.relative(r.file, path), function: r.function })
    quote bind_quoted: [app: app, s: s] do
      Exgettext.Runtime.gettext(app, s, getlocale())
    end
  end
  @doc """
  translate target string by lang.
  """
  defmacro txt(s, lang) do
    r = __CALLER__
    path = System.get_env("PWD")
    app = get_app()
    put_dets(s, %{line: r.line, file: Exgettext.Util.relative(r.file, path), function: r.function })
    quote bind_quoted: [app: app, s: s, lang: lang] do
      Exgettext.Runtime.gettext(app, s, lang)
    end
  end
end

