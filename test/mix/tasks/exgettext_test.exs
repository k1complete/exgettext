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

  test "xgettext" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "exgettext_test.pot_db"
      assert_received {:mix_shell, :info, ["xgettext exgettext_test.pot_db --output=priv/po/exgettext_test.pot"]}
      assert_received {:mix_shell, :info, ["collecting document for exgettext_test"]}
    end
  end
  test "msginit for japanese" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "priv/po/exgettext_test.pot"
      env = System.get_env("LANG")
      System.put_env("LANG", "ja_JP.UTF-8")
      #Mix.Shell.IO.cmd("echo $LANG")

      Mix.Tasks.L10n.Msginit.run []
      assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
      assert File.regular? "priv/po/ja.po"
      contents = File.read!("priv/po/ja.po")
      
      #Mix.Shell.IO.info(contents)
      assert contents =~ "Language: ja"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
      System.put_env("LANG", env)
    end
  end
  test "msginit for english" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "priv/po/exgettext_test.pot"

      env = System.get_env("LANG")
      System.put_env("LANG", "en")
      Mix.Tasks.L10n.Msginit.run []
      assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
      assert File.regular? "priv/po/en.po"
      contents = File.read!("priv/po/en.po")
      #Mix.Shell.IO.info(contents)
      assert contents =~ "Language: en"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
      System.put_env("LANG", env)
    end
  end
  test "msgmerge" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "priv/po/exgettext_test.pot"
      env = System.get_env("LANG")
      System.put_env("LANG", "ja_JP.UTF-8")
      Mix.Tasks.L10n.Msginit.run []
      assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
      assert File.regular? "priv/po/ja.po"
      contents = File.read!("priv/po/ja.po")
      assert contents =~ "Language: ja"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
      System.put_env("LANG", env)
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world\"\nmsgstr \"\"/
      contents2 = Regex.replace ~r/(msgid \"(\"\"\n)?Hello world\"\nmsgstr \")/, contents, ~S(\1今日は世界)
#      Mix.Shell.IO.info(contents2)
      File.write!("priv/po/ja.po", contents2)
      Mix.Tasks.L10n.Msgmerge.run []
      assert_received {:mix_shell, :info, ["msgmerge -o priv/po/ja.pox priv/po/ja.po priv/po/exgettext_test.pot"]}
      assert File.regular? "priv/po/ja.pox"
      contents3 = File.read!("priv/po/ja.pox")
#      Mix.Shell.IO.info(contents3)
      assert contents2 == contents3
    end
  end
  test "msgfmt" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "priv/po/exgettext_test.pot"
      env = System.get_env("LANG")
      System.put_env("LANG", "ja_JP.UTF-8")
      Mix.Tasks.L10n.Msginit.run []
      assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
      assert File.regular? "priv/po/ja.po"
      contents = File.read!("priv/po/ja.po")
      assert contents =~ "Language: ja"
      assert contents =~ ~r/msgid \"(\"\"\n)?module doc for A/
      assert contents =~ ~r/msgid \"(\"\"\n)?method doc for hello/
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world/
      System.put_env("LANG", env)
      assert contents =~ ~r/msgid \"(\"\"\n)?Hello world\"\nmsgstr \"\"/
      contents2 = Regex.replace ~r/(msgid \"(\"\"\n)?Hello world\"\nmsgstr \")/, contents, ~S(\1今日は世界)
      File.write!("priv/po/ja.po", contents2)
      Mix.Tasks.L10n.Msgfmt.run []
      assert_received {:mix_shell, :info, ["msgfmt for exgettext_test"]}
#      assert_received {:mix_shell, :info, ["priv/po/ja.po .*gettext_test.exmo"]}
#      Mix.Shell.IO.info(Path.relative_to(Exgettext.Runtime.mofile(:exgettext_test, "ja"), System.cwd))
      exmopath = Exgettext.Runtime.mofile(:exgettext_test, "ja")
      assert File.regular? exmopath
    end
  end
  test "gettext" do
    in_fixture "ex_src", fn() ->
      Mix.Tasks.L10n.Xgettext.run []
      assert File.regular? "priv/po/exgettext_test.pot"
      env = System.get_env("LANG")
      System.put_env("LANG", "ja_JP.UTF-8")
      Mix.Tasks.L10n.Msginit.run []
      assert_received {:mix_shell, :info, ["cd priv/po; msginit"]}
      assert File.regular? "priv/po/ja.po"
      contents = File.read!("priv/po/ja.po")
      contents2 = Regex.replace ~r/(msgid \"(\"\"\n)?Hello world\"\nmsgstr \")/, contents, ~S(\1今日は世界)
      File.write!("priv/po/ja.po", contents2)
      Mix.Tasks.L10n.Msgfmt.run []
      assert_received {:mix_shell, :info, ["msgfmt for exgettext_test"]}
      exmopath = Exgettext.Runtime.mofile(:exgettext_test, "ja")
#      Mix.Shell.IO.info(exmopath)
#      Mix.Shell.IO.info(System.cwd)
      assert File.regular? exmopath
      result = A.hello
      assert result == "今日は世界"
      System.put_env("LANG", "en_US.UTF-8")
      result_us = A.hello
      assert result_us == "Hello world"
      System.put_env("LANG", env)
    end
  end
end
