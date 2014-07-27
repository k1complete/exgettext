defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  @shortdoc "run msgmerge"
  def run(_opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    lang = Exgettext.Runtime.getlang()
    pofile = Exgettext.Util.pofile(app, lang)
    potfile = Exgettext.Util.pot_file(app)
    poxfile = Exgettext.Util.poxfile(app,lang)
    cmd = "msgmerge -o #{poxfile} #{pofile} #{potfile}"
    Mix.shell.info(cmd)
    case Mix.shell.cmd(cmd) do
      0 -> 0
      r -> Mix.shell.error("failed #{r}")
           r
    end
  end
end
