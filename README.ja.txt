Ubuntu 12.04 で MinGW-w64 をクロスビルドするためのスクリプト集です。
公開を考えて作成していないスクリプトですので、ひどい内容となっています。

スクリプトを /usr/xmingw/xmingw32 に配置してください。異なる場所に配置したい
場合は scripts ディレクトリーのスクリプトに記述された当該箇所を書き換えてくださ
い。

ここからの作業はシェル(bash)で行います。

Ubuntu の開発環境を整えます。つぎのツール、ライブラリーを使用するために
インストールします。

sudo apt-get install gcc-mingw-w64 g++-mingw-w64 mingw-w64-tools
sudo apt-get install automake autoconf libtool
sudo apt-get install intltool
#sudo apt-get install flex bison
#sudo apt-get install gobject-introspection
sudo apt-get install libgtk2.0-dev
sudo apt-get install libffi-dev
sudo apt-get install bsdtar 7zip*
sudo apt-get install unix2dos

配置したディレクトリーに移動し、 bash make_link.sh を実行します。

. env.sh を実行します。行頭のピリオド(.)を忘れずにつけてください。
env.sh は環境変数に値を設定します。引数 win32 で MinGW32、 win64 で 
MinGW-W64 環境の設定を行います。
下は env.sh が設定する環境編数の一覧と既定値です。

XMINGW=/usr/xmingw/xmingw32
XLOCAL=${XMINGW}/local
XLIBRARY=${XLOCAL}/libs
XLIBRARY_SET=${XLIBRARY}/default_set
TARGET=mingw32
BUILD_CC="${XMINGW}/bin/build-cc "

$XMINGW/cross コマンドで MinGW 環境下でコマンドを実行します。
同様に $XMINGW/cross-configure, $XMINGW/cross-cmake は 
MinGW32 環境下で設定を行い、 configure, cmake を実行するコマンドです。
bin/build-cc コマンドは MinGW 環境下で Ubuntu 環境の gcc を実行する
ためのコマンドです。

local/src/packaging ディレクトリーにライブラリーのビルド スクリプトを置いて
います。ビルドに使用するライブラリー、ソースの保管場所、
ワーキング ディレクトリー、パッケージの保存場所はやや特殊な構成となっています。

ビルドに使用するライブラリーは local/libs に下位ディレクトリーを作成し
配置します( win64 は local/libs64 に配置します)。 $XMINGW/cross コマンドは
通常は lib, gtk, gimp ディレクトリーを参照します。参照ディレクトリーは自由に
切り替えられます。参照ディレクトリーを列挙したファイルを作成し、 XLIBRARY_SET 
環境変数にファイル パスをセットします。設定例は local/libs/gimp_build_set を
参照してください。
 XLIBRARY_SET 環境変数の設定は $XMINGW/cross コマンドの --cflags, 
--ldflags, --libset オプションに影響します。

ソースの保管場所は次のような構成になっています。
# この構成は将来変更されるでしょう。

local/src
├── gimp
│   ├── core
│   ├── dep
├── gtk+
└── libs
    ├── compress
    ├── etc
    ├── lang
    ├── math
    ├── pic
    └── text

ワーキング ディレクトリーは local/src/build に作成されます。ここに作成された
ディレクトリーは作業後に削除されません。手動で削除してください。

作成されたパッケージは local/archives に保存されます。

ビルド スクリプトで使用するこれらディレクトリーは scripts/build_lib.func で
設定しています。環境変数の一覧と既定値です。

XLIBRARY_SOURCES=${XLOCAL}/src
XLIBRARY_ARCHIVES=${XLOCAL}/archives
XLIBRARY_TEMP=${XLOCAL}/src/build

ビルドスクリプトの雛形は local/src/template.sh にあります。 <MODULE NAME>, 
<VERSION>, <SUBDIR> を置き換え、 configure, make, pack 関係を編集してく
ださい。

ビルド スクリプトはこのように実行します。実行するとログが作成されます。エラーな
く終了すると最後に SUCCESS COMPLETED. と表示されます。

$XMINGW/package bzip2-1.0.6

ビルドした実行ファイルが gcc の dll とリンクしている場合があります。 dll は次の
場所に保存されています。 i686-w64-* が win32 、 x86_64-w64-* が win64 用です。

> /usr/lib/gcc/i686-w64-mingw32/4.6
> /usr/lib/gcc/x86_64-w64-mingw32/4.6



