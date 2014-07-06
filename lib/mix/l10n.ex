defmodule Mix.Tasks.L10n.Msginit do
  use Mix.Task
  def run(_opt) do
    podir = Exgettext.popath()
    Mix.Shell.Process.cmd("cd #{podir}; msginit")
  end
end
defmodule Mix.Tasks.L10n.Msgfmt do
  use Mix.Task
  def run(_opt) do
    app = Mix.Project.config[:app]
    lang = Exgettext.Runtime.getlang()
    Mix.Shell.IO.info("msgfmt for #{app}")
    pofile = Exgettext.pofile(app, lang)
    mofile = Exgettext.Runtime.mofile(app, lang)
    dir = Path.dirname(mofile)
    Mix.Shell.IO.info("#{pofile} #{mofile}")
    :ok = File.mkdir_p(dir)
    :ok = Exgettext.Tool.msgfmt(pofile, mofile)
  end
end
defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
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
defmodule Mix.Tasks.L10n.Xgettext do
  use Mix.Task
  def run(_opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    Mix.Shell.IO.info("xgettext for #{app}")
    :ok = Exgettext.Tool.clean(app)
    :ok = Mix.Tasks.Compile.run(["--force"])
    :ok = Exgettext.Tool.xgettext(app)
  end
end
