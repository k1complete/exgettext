Mix.start()
Mix.shell(Mix.Shell.Process)
ExUnit.start [trace: "--trace" in System.argv]
#ExUnit.start()

defmodule MixTest.Case do
  use ExUnit.CaseTemplate

  defmodule Sample do
    def project do
      [ app: :sample,
        version: "0.1.0" ]
    end
  end

  using do
    quote do
      import MixTest.Case
    end
  end

  setup do
    on_exit fn ->
      Mix.env(:dev)
      Mix.Task.clear
      Mix.Shell.Process.flush
      Mix.ProjectStack.clear_cache
      Mix.ProjectStack.clear_stack
      System.put_env("MIX_HOME", tmp_path(".mix"))
      delete_tmp_paths
    end

    :ok
  end

  def elixir_root do
    Path.expand("../../..", __DIR__)
  end

  def fixture_path do
    Path.expand("fixtures", __DIR__)
  end

  def fixture_path(extension) do
    Path.join fixture_path, extension
  end

  def tmp_path do
    Path.expand("../tmp", __DIR__)
  end

  def tmp_path(extension) do
    Path.join tmp_path, extension
  end

  def purge(modules) do
    Enum.each modules, fn(m) ->
      :code.delete(m)
      :code.purge(m)
    end
  end

  def in_tmp(which, function) do
    path = tmp_path(which)
    File.rm_rf! path
    File.mkdir_p! path
    File.cd! path, function
  end

  defmacro in_fixture(which, block) do
    module   = inspect __CALLER__.module
    function = Atom.to_string elem(__CALLER__.function, 0)
    tmp      = Path.join(module, function)

    quote do
      unquote(__MODULE__).in_fixture(unquote(which), unquote(tmp), unquote(block))
    end
  end

  def in_fixture(which, tmp, function) do
    src  = fixture_path(which)
    dest = tmp_path(tmp)
    flag = tmp_path |> String.to_char_list

    File.rm_rf!(dest)
    File.mkdir_p!(dest)
    File.cp_r!(src, dest)

    get_path = :code.get_path
    previous = :code.all_loaded

    try do
      File.cd! dest, function
    after
      :code.set_path(get_path)
      Enum.each (:code.all_loaded -- previous), fn {mod, file} ->
        if is_list(file) and :lists.prefix(flag, file) do
          purge [mod]
        end
      end
    end
  end

  def ensure_touched(file) do
    ensure_touched(file, File.stat!(file).mtime)
  end

  def ensure_touched(file, current) do
    File.touch!(file)
    unless File.stat!(file).mtime > current do
      ensure_touched(file, current)
    end
  end

  def os_newline do
    case :os.type do
      {:win32, _} -> "\r\n"
      _ -> "\n"
    end
  end

  defp delete_tmp_paths do
    tmp = tmp_path |> String.to_char_list
    to_remove = Enum.filter :code.get_path, fn(path) -> :string.str(path, tmp) != 0 end
    Enum.map to_remove, &(:code.del_path(&1))
  end
end

## Copy fixtures to tmp

#source = MixTest.Case.fixture_path("rebar_dep")
#dest = MixTest.Case.tmp_path("rebar_dep")
#File.mkdir_p!(dest)
#File.cp_r!(source, dest)

## Generate git repo fixtures

# Git repo
#target = Path.expand("fixtures/git_repo", __DIR__)


## Generate helper modules

path = MixTest.Case.tmp_path("beams")
File.rm_rf!(path)
File.mkdir_p!(path)
Code.prepend_path(path)

write_beam = fn {:module, name, bin, _} ->
  path
  |> Path.join(Atom.to_string(name) <> ".beam")
  |> File.write!(bin)
end

defmodule Mix.Tasks.Hello do
  use Mix.Task
  @shortdoc "This is short documentation, see"

  @moduledoc """
  A test task.
  """

  def run([]) do
    "Hello, World!"
  end

  def run(args) do
    "Hello, #{Enum.join(args, " ")}!"
  end
end |> write_beam.()

defmodule Mix.Tasks.Invalid do
end |> write_beam.()
