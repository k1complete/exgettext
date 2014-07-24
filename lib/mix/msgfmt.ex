defmodule Mix.Tasks.L10n.Msgfmt do
  use Mix.Task
  @shortdoc "run msgfmt"
  @moduledoc """
  create elixir message object for current project.

  ## Synopsis

  ```
      mix l10n.msgfmt
  ```

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## Files

  ### Input

    * priv/po/`LANG`.po -- portable object for translation working.
 
  ### Output

    * priv/lang/`LANG`/`app`.exmo -- message object dets.

  """
  def run(_opt) do
    app = Mix.Project.config[:app]
    lang = Exgettext.Runtime.getlang()
    Mix.shell.info("msgfmt for #{app}")
    pofile = Exgettext.Util.pofile(app, lang)
    mofile = Exgettext.Runtime.mofile(app, lang)
    dir = Path.dirname(mofile)
    Mix.shell.info("#{pofile} #{mofile}")
    :ok = File.mkdir_p(dir)
    :ok = Exgettext.Tool.msgfmt(pofile, mofile)
  end
end
