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
	MOD=pthreads
	if [ "" = "${VER}" ]
	then
	VER=2.9.1
	REV=1
	fi
	DIRECTORY="${MOD}-w32-`echo "${VER}" | sed -e"s/\./-/g"`-release"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/etc"
	__ARCHIVE="${MOD}-w32-`echo "${VER}" | sed -e"s/\./-/g"`-release"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_make() {
	${XMINGW}/cross make -f GNUmakefile \
		OPT="\$(CLEANUP) \
			`${XMINGW}/cross --archcflags` \
			-pipe -O2 -fomit-frame-pointer -ffast-math" \
		LFLAGS="-Wl,--enable-auto-image-base -Wl,-s" \
		CROSS=mingw32- DEVROOT="${INSTALL_TARGET}" \
		clean GC-inlined GCE-inlined
}

pre_pack() {
	(mkdir -p "${INSTALL_TARGET}" &&
	cd "${INSTALL_TARGET}" &&
	mkdir -p bin &&
	mkdir -p include &&
	mkdir -p lib
	) &&
	(
	cp pthread.h semaphore.h sched.h "${INSTALL_TARGET}/include/." &&
	cp *.dll "${INSTALL_TARGET}/bin/." &&
	cp *.a "${INSTALL_TARGET}/lib/."
	)
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


