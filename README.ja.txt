Ubuntu 12.04 で MinGW32 をクロスビルドするためのスクリプト集です。
公開を考えて作成していないスクリプトですので、ひどい内容となっています。

スクリプトを /usr/xmingw/xmingw32 に配置してください。異なる場所に配置したい
場合は scripts ディレクトリーの当該箇所を書き換えてください。

ここからの作業はシェル(bash)で行います。

Ubuntu の開発環境を整えます。つぎのツール、ライブラリーを使用するために
インストールします。

sudo apt-get install gcc-mingw-w64 g++-mingw-w64
sudo apt-get install automake autoconf libtool
sudo apt-get install intltool
#sudo apt-get install flex bison
#sudo apt-get install gobject-introspection
sudo apt-get install libgtk2.0-dev
sudo apt-get install libffi-dev
sudo apt-get install bsdtar 7zip*

配置したディレクトリーに移動し、 bash make_link.sh を実行します。

. env.sh を実行します。行頭のピリオド(.)を忘れずにつけてください。
env.sh は環境変数に値を設定します。
env.sh が設定する環境編数の一覧と既定値です。

XMINGW=/usr/xmingw/xmingw32
XLOCAL=${XMINGW}/local
XLIBRARY=${XLOCAL}/libs
XLIBRARY_SET=${XLIBRARY}/default_set
TARGET=mingw32
BUILD_CC="${XMINGW}/bin/build-cc "

$XMINGW/cross コマンドで MinGW32 環境下でコマンドを実行します。
同様に $XMINGW/cross-configure, $XMINGW/cross-cmake は 
MinGW32 環境下で設定を行い、 configure, cmake を実行するコマンドです。
bin/build-cc コマンドは MinGW32 環境下で Ubuntu 環境の gcc を実行する
ためのコマンドです。

local/src/packaging ディレクトリーにライブラリーのビルド スクリプトを置いて
います。ビルドに使用するライブラリー、ソースの保管場所、
ワーキング ディレクトリー、パッケージの保存場所はやや特殊な構成となっています。

ビルドに使用するライブラリーは local/libs に下位ディレクトリーを作成し
配置します。 $XMINGW/cross コマンドは通常は lib, gtk, gimp ディレクトリーを
参照します。参照ディレクトリーは自由に切り替えられます。参照ディレクトリーを
列挙したファイルを作成し、 XLIBRARY_SET 環境変数にファイル パスをセットします。
設定例は local/libs/gimp_build_set を参照してください。
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
ディレクトリーは作業後に削除されません。作業後は手動で削除してください。

作成されたパッケージは local/archives に保存されます。

ビルド スクリプトで使用するこれらディレクトリーは scripts/build_lib.func で
設定しています。環境変数の一覧と既定値です。

XLIBRARY_SOURCES=${XLOCAL}/src
XLIBRARY_ARCHIVES=${XLOCAL}/archives
XLIBRARY_TEMP=${XLOCAL}/src/build

ビルド スクリプトはこのように実行します。実行するとログが作成されます。エラーなく
終了すると最後に success completed. と表示されます。

bash bzip2-1.0.6.sh



