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
	XLIBRARY_SET="gtk"

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
	RUST_TARGET="`$XMINGW/scripts/cross-rust --target-name`" \
	${XMINGW}/cross-configure  --enable-shared --disable-static --disable-rpath --prefix="${INSTALL_TARGET}" \
		--enable-pixbuf-loader \
		--enable-gtk-doc-html --enable-vala --enable-introspection
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
	if [[ ! -e './.cargo/config' ]]
	then
		${XMINGW}/scripts/cross-rust --create-cargo-config ./rust
	else
		# [2.42.3] 
		# rust フォルダーから他へソースが移動し .cargo/config が作成された。
		# rsvg_internals, vendor フォルダーに影響を与えるためトップに設定を書き込む。
		${XMINGW}/scripts/cross-rust --create-cargo-config .
	fi

	# [2.42.0]
	# cargo build --target x86_64-w64-mingw32 するが triplet が間違い。
	# cross-rust に任せる。
	sed -i.orig Makefile -e 's/^CARGO_TARGET_ARGS = --target=$(host)/#\0/'

	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	bash ${XMINGW}/replibtool.sh mix
}

pre_make() {
local version="`sed configure -ne "s/^PACKAGE_VERSION='\([0-9.-]\+\).*/\1/p"`"
local rust_target="`$XMINGW/scripts/cross-rust --target-name`"
	# rust まわりが不完全でリンクできない。
	case "${version}" in
	2.41.0)
		# [2.41.0]
		mkdir -p "target/release"
		ln --symbolic --force \
			"${PWD}/target/${rust_target}/release/rsvg_internals.lib" \
			"target/release/librsvg_internals.a"
		;;
	2.41.[12])
		# [2.41.1] rustc 1.20.0
		mkdir -p "rust/target/release"
		ln --symbolic --force \
			"${PWD}/rust/target/${rust_target}/release/rsvg_internals.lib" \
			"rust/target/release/librsvg_internals.a"
		;;
	2.42.[012])
		# [2.42.0] rustc 1.23.0
		mkdir -p "rust/target/${TARGET}/release/"
		ln --symbolic --force \
			"${PWD}/rust/target/${rust_target}/release/rsvg_internals.lib" \
			"rust/target/${TARGET}/release/librsvg_internals.a"
		;;
	2.42.[3456] | 2.44.1[0134])
		# [2.42.3] rustc 1.25.0
		mkdir -p "target/${TARGET}/release/"
		ln --symbolic --force \
			"${PWD}/target/${rust_target}/release/rsvg_internals.lib" \
			"target/${TARGET}/release/librsvg_internals.a"
		# [2.42.6] rustc 1.26.2
		sed -i.orig Makefile -e "s/^RUST_TARGET = \(x86_64\|i686\)-w64-mingw32/RUST_TARGET = ${rust_target}/"
		;;
	2.46.[34])
		# [2.46.3] rustc 1.39.0
		sed -i.orig Makefile -e "s/^RUST_TARGET = \(x86_64\|i686\)-w64-mingw32/RUST_TARGET = ${rust_target}/"

		mkdir -p "target/${TARGET}/release/"
		ln --symbolic --force \
			"${PWD}/target/${rust_target}/release/rsvg_c_api.lib" \
			"target/${TARGET}/release/rsvg_c_api.lib"
		ln --symbolic --force \
			"${PWD}/target/${rust_target}/release/rsvg_c_api.lib" \
			"librsvg_c_api.a"
		sed -i Makefile -e "/^librsvg_2_la_LIBADD/,/^\s*$/ {" -e "s/librsvg_c_api.la/${PWD}/librsvg_c_api.la/" -e "}"
		;;
	2.48.7 | 2.50.*)
		# [2.48.7] rustc 1.44.0
		mkdir -p "target/${rust_target}/release/"
		ln --symbolic --force \
			"${PWD}/target/${rust_target}/release/librsvg_c_api.a" \
			"target/${rust_target}/release/rsvg_c_api.lib"
		;;
	*)
		echo "${version} はサポートしていないバージョンです。 rust まわりのパッチを確認してください。"
		return 1;
		;;
	esac
	return 0
}

run_make() {
	# [2.41.0] librsvg-2 のリンクでフラグを渡してくれない。
	WINEPATH="${PWD}/.libs" \
	${XMINGW}/cross make all install LIBS="\$(LIBRSVG_LIBS) \$(LDFLAGS)"
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
local bin_add=""
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll `find lib -name \*.dll` lib/girepository-* share/{doc,locale} &&
	pack_archive "${__DEVZIP}" include `find lib -name \*.a` lib/pkgconfig share/gir-* share/vala/vapi/ &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files `find lib -name loaders.cache` share/thumbnailers
}


