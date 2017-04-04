#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=poppler
	[ "" = "${VER}" ] && VER=0.22.1
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
cairo
freetype2
lcms2
libjpeg
libpng
openjpeg
tiff
zlib
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

# 0.22.5 の問題に対処する。
pre_configure() {
	# strcat_s は vc2005 から導入された関数。
	# strcat を使用した。 test では問題ないだろう。
	sed -i.orig -e 's/strcat_s(buf, buf_size, filename)/strcat(buf, filename)/' test/perf-test.cc
}

run_configure() {
	# [0.43.0] configure --help と configure.ac は --disable-nss になっているが、
	# configure は --disable-libnssで処理している。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	`${XMINGW}/cross pkg-config libpng --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="${OLD_CXX_ABI}" \
	${XMINGW}/cross-configure --disable-static --disable-gtk-doc --disable-gtk-doc-html --without-x --disable-nss --disable-libnss -disable-poppler-qt4 -disable-poppler-qt5 --enable-zlib --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# shared ファイルを作ってくれない場合の対処。
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	# libstdc++ を静的リンクする。
	bash ${XMINGW}/replibtool.sh shared mix static-libgcc
#	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING "${docdir}/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


