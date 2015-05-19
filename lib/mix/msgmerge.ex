defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  @shortdoc "run msgmerge: options: --update for update"
  @moduledoc """
  run msgmerge in GNU gettext utility for current project.

  ## Synopsis

  ```
      mix l10n.msgmerge [--update=(false|true)] [--locale LL_CC.charset]

  ```

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## Files

  ### Input

    * priv/po/**/`app`.pot -- portable object template generated by
                              l10n.xgettext task.

    * priv/po/**/`LANG`.po -- portable object for translation working.
 
  ### Output

    * priv/po/`LANG`.pox --  merge result.

    * priv/po/`LANG`.po --  merge result(if --update=true ).

  ## Note

    if new modules(new srcs) exisit, run msginit first.

    msgmerge do only merge.

  """
  def run(opt) do
    {opt, _args, _rest} = OptionParser.parse(opt)
    lang = Exgettext.Runtime.getlang(Keyword.get(opt, :locale, System.get_env("LANG")))
    outfile = case (Keyword.get(opt, :update, false)) do
                true ->
                  Exgettext.Util.pofile_base(lang)
                false ->
                  Exgettext.Util.poxfile_base(lang)
              end
    config = Mix.Project.config()
    app = to_string(config[:app])
    pofiles = Path.wildcard(Path.join([Exgettext.Util.popath(), 
                                        "**", "*.pot"]))
    Enum.map(pofiles, 
             fn(x) ->
               dir = Path.dirname(x)
               basename = Path.basename(x, ".pot")
               poxfile = Path.join([dir, outfile])
               pofile = Path.join([dir, Exgettext.Util.pofile_base(lang)])
               poxfile = Exgettext.Util.pathescape(poxfile)
               pofile = Exgettext.Util.pathescape(pofile)
               x = Exgettext.Util.pathescape(x)
               cmd = "msgmerge -o #{poxfile} #{pofile} #{x}"
#               IO.inspect [merge: cmd]
               Mix.shell.info(cmd)
               case Mix.shell.cmd(cmd) do
                 0 -> 0
                 r -> Mix.shell.error("failed #{r}")
                      r
               end
             end)
  end
end
