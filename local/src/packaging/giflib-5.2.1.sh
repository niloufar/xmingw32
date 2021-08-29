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
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=giflib
	[ "" = "${VER}" ] && VER=5.2.1
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

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
MIT License

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# soname の削除、 dll の拡張子の変更、実行可能ファイルに拡張子を追加。
	sed -i.orig Makefile \
		-e 's/ -Wl,-soname -Wl,\(lib[^.]\+\)\.so\.[^ \t]\+/ -Wl,--out-implib,\1.dll.a/g' \
		-e 's/\.so\(:\| \|\t\|$\)/-$(LIBMAJOR).dll\1/g' \
		-e 's|\$(LIBDIR)\(/libgif\)\.so\.\$(LIBVER)\"|$(BINDIR)\1-$(LIBMAJOR).dll\"|' \
		-e '/^\s\+\$(INSTALL).\+ libgif.a / {' \
			-e 'a\	$(INSTALL) -m 644 libgif.dll.a "$(DESTDIR)$(LIBDIR)/libgif.dll.a"' \
		-e '}' \
		-e 's|^UOBJECTS = .\+)$|\0 ./libgif.dll.a|' \
		-e '/^\$(UTILS)::/ {' \
			-e 'c $(UTILS):: libutil.a libgif.dll.a' \
			-e 'a \	$(CC) $(CFLAGS) $(LDFLAGS) -o $@.exe $@.c $^' \
		-e '}' \
		-e '/^install-bin:/,/^.\+:/ {' \
			-e '/^\s\+\$(INSTALL) \$\^/ s/\$\^/$(addsuffix .exe,$^)/' \
		-e '}'
}

run_make() {
	${XMINGW}/cross make all install \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	OFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	PREFIX="${INSTALL_TARGET}"
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	cp COPYING "${docdir}/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files lib/*.so lib/*.so.*
}



