Code.require_file "../../test_helper.exs", __DIR__

defmodule Mix.Tasks.ExgettextTest do
  use MixTest.Case
  use Exgettext

  defmodule ExgettextProject do
    def project do
      [ app: :exgettext_test, version: "0.1.0" ]
    end
  end
  setup do
    Mix.Project.push(ExgettextProject)
  end
  def xgettext_run do
    Mix.Tasks.L10n.Xgettext.run []
#    IO.inspect [pot: Path.wildcard("priv/po/**/*.pot")]
    assert File.regular? "priv/po/exgettext_test.pot"
    assert_received {:mix_shell, :info, ["xgettext exgettext_test.pot_db --output=priv/po/exgettext_test.pot"]}
    assert_received {:mix_shell, :info, ["collecting document for exgettext_test"]}
  end
  def msginit_run(lang) do
    xgettext_run
    env = System.get_env("LANG")
    System.put_env("LANG", lang)
    la = Exgettext.lang(lang)
#    IO.inspect [lang: lang, la: la]
    Mix.Tasks.L10n.Msginit.run []
    System.put_env("LANG", env)
    ex = "cd priv/po; msginit --locale #{lang}"
    assert_received {:mix_shell, :info, [^ex]}
    assert File.regular? "priv/po/#{la}.po"
    sp = Path.wildcard("priv/po/**/#{la}.po") 
    s = Enum.reduce(sp, "", fn(x, a) ->
#                          IO.inspect [s0: x]
                          a <> File.read!(x)
                end)
#    IO.inspect [s: s]
    s
  end

  def msgmerge_run(lang, replace) do
    loc = lang(lang)
    contents = msginit_run(lang)
    assert contents =~ "Language: #{loc}"
    assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
    assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
    assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
    assert contents =~ ~r/msgid \"(\"\"\n)?Hello world\"\nmsgstr \"\"/
    contents = File.read!("priv/po/#{loc}.po")
    contents2 = Regex.replace ~r/(msgid \"(\"\"\n)?Hello world\"\nmsgstr \")/, contents, ~s(\\1#{replace})
    File.write!("priv/po/#{loc}.po", contents2)
    Mix.Tasks.L10n.Msgmerge.run ["--locale", lang]
    rec = "msgmerge -o priv/po/#{loc}.pox -D priv/po #{loc}.po exgettext_test.pot"
    assert_received {:mix_shell, :info, [ ^rec ]}
    file = "priv/po/#{loc}.pox"
#    IO.inspect [test_file: file, cd: File.cwd, lang: lang]
    assert File.regular? file
    contents3 = File.read!("priv/po/#{loc}.pox")
    assert contents2 == contents3
  end
  def msgfmt_run(lang, replace) do
    msgmerge_run(lang, replace)
    loc = Exgettext.lang(lang)
    Mix.Tasks.L10n.Msgfmt.run ["--locale", loc]
    assert_received {:mix_shell, :info, ["msgfmt for exgettext_test"]}
    exmopath = Exgettext.Runtime.mofile(:exgettext_test, loc)
    assert File.regular? exmopath
  end

  test "test_lang" do
    assert Exgettext.lang("ja") =~ "ja"
    assert Exgettext.lang("ja_JP.UTF-8") =~ "ja"
    assert Exgettext.lang("C") =~ "C"
  end

  test "xgettext" do
    in_fixture "ex_src", fn() ->
      xgettext_run()
    end
  end
  test "msginit for japanese" do
    in_fixture "ex_src", fn() ->
      contents = msginit_run("ja_JP.UTF-8")
      assert contents =~ "Language: ja"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
    end
  end
  test "msginit for english" do
    in_fixture "ex_src", fn() ->
      contents = msginit_run("en")
#      IO.inspect [Contents: contents]
      assert contents =~ "Language: en"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
    end
  end
  test "msgmerge" do
    in_fixture "ex_src", fn() ->
      msgmerge_run("ja_JP.UTF-8", "今日は世界")                     
    end
  end
  test "msgfmt" do
    in_fixture "ex_src", fn() ->
      msgfmt_run("ja_JP.UTF-8", "今日は世界")
    end
  end
  test "gettext LANG env" do
    in_fixture "ex_src", fn() ->
      msgfmt_run("ja_JP.UTF-8", "今日は世界")
      Exgettext.setlocale("ja")
      result = A.hello
      assert result == "今日は世界"
      result_us = A.hello2
      assert result_us == "Hello world"
      env = System.get_env("LANG")
      System.put_env("LANG", "en_US.UTF-8")
      setlocale("en")
      result_us = A.hello
      assert result_us == "Hello world"
      System.put_env("LANG", env)
    end
  end
  test "gettext setlocale" do
    in_fixture "ex_src", fn() ->
      msgfmt_run("ja_JP.UTF-8", "今日は世界")
      Exgettext.setlocale("ja")
      result_us = A.hello2
      assert result_us == "Hello world"
      result = A.hello
      assert result == "Hello world"
    end
  end
  test "gettext no locale" do
    in_fixture "ex_src", fn() ->
      msgfmt_run("ja_JP.UTF-8", "今日は世界")
      Exgettext.setlocale("ja")
      result_us = A.hello2
      assert result_us == "Hello world"
      Exgettext.setlocale("en")
      result = A.hello
      assert result == "Hello world"
      result = A.helloja
      assert result == "今日は世界"
    end
  end
  test "option" do
    assert {:__block__, [], 
            [{:=, [], [{:ja, [], Mix.Tasks.ExgettextTest}, "ja"]}, 
             {:sigil_T, [context:
                         Mix.Tasks.ExgettextTest, import: Exgettext],
              [{:<<>>, [], ["Hello world"]}, 'ja']}]} ==
      Macro.expand(quote do
                     ja = "ja"
                     ~T"Hello world"ja
                   end, __ENV__)
  end
end
