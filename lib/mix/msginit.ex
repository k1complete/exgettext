defmodule Mix.Tasks.L10n.Msginit do
  use Mix.Task
  @shortdoc "run msginit"
  @moduledoc """
  run msginit in GNU gettext utility for current project.

  ## Synopsis

  ```
      mix l10n.msginit [--locale LL_CC.charset]
  ```

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## Files

  ### Input

    * priv/po/`app`.pot -- portable object template generated by
                           l10n.xgettext task.
 
  ### Output

    * priv/po/`LANG`.po -- portable object for translation working.

  """
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    lang = Keyword.get(opt, :locale, System.get_env("LANG"))
    potdir = Exgettext.Util.popath()
    Enum.map(Path.wildcard(Path.join([potdir, "**", "*.pot"])),
             fn(x) ->
               dir = Path.dirname(x)
               dir2 = Exgettext.Util.pathescape(dir)
               cmd = "cd #{dir2}; msginit --locale #{lang}"
#               IO.inspect [msgint: cmd]
               Mix.shell.info(cmd)
               Mix.Shell.Process.cmd(cmd)
             end)
  end
end
