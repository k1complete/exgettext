exgettext --  gettext for elixir
=====================================================


概要
=====================================================

exgettextはgettext()互換のpoファイルを用いたelixir用
地域化(l10n)パッケージです。

用語やファイルは [GNU gettext] (https://www.gnu.org/software/gettext/)
ライブラリに準じています。ファイルフォーマットはpot, po, poxはGNU
gettext互換ですが、exmo, pot_dbは独自形式です。poファイルが
GNU gettext互換ですので、GNU gettextに対応したツールが使えます。
地域化メッセージ関係のファイルはpriv配下の以下のサブディレクトリに
配置され、mix archiveで配布されます。

メッセージの場合

|拡張子|意味                       |生成コマンド |パス
|:-----|:--------------------------|:------------|:------------------------
|pot   |POテンプレート             |l10n.xgetetxt|priv/po
|pot_db|POテンプレート中間ファイル |l10n.xgetetxt|
|po    |メッセージの翻訳マスタ     |l10n.msginit |priv/po
|pox   |poとpotをマージしたファイル|l10n.msgmerge|priv/po
|exmo  |poをコンパイルしたもの     |l10n.msgfmt  |priv/lang/#{LANG}/

ドキュメントの場合

|拡張子|意味                       |生成コマンド |パス
|:-----|:--------------------------|:------------|:------------------------
|pot   |POテンプレート             |l10n.xgetetxt|priv/po/srctree/
|pot_db|POテンプレート中間ファイル |l10n.xgetetxt|
|po    |メッセージの翻訳マスタ     |l10n.msginit |priv/po/srctree/
|pox   |poとpotをマージしたファイル|l10n.msgmerge|priv/po/srctree/
|exmo  |poをコンパイルしたもの     |l10n.msgfmt  |priv/lang/#{LANG}/


インストールされるmixタスク
------------------------------------------------------

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

* mix.exsの、project/0にcompilers: Mix.compilers++[:po]を
  追加します。

* use Exgettext; を呼び出します。

* 地域化が必要なリテラル文字列を~T() sigil でマークアップ
  します。

* mix l10n.xgettextタスクにより、app.potファイルを生成します。
  priv/po/app.potファイルには、以下が格納されます。

  ~T()

  また、priv/po/path_to_src/src.potファイルには、以下が格納さ
  れます。

  @moduledoc, @doc, @typedoc

  現在の実装では、mix l10n.xgettextにより内部的にmix cleanが
  実行され、コンパイルしなおしになります。

* リリースします。

* 翻訳は翻訳チームが行いますので、プログラマはこれだけ。


翻訳チーム
-----------------------------------------------------

* パッケージを入手し、priv/po/lang.poファイルを確認します。
  ドキュメントを翻訳する際には、それぞれのソースファイルの
  プロジェクトからの相対パスpath_to_srcとすると、以下の位置に
  各ソースファイルに対応した翻訳ファイルがあります。

  priv/po/app/path_to_src/*.po

* まだ翻訳したい言語のpoファイルが無い場合、poファイルを作成するために、
  env LANG=ja mix l10n.msginit を実行します。適切な位置に
  po/ja.po, po/app/path_to_src/ja.po が作成されます(jaの場合)。
  mix l10n.msginitでは環境変数LANGを参照してどの言語へローカライズしよ
  うとしているかを判断します。内部ではGNU gettextのmsginitが呼び出され
  ます。

* 既に翻訳したい言語のpoファイル(jaならpo/ja.po)がある場合で、
  パッケージのバージョンアップなどでメッセージを翻訳し直す場合は
  mix l10n.msgmerge を実行します。内部では、path/toをpoファイルの
  ディレクトリとすると、GNU gettextの
  msgmerge -o path/to/ja.pox path/to/ja.po path/to/app.potが実行され、
  マージ結果としてpath/to/ja.poxが作成されます。マージ内容に問題がなければ
  手動でpath/to/ja.poxをpath/to/ja.poに移動します。
  --updateオプションを付けると既存のpoファイルを上書きしますので、
  普段はこちらを使うとよいでしょう。

* po/ja.po中のmsgidをmsgstrに翻訳していきます。GNU emacsのpoモードが
  便利です。

* 翻訳が終ったら、mix l10n.msgfmtを実行して path/to/ja.poから
  priv/lang/ja/app.exmoを生成します。

実行時
-----------------------------------------------------

* Exgettext.setlocale/1 でロケールを明示的に設定することが出来ます。

* ~T()は、exgettextへの呼出に置き換えられ、lang/ja/app.exmoを
  参照して対応する言語のメッセージが使用されます。オープンに失敗すると
  置き換えは行なわれません。また、対応する翻訳結果が見付からなかったり、
  ""の場合も置き換えは行なわれません。置き換えが行われない場合は
  オリジナルの文字列がそのまま出力されます。

* Exgettext.Helper.h で翻訳されたmoduledocを表示させることができます。
  import Exgettext.Helperすることで、標準のhを置き換えることもできます。

