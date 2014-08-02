defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  @shortdoc "run msgmerge"
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    lang = Exgettext.Runtime.getlang(Keyword.get(opt, :locale, System.get_env("LANG")))
    config = Mix.Project.config()
    app = to_string(config[:app])
    pofile = Exgettext.Util.pofile(app, lang)
    potfile = Exgettext.Util.pot_file(app)
    poxfile = Exgettext.Util.poxfile(app,lang)
#    cmd = "pwd"
#    Mix.Shell.IO.cmd(cmd)
    cmd = "msgmerge -o #{poxfile} #{pofile} #{potfile}"
#    Mix.Shell.IO.info(cmd<> "--running--")
    Mix.shell.info(cmd)
    case Mix.shell.cmd(cmd) do
#    case Mix.Shell.IO.cmd(cmd) do
      0 -> 0
      r -> Mix.shell.error("failed #{r}")
           r
    end
  end
end
