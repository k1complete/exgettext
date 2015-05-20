defmodule Mix.Tasks.L10n.Msgfmt do
  use Exgettext
  use Mix.Task
  @shortdoc "run msgfmt"
  @moduledoc """
  create elixir machine object for current project.

  ## Synopsis

  ```
      mix l10n.msgfmt [--force]
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
  @spec run(String.t) :: :ok | :noop 
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    env  = Keyword.get(opt, :locale, System.get_env("LANG"))
    lang = Exgettext.Runtime.getlang(env)
    app = Mix.Project.config[:app]
    pofile = Exgettext.Util.pofiles(lang)
    mofile = Exgettext.Runtime.mofile(app, lang)
    if opt[:force] || Mix.Utils.stale?(pofile, [mofile]) do
      Mix.shell.info("msgfmt for #{app}")
      dir = Path.dirname(mofile)
      Mix.shell.info("#{pofile} #{mofile}")
      #    Mix.Shell.IO.info("#{pofile} #{mofile}")
      :ok = File.mkdir_p(dir)
      :ok = Exgettext.Tool.msgfmt(pofile, mofile)
    else
      :noop
    end
  end
end
