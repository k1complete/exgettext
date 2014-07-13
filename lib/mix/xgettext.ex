defmodule Mix.Tasks.L10n.Xgettext do
  use Mix.Task
  def run(opt) do
    config = Mix.Project.config()
    app = to_string(config[:app])
    Mix.Shell.IO.info("xgettext for #{app}")
    :ok = Exgettext.Tool.clean(app)
    :ok = Mix.Tasks.Compile.run(["--force"])
    :ok = Exgettext.Tool.xgettext(app, opt)
  end
end
