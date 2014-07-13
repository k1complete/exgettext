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
