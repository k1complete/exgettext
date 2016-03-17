defmodule Mix.Tasks.L10n.Check do
  use Mix.Task
  @shortdoc "run msgfmt -v --statistics -c for checking po-files"
  @moduledoc """
  check portable object files for current project.

  ## Synopsis

  ```
      mix l10n.check [--list]
  ```

  ## Arguments
 
    * --listt  -- add fuzzy, and untransated file list

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## Files

    * priv/po/**/*.po -- target po-files

  ### Input


  ### Output


  """
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    env  = Keyword.get(opt, :locale, System.get_env("LANG"))
    lang = Exgettext.Runtime.getlang(env)
#    app = Mix.Project.config[:app]
    pofiles = Exgettext.Util.pofiles(lang)
#    Mix.shell.info("check #{pofiles}")
#    IO.inspect [pofiles: pofiles]
    Enum.reduce(pofiles, 0,
                fn(x, a) ->
                  x = Regex.replace(~r/ /, x, "\\ ")
                  cmd = "msgfmt -c -v --statistics -o /dev/null #{opt} #{x}"
#                  Mix.shell.info(cmd)
                  a+Mix.shell.cmd(cmd)
                end)
  end
end
