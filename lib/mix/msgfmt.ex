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

    * priv/po/**/`LANG`.po -- portable object for translation working.
 
  ### Output

    * priv/lang/`LANG`/`app`.exmo -- machine object dets.

  """
  @spec run(String.t) :: :ok | :noop 
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    env  = Keyword.get(opt, :locale, System.get_env("LANG"))
    lang = Exgettext.Runtime.getlang(env)
    app = Mix.Project.config[:app]
    pofiles = Exgettext.Util.pofiles(lang)
    mofile = Exgettext.Runtime.mofile(app, lang)
    if opt[:force] || Mix.Utils.stale?(pofiles, [mofile]) do
      Mix.shell.info("msgfmt for #{app}")
      dir = Path.dirname(mofile)
      pofile = Enum.join(pofiles, " ")
      # Mix.shell.info("#{pofile} #{mofile}")
      :ok = File.mkdir_p(dir)
      :ok = Exgettext.Tool.msgfmt(pofiles, mofile)
    else
      :noop
    end
  end
end
