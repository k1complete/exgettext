defmodule Mix.Tasks.L10n.Xgettext do
  use Mix.Task
  @shortdoc "run xgettext"
  @moduledoc """
  create portable object template for current project.

  ## Synopsis

  ```
      mix l10n.xgettext [--app src_root]...
  ```

  ## Arguments
 
    * --app srcroot  -- addional `app` and src_root
                        for correcting @moduledoc, @doc

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## Files

  ### Input

    * `app`.pot_db -- message database generated by gettext macro.
 
  ### Output

    * priv/po/`app`.pot -- portable object template generated by
                           l10n.xgettext task.

  """
  def run(opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    Mix.shell.info("xgettext for #{app}")
    :ok = Exgettext.Tool.clean(app)
#    m = Path.join([Mix.Project.compile_path(config),"**/#{app}/ebin/*"]) |>
#      Path.wildcard 
#    IO.puts "stat #{m}"
    Mix.Task.run("clean", [])
    case Mix.Tasks.Compile.Elixir.run(["--force --docs"]) do
      :noop -> 
        Mix.shell.info("noop")
        :ok
      {:ok, _} -> :ok
    end
    case Mix.Tasks.Compile.App.run(["--force --docs"]) do
      :noop -> 
        Mix.shell.info("noop")
        :ok
      :ok -> :ok
    end
    :ok = Exgettext.Tool.xgettext(app, opt)
    m = config[:exgettext][:extra]
    case Code.ensure_loaded(m) do
      {:module, ^m} ->
        apply(m, :xgettext, [config, app, opt])
      _ ->
        :ok      
    end
  end
end
