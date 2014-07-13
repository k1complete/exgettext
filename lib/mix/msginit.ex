defmodule Mix.Tasks.L10n.Msginit do
  use Mix.Task
  def run(_opt) do
    podir = Exgettext.popath()
    Mix.Shell.IO.info(podir)
    cmd = "cd #{podir}; msginit"
    Mix.Shell.IO.info(cmd)
    Mix.Shell.Process.cmd(cmd)
  end
end
