defmodule Mix.Tasks.L10n.Msginit do
  use Mix.Task
  def run(_opt) do
    Mix.Shell.Process.cmd("msginit")
  end
end
defmodule Mix.Tasks.L10n.Msgfmt do
  use Mix.Task
  def run(_opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    lang = Exgettext.getlang()
    Mix.Shell.IO.info("msgfmt for #{app}")
    pofile = Exgettext.pofile(app, lang)
    mofile = Exgettext.mofile(app, lang)
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
    lang = Exgettext.getlang()
    pofile = Exgettext.pofile(app, lang)
    cmd = "msgmerge -o #{lang}.pox #{pofile} #{app}.pot"
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
