=====================================================
 exgettext --  gettext for elixir
=====================================================

exgettextはgettext()互換のpoファイルを用いたelixir用
地域化(l10n)パッケージです。

用語やファイルは [GNU gettext] (https://www.gnu.org/software/gettext/) 
ライブラリに準じています。

|拡張子   | 意味                               | 生成コマンド
|:--------|:-----------------------------------|:-------------
| pot     | ポータブルオブジェクトテンプレート | xgetetxt
| po      | メッセージの翻訳マスタ             | msginit
| pox     | poとpotをマージしたファイル        | msgmerge
| exmo    | poをコンパイルしたもの             | msgfmt


* xgettext: プログラムソースからpotを生成
* msginit : potファイルからpoを初期化
* msgmerge: potとpoをマージしてpoxを生成
* msgfmt  : poからexmoを生成


ワークフロー
=====================================================

以下では、パッケージとしてappを日本語(ja)にローカライズする
例としています。

プログラマ
-----------------------------------------------------

* mix.exsにdeps: exgettextを追加します。

* use Exgettext; import Exgettext; を呼び出します。

* 地域化が必要なリテラル文字列を~T() sigil でマークアップ
  します。

* mix xgettextタスクにより、app.potファイルを生成します。app.potファイ
  ルには、以下が格納されます。

  @moduledoc, @doc,~T()

  現在の実装ではは、mix xgettextにより内部的にmix cleanが実行されコ
  ンパイルしなおしになります。

* リリースします。

* 翻訳は翻訳チームが行いますので、プログラマはこれだけ。


翻訳チーム
-----------------------------------------------------

* パッケージを入手し、app.potファイルを確認します。

* まだ翻訳したい言語のpoファイルが無い場合、poファイルを作成する
  ために、 mix l10n.msginit を実行します。po/ja.po が作成されます。

* 既にpo/ja.poがある場合で、パッケージのバージョンアップなどでメッセー
  ジを翻訳仕直す場合はmix l10n.msgmerge を実行します。内部では、
  msgmerge -o po/ja.pox po/ja.po app.potが実行され、マージ結果として
  po/ja.poxが作成されます。マージ内容に問題がなければpo/ja.poxを
  po/ja.poに移動します。

* po/ja.po中のmsgidをmsgstrに翻訳していきます。emacsのpoモードが
  便利です。

* 翻訳が終ったら、mix l10n.msgfmtを実行して po/ja.poからlang/ja/app.exmo
  を生成します。
  

実行時
-----------------------------------------------------

* Exgettext.setlocale/1 でロケールを明示的に設定することが出来ます。

* ~T()は、exgettextへの呼出に置き換えられ、lang/ja/app.exmoを
  参照して対応する言語のメッセージが使用されます。オープンに失敗すると
  置き換えは行なわれません。

[* Exgettext.h で翻訳されたmoduledocを表示させることができます。]
