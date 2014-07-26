Code.require_file "../../test_helper.exs", __DIR__

defmodule Mix.Tasks.ExgettextTest do
  use MixTest.Case

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
    assert File.regular? "priv/po/exgettext_test.pot"
    assert_received {:mix_shell, :info, ["xgettext exgettext_test.pot_db --output=priv/po/exgettext_test.pot"]}
    assert_received {:mix_shell, :info, ["collecting document for exgettext_test"]}
  end
  def locale(<<a,b>> <> _ = _lang) do
    <<a,b>>
  end
  def msginit_run(lang) do
    xgettext_run
    env = System.get_env("LANG")
    System.put_env("LANG", lang)
    Mix.Tasks.L10n.Msginit.run []
    System.put_env("LANG", env)
    assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
    assert File.regular? "priv/po/#{locale(lang)}.po"
    File.read!("priv/po/#{locale(lang)}.po")
  end

  def msgmerge_run(lang, replace) do
    loc = locale(lang)
    contents = msginit_run(lang)
    assert contents =~ "Language: #{loc}"
    assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
    assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
    assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
    assert contents =~ ~r/msgid \"(\"\"\n)?Hello world\"\nmsgstr \"\"/
    contents2 = Regex.replace ~r/(msgid \"(\"\"\n)?Hello world\"\nmsgstr \")/, contents, ~s(\\1#{replace})
    #      Mix.Shell.IO.info(contents2)
    File.write!("priv/po/#{loc}.po", contents2)
    Mix.Tasks.L10n.Msgmerge.run []
    rec = "msgmerge -o priv/po/#{loc}.pox priv/po/#{loc}.po priv/po/exgettext_test.pot"
    assert_received {:mix_shell, :info, [ rec ]}
    assert File.regular? "priv/po/#{loc}.pox"
    contents3 = File.read!("priv/po/#{loc}.pox")
    #      Mix.Shell.IO.info(contents3)
    assert contents2 == contents3
  end
  def msgfmt_run(lang, replace) do
    msgmerge_run(lang, replace)
    loc = locale(lang)
    Mix.Tasks.L10n.Msgfmt.run []
    assert_received {:mix_shell, :info, ["msgfmt for exgettext_test"]}
    exmopath = Exgettext.Runtime.mofile(:exgettext_test, loc)
    assert File.regular? exmopath
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
      #Mix.Shell.IO.info(contents)
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
  test "gettext" do
    in_fixture "ex_src", fn() ->
      msgfmt_run("ja_JP.UTF-8", "今日は世界")
      result = A.hello
      assert result == "今日は世界"
      env = System.get_env("LANG")
      System.put_env("LANG", "en_US.UTF-8")
      result_us = A.hello
      assert result_us == "Hello world"
      System.put_env("LANG", env)
    end
  end
end
