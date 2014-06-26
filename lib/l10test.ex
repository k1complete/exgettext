defmodule L10nTest do
  use Exgettext
  import Exgettext
  def test do
    :gettext_server.start({L10nTest, []})
    {
     :erlang.list_to_binary(txt("Hello World!\nA what is this!")),
             :erlang.list_to_binary(txt("Hello World!\nA \"what\" \\is \tthis!\n")),
             :erlang.list_to_binary(txt("Hello World!\nA what is this!\n")),
             :erlang.list_to_binary(~T"Hello World!\nA what is this!\n"),
             :erlang.list_to_binary(txt2("Hello World!\nA what is this!\n", 'ja')),
             :erlang.list_to_binary(stxt("Hello World! $hello$", [hello: txt("H")])),
             :erlang.list_to_binary(stxt2("Hello World! $hello$", [hello: txt("H")], 'en'))
    }
  end
  def gettext_dir() do
    '.'
  end
  def gettext_def_lang() do
    to_char_list(System.get_env("LANG"))
    'ja'
  end
end
