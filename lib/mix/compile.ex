defmodule Mix.Tasks.Compile.Po do
  use Mix.Task
  @moduledoc """
  po compile
  """
  #@manifest ".compile.po"
  def run(args) do
    Mix.Task.run("l10n.msgfmt", args)
  end
#  def maifests, do: [manifest]
#  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)
end
