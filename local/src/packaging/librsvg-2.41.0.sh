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
	MOD=librsvg
	[ "" = "${VER}" ] && VER=2.41.0
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
glib
gdk-pixbuf
libcroco
libxml2
pango
EOS
}

optional_dependencies() {
	cat <<EOS
gtk3
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
GNU LIBRARY GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	if find ~/.cargo/registry/src/ -type d -iname c_vec-\* > /dev/null
	then
:		# ignore
	else
		# パッチをあてるためにライブラリーを取得しておく。
		(cd rust && cargo update)
	fi

	# c_vec 1.0.12 の crate-type = "dylib" が問題を引き起こしている。
	# Still cannot build project with 'panic = abort' ・ Issue #2738 ・ rust-lang/cargo ・ GitHub <https://github.com/rust-lang/cargo/issues/2738>
	# c_vec の trunc では crate-type そのものが削除されている。
	# Remove redundant crate-type declaration ・ GuillaumeGomez/c_vec-rs@ab0c220 ・ GitHub <https://github.com/GuillaumeGomez/c_vec-rs/commit/ab0c220d94d868489c9865974980c6948be083ed>

local IFS=""
	find ~/.cargo/registry/src/ -iname Cargo.toml -path \*/c_vec-1.0.12/\* | \
	while read f
	do
		if grep "${f}" -ie '^crate-type' > /dev/null
		then
			sed -i.orig "${f}" -e 's/^crate-type/#\0/'
		fi
	done	
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-lws2_32 -luserenv \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure  --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --enable-pixbuf-loader --enable-gtk-doc-html --disable-vala --disable-introspection
}

post_configure() {
local c
	# [2.40.16] pixbufloader が pkg-config --variable=prefix gdk-pixbuf-2.0 にインストールされる問題を修正する。
	c=`${XMINGW}/cross pkg-config --variable=prefix gdk-pixbuf-2.0 | tr --delete "\r\n" | wc --bytes` &&
	for mf in `find -name Makefile`
	do
		sed -i.orig -e '/^gdk_pixbuf_\(binarydir\|cache_file\|moduledir\)/{' -e '/${prefix}/!{' -e "s/^\([^=]\+=\s*\).\{${c}\}/\1\${prefix}/" -e "}"  -e "}" "${mf}"
	done
	if grep Makefile -e '^gdk_pixbuf_moduledir\s*=\s*${prefix}/lib/' > /dev/null
	then
:		# 置換成功。
	else
		# 置換失敗。
		echo " pixbufloader のインストール パスの置換に失敗しました。"
		grep Makefile -e '^gdk_pixbuf_\(binarydir\|cache_file\|moduledir\)'
		return 1
	fi

	# win32 では panic=unwind できないため panic=abort する。
	${XMINGW}/scripts/cross-rust --create-cargo-config rust

	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	bash ${XMINGW}/replibtool.sh mix
}

pre_make() {
	# rust まわりが不完全でリンクできない。
	# [2.41.0]
	mkdir -p "target/release"
	ln --symbolic --force "${PWD}/target/`$XMINGW/scripts/cross-rust --target-name`/release/rsvg_internals.lib" "target/release/librsvg_internals.a"
	# [2.41.1] rust 1.20.0
	mkdir -p "rust/target/release"
	ln --symbolic --force "${PWD}/rust/target/`$XMINGW/scripts/cross-rust --target-name`/release/rsvg_internals.lib" "rust/target/release/librsvg_internals.a"
	return 0
}

run_make() {
	# [2.41.0] librsvg-2 のリンクでフラグを渡してくれない。
	${XMINGW}/cross make all install LIBS="\$(LIBRSVG_LIBS) \$(LDFLAGS)"
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING* "${docdir}/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll `find lib -name \*.dll` share/doc &&
	pack_archive "${__DEVZIP}" include `find lib -name \*.a` lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files `find lib -name loaders.cache` share/thumbnailers
}


