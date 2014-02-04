#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=gettext
	if [ "" = "${VER}" ]
	then
	VER=0.18.2
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/text"
	__ARCHIVE="${MOD}-${VER}"

	# gettext-runtime
	__RBINZIP="${MOD}-runtime-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__RDEVZIP="${MOD}-runtime-dev-${VER}-${REV}_${ARCHSUFFIX}"
	# gettext-tools
	__TDEVZIP="${MOD}-tools-dev-${VER}-${REV}_${ARCHSUFFIX}"
	__TTOOLSZIP="${MOD}-tools-${VER}-${REV}-tools_${ARCHSUFFIX}"
}

dependencies() {
	cat <<EOS
libiconv
EOS
	# optional なライブラリーはソース アーカイブの DEPENDENCIES を参照。
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --disable-java --disable-native-java --disable-rpath --disable-openmp --enable-threads=win32 --enable-relocatable --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make GNULIB_MEMCHR=0 install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	# gettext-runtime
#	pack_archive "${__RBINZIP}" bin/{libasprintf,libintl,intl}*.dll &&
	pack_archive "${__RBINZIP}" bin/{libasprintf,libintl}*.dll &&
	pack_archive "${__RDEVZIP}" include/{autosprintf,libintl}.h lib/lib{asprintf,intl}*.a share/{aclocal,doc,gettext,info} share/man/man3 &&
	store_packed_archive "${__RBINZIP}" &&
	store_packed_archive "${__RDEVZIP}" &&
	# gettext-tools
	pack_archive "${__TDEVZIP}" include/gettext-po.h lib/libgettext*.a share/man/man1 &&
	pack_archive "${__TTOOLSZIP}" bin/*.{exe,manifest,local} bin/libgettext*.dll bin/{autopoint,gettext.sh,gettextize} lib/gettext share/locale share/man/man1 &&
	store_packed_archive "${__TDEVZIP}" &&
	store_packed_archive "${__TTOOLSZIP}"
}


