defmodule Mix.Tasks.L10n.Msginit do
  use Mix.Task
  def run(_opt) do
    Mix.Shell.Process.cmd("msginit")
  end
end
defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  def locale_to_lang("C") do
    "en"
  end
  def locale_to_lang(nil) do
    "en"
  end
  def locale_to_lang(locale) do
    case Regex.run(~r/([^._]+)_([^._]+)\.([^.])+/, locale) do
      nil -> locale
      [^locale, lang, _country, _encoding] -> 
        lang
    end
  end
  def run(_opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    lang = locale_to_lang(System.get_env("LANG"))
    cmd = "msgmerge -o #{lang}.pox #{lang}.po #{app}.pot "
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
    :ok = Mix.Tasks.Compile.run(["--force"])
  end
end
