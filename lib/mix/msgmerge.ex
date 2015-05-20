defmodule Mix.Tasks.L10n.Msgmerge do
  use Mix.Task
  @shortdoc "run msgmerge: options: --update for update"
  @moduledoc """
  run msgmerge in GNU gettext utility for current project.

  ## Synopsis

  ```
      mix l10n.msgmerge [--locale LL_CC.charset] [--update=true] [msgmerge-options]

  ```

  ## Environment
  
    * LANG -- localize target language for `Language`

  ## Mix Environment

    * project[:app] -- basename for portable object file.

  ## msgmerge options
    `-D` 
      search directory.
    `-C`
      compendium file.

  ## Files

  ### Input

    * guess-po-file -- the hint po-file.

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
    {opt, _args, rest} = OptionParser.parse(opt)
    lang = Exgettext.Runtime.getlang(Keyword.get(opt, :locale, System.get_env("LANG")))
    update = Keyword.get(opt, :update, false)

    outfile = Exgettext.Util.poxfile_base(lang)

#    config = Mix.Project.config()
#    app = to_string(config[:app])
    pofiles = Path.wildcard(Path.join([Exgettext.Util.popath(), 
                                        "**", "*.pot"]))
    opt = Keyword.drop(opt, [:update, :locale]) 
    opt = Enum.reduce(opt, rest, fn({k,v}, a) -> [{"--#{k}", "#{v}"} | a] end)
    opts = Enum.reduce(opt, "", fn({k,nil}, a) -> 
                                  "#{k} " <> a
                                  ({k, v}, a) ->
                                  "#{k} #{v} " <> a
                       end)
    Enum.map(pofiles, 
             fn(x) ->
               dir = Path.dirname(x)
               pofile = Path.join(dir, Exgettext.Util.pofile_base(lang))
               basename = Path.join(dir, Path.basename(x))
               pofile = Exgettext.Util.pathescape(pofile)
               basename = Exgettext.Util.pathescape(basename)
               #x = Exgettext.Util.pathescape(x)
               poxfile = Path.join(dir, outfile)
               poxfile = Exgettext.Util.pathescape(poxfile)
               if (update) do
                 cmd = "msgmerge -U #{opts}#{pofile} #{basename}"
               else
                 cmd = "msgmerge -o #{poxfile} #{opts}#{pofile} #{basename}"
               end
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
