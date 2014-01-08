#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
local typ=
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=fftw
	if [ "" = "${VER}" ]
	then
	VER=3.3.3
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/math"
	__ARCHIVE="${MOD}-${VER}"

	if [ ! "" = "${FEATURE}" ]
	then
#		typ=`echo ${VER} | cut --delimiter=. --fields=1`
		case "${FEATURE}" in
		single|float)
#			typ="${typ}f"
			;;
		double)
#			typ="${typ}l"
			;;
		quad)
#			typ="${typ}q"
			;;
		*)
			__fail_exit "${FEATURE} はサポートしていないタイプです。 float, single, double, quad のいずれかを指定してください。"
			;;
		esac
	fi
	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
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
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	echo skip > /dev/null
}

pre_configure() {
	echo skip > /dev/null
}

run_configure_float() {
	__run_configure --enable-float --enable-sse2 --enable-avx
}

run_configure_single() {
	__run_configure --enable-single --enable-sse2 --enable-avx
}

run_configure_double() {
	__run_configure --enable-long-double
}

run_configure_quad() {
	__run_configure --enable-quad-precision
}

run_configure() {
	__run_configure --enable-sse2 --enable-avx
}

__run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math  -static-libgcc" \
	${XMINGW}/cross-configure --enable-shared --prefix="${INSTALL_TARGET}" --disable-alloca --with-our-malloc --with-windows-f77-mangling --enable-threads --with-combined-threads "$@"
}

post_configure() {
	sed -i.orig -e 's!^#define USING_POSIX_THREADS .\+$!/* \0 */!' config.h
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make all install
}

run_make_test() {
	echo skip > /dev/null
}

run_make_example() {
	echo skip > /dev/null
}

pre_pack() {
	echo skip > /dev/null
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.a share/info &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} bin/fftw-wisdom-to-conf share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



