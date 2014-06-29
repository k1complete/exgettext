defmodule L10nTest do
  use Exgettext
  import Exgettext
  def test do
#    :gettext_server.start({L10nTest, []})
    {
     txt("Hello World!\nA what is this!"),
     txt("Hello World!\nA \"what\" \\is \tthis!\n"),
     txt("Hello World!\nA what is this!\n"),
     ~T"Hello World!\nA what is this!\n",
     txt2("Hello World!\nA what is this!\n", 'ja')
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
