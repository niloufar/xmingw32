#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCHSUFFIX は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=mingw-w64-gcc-runtime
	[ "" = "${VER}" ] && VER=6.3.1
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="."

	# 内部で使用する変数。

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
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
EOS
}

pre_make() {
	mkdir -p "${INSTALL_TARGET}/bin"
	cp "/usr/${TARGET}/bin"/*.dll "${INSTALL_TARGET}/bin/."
	rm "${INSTALL_TARGET}/bin"/libwinpthread*.dll
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin &&
	store_packed_archive "${__BINZIP}"
#	put_exclude_files 
}



