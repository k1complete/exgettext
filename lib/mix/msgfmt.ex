defmodule Mix.Tasks.L10n.Msgfmt do
  use Mix.Task
  @shortdoc "run msgfmt"
  @moduledoc """
  create elixir machine object for current project.

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

    * priv/lang/`LANG`/`app`.exmo -- machine object dets.

  """
  def run(opt) do
    use Exgettext
    {opt, _args, _rest} = OptionParser.parse(opt)
    env  = Keyword.get(opt, :locale, System.get_env("LANG"))
    lang = Exgettext.Runtime.getlang(env)
    app = Mix.Project.config[:app]
    Mix.shell.info("msgfmt for #{app}")
    pofile = Exgettext.Util.pofile(app, lang)
    mofile = Exgettext.Runtime.mofile(app, lang)
    dir = Path.dirname(mofile)
    Mix.shell.info("#{pofile} #{mofile}")
#    Mix.Shell.IO.info("#{pofile} #{mofile}")
    :ok = File.mkdir_p(dir)
    :ok = Exgettext.Tool.msgfmt(pofile, mofile)
  end
end
