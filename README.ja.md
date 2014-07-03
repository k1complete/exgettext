=====================================================
 exgettext --  gettext for elixir
=====================================================

exgettextはgettext()互換のpoファイルを用いたelixir用
地域化(l10n)パッケージです。

用語やファイルは [GNU gettext] (https://www.gnu.org/software/gettext/)
ライブラリに準じています。ファイルフォーマットはpot, po, poxはGNU
gettext互換ですが、exmo, pot_dbは独自形式です。poファイルが
GNU gettext互換ですので、GNU gettextに対応したツールが使えます。

|拡張子   | 意味                        | 生成コマンド      |
|:--------|:----------------------------|:------------------|
| pot     | POテンプレート              | l10n.xgetetxt     |
| pot_db  | POテンプレート中間ファイル  | l10n.xgetetxt     |
| po      | メッセージの翻訳マスタ      | l10n.msginit      |
| pox     | poとpotをマージしたファイル | l10n.msgmerge     |
| exmo    | poをコンパイルしたもの      | l10n.msgfmt       |


* l10n.xgettext: プログラムソースからpotを生成
* l10n.msginit : potファイルからpoを初期化
* l10n.msgmerge: potとpoをマージしてpoxを生成
* l10n.msgfmt  : poからexmoを生成

インストール
=====================================================

GNU gettextをインストールしておきます。exgettextはmsginit, msgmergeを内
部で使用します。


ワークフロー
=====================================================

以下では、パッケージとしてappを日本語(ja)にローカライズする例としていま
す。

プログラマ
-----------------------------------------------------

* mix.exsにdeps: exgettextを追加します。

* use Exgettext; import Exgettext; を呼び出します。

* 地域化が必要なリテラル文字列を~T() sigil でマークアップ
  します。

* mix l10n.xgettextタスクにより、app.potファイルを生成します。app.potファイ
  ルには、以下が格納されます。

  @moduledoc, @doc,~T()

  現在の実装ではは、mix l10n.xgettextにより内部的にmix cleanが実行され
  コンパイルしなおしになります。

* リリースします。

* 翻訳は翻訳チームが行いますので、プログラマはこれだけ。


翻訳チーム
-----------------------------------------------------

* パッケージを入手し、app.potファイルを確認します。

* まだ翻訳したい言語のpoファイルが無い場合、poファイルを作成する
  ために、 mix l10n.msginit を実行します。po/ja.po が作成されます。

* 既にpo/ja.poがある場合で、パッケージのバージョンアップなどでメッセー
  ジを翻訳仕直す場合はmix l10n.msgmerge を実行します。内部では、GNU
  gettextのmsgmerge -o po/ja.pox po/ja.po app.potが実行され、マージ結果
  としてpo/ja.poxが作成されます。マージ内容に問題がなければpo/ja.poxを
  po/ja.poに移動します。

* po/ja.po中のmsgidをmsgstrに翻訳していきます。GNU emacsのpoモードが
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
