#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=icu4c
	[ "" = "${VER}" ] && VER=68.2
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
#	DIRECTORY="${MOD}-${VER}"
	DIRECTORY="icu/source"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER//./_}-src"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}

	__LOCAL_BUILD_DIR_HOST="build_host"
	__LOCAL_BUILD_DIR_TARGET="build_target"
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
ICU License

BSD License

Lao Dictionary License

Burmese Dictionary License

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# ネイティブの icu4c が必要。
	mkdir -p "${__LOCAL_BUILD_DIR_HOST}" &&
	cd "${__LOCAL_BUILD_DIR_HOST}" &&
	sh "../runConfigureICU" Linux &&
	# TARGET は $XMINGW/package 内部で使用している(厳密には env.sh)。
	# 設定が衝突しないよう TARGET をクリアしている。
	TARGET= make &&
	cd ".."
}

run_configure() {
	if [[ -d "${__LOCAL_BUILD_DIR_TARGET}" && "" != "${__LOCAL_BUILD_DIR_TARGET}" && "." != "${__LOCAL_BUILD_DIR_TARGET}" && ".." != "${__LOCAL_BUILD_DIR_TARGET}" ]]
	then
		rm -Ir "${__LOCAL_BUILD_DIR_TARGET}"
	fi
	mkdir -p "${__LOCAL_BUILD_DIR_TARGET}" &&
	cd "${__LOCAL_BUILD_DIR_TARGET}" &&
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math \
		 ${OLD_CXX_ABI}" \
	${XMINGW}/cross-ppconfigure --prefix="${INSTALL_TARGET}" --enable-shared --disable-static \
		--enable-renaming --with-data-packaging=library \
		--enable-tracing --enable-rpath \
		--disable-samples --disable-tests \
		--with-cross-build="${PWD}/../${__LOCAL_BUILD_DIR_HOST}" &&
	cd ".."
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
#	bash ${XMINGW}/replibtool.sh shared
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
#	bash ${XMINGW}/replibtool.sh static-libgcc
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
	echo skip > /dev/null
}

run_make() {
	cd "${__LOCAL_BUILD_DIR_TARGET}" &&
	TARGET= ${XMINGW}/cross make all install &&
	cd ".."
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" ../LICENSE*
}

run_pack() {
local version=$(sed "${__LOCAL_BUILD_DIR_TARGET}/icudefs.mk" -n -e 's/^VERSION\s*=\s*//p')
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" bin/icu-config include lib/*.a lib/{icu,pkgconfig} share/icu/${version}/{config,install-sh,mkinstalldirs} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files share/icu/${version}/LICENSE
}



