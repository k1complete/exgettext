defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  @shortdoc "run msgmerge"
  def run(_opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    lang = Exgettext.Runtime.getlang()
    pofile = Exgettext.pofile(app, lang)
    potfile = Exgettext.pot_file(app)
    poxfile = Exgettext.poxfile(app,lang)
    cmd = "msgmerge -o #{poxfile} #{pofile} #{potfile}"
    Mix.Shell.IO.info(cmd)
    case Mix.Shell.IO.cmd(cmd) do
      0 -> 0
      r -> Mix.Shell.IO.error("failed #{r}")
    end
  end
end
