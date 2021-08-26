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
	XLIBRARY_SET="gtk"

	# package に返す変数。
	MOD=gobject-introspection
	[ "" = "${VER}" ] && VER=1.66.1
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
#	__DOCZIP="${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}"
	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"

	# アーキテクチャを指定しない場合は NOARCH=yes する。
#	NOARCH=yes
}

dependencies() {
	cat <<EOS
glib
libffi
EOS
}

optional_dependencies() {
	cat <<EOS
cairo
doctool
EOS
}

license() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# ldd の出力をうまく解析できない問題への対処。
	# libglib-2.0-0.dll のようなファイル名に対応する。
	sed -i.orig giscanner/shlibs.py \
		-e 's/^\s*lib%s$/\0(?:-[0-9]+)?/'

	# mingw の ld は利用していないライブラリーをリンクせず、
	# shlibs.py でのチェックに失敗する。
	patch_adhoc -p 1 <<EOS
--- gobject-introspection.orig/giscanner/ccompiler.py
+++ gobject-introspection/giscanner/ccompiler.py
@@ -217,17 +217,18 @@
 
             runtime_paths.append(library_path)
 
-        for library in libraries + extra_libraries:
-            if self.check_is_msvc():
-                # Note that Visual Studio builds do not use libtool!
-                if library != 'm':
-                    args.append(library + '.lib')
-            else:
-                # If we get a real filename, just use it as-is
-                if library.endswith(".la") or os.path.isfile(library):
-                    args.append(library)
-                else:
-                    args.append('-l' + library)
+        if not self.check_is_msvc():
+            args.append("-Wl,--whole-archive")
+
+        self.get_external_link_flags(args, libraries)
+
+        if not self.check_is_msvc():
+            args.append("-Wl,--no-whole-archive")
+            args.append("-Wl,--allow-multiple-definition")
+            args.append("-Wl,-u,___deregister_frame_info")
+            args.append("-Wl,-u,___register_frame_info")
+
+        self.get_external_link_flags(args, extra_libraries)
 
         for envvar in runtime_path_envvar:
             if envvar in os.environ:
@@ -247,7 +248,8 @@
                 if library != 'm':
                     args.append(library + ".lib")
             else:
-                if library.endswith(".la"):  # explicitly specified libtool library
+                # If we get a real filename, just use it as-is
+                if library.endswith(".la") or os.path.isfile(library):
                     args.append(library)
                 else:
                     args.append('-l' + library)
EOS


	# ホストの python3 を使用する。
	sed -i.orig meson.build \
		-e "s/^cc\.check_header('Python\.h'/# \0/" \
#		-e "/^if meson.version().version_compare(/,/^endif/ s/^/#/"

	# gir のビルドにホストの _giscanner を使用する。
	sed -i.orig gir/meson.build \
		-e '/depends: giscanner_pymod/ d' \
		-e 's/, giscanner_pymod//'

	# gir のビルドにホストの _giscanner を使用する。
	sed -i.orig giscanner/meson.build \
		-e "/^giscanner_pymod = python.extension_module('_giscanner',/,/^)/ {" \
			-e 's/^/# /' \
		-e '}' \
		-e "$ agiscanner_pymod = find_program('g-ir-scanner')" \
		-e "$ agiscanner_built_files = []"

	# gir のビルドにホストの giscanner を使用する。
:	sed -i.orig tools/g-ir-tool-template.in \
		-e '/^filedir = os.path.dirname(__file__)/ {' \
		-e 's/^/# \0/' \
		-e "afiledir = os.path.dirname('/usr/bin/g-ir-scanner')" \
		-e '}'
:	chmod +x tools/g-ir-tool-template.in

	sed -i.orig tools/g-ir-tool-template.in \
		-e '/import builtins/ aimport shlex' \
		-e '/^sys.exit(@TOOL_FUNCTION@(sys.argv))/ {' \
			-e 's/^/# /' \
			-e "asys.exit(@TOOL_FUNCTION@(sys.argv + shlex.split(os.environ.get('CROSS_EXTRA_GISCANNER_CFLAGS','')) ))" \
		-e '}' \
		-e '/^filedir = os.path.dirname(__file__)/ {' \
			-e "asys.path.append(os.path.join(filedir, '..'))" \
		-e '}'
	chmod +x tools/g-ir-tool-template.in
}

run_configure() {
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Dgtk_doc=false \
		-Dgi_cross_binary_wrapper=wine \
		-Dbuild_introspection_data=true
}

post_configure() {
:	sed -i.orig _build/tools/g-ir-scanner \
		-e '/import builtins/ aimport shlex' \
		-e '/^sys.exit(scanner_main(sys.argv))/ {' \
			-e 's/^/# /' \
			-e "asys.exit(scanner_main(sys.argv + shlex.split(os.environ.get('CROSS_EXTRA_GISCANNER_CFLAGS','')) ))" \
		-e '}' \
		-e '/^filedir = os.path.dirname(__file__)/ {' \
			-e "asys.path.append(os.path.join(filedir, '..'))" \
		-e '}'

	ln -s -f "$PWD/giscanner" _build/

	# gir のビルドにホストの giscanner を使用する。
#	ln -s -f "$(find /usr/lib/gobject-introspection/giscanner -name _giscanner.cpython-\*.so | head -n 1)" giscanner/
#	mkdir -p _build/giscanner
	ln -s -f "$(find /usr/lib/gobject-introspection/giscanner -name _giscanner.cpython-\*.so | head -n 1)" _build/giscanner/
}

:post_configure() {
	# gir のビルドにホストの giscanner を使用する。
	mkdir -p _build/lib/gobject-introspection
#	ln -s -f "$PWD/giscanner" _build/lib/gobject-introspection/
#	ln -s -f "/usr/lib/gobject-introspection/giscanner/__pycache__" _build/lib/gobject-introspection/giscanner/
	ln -s -f "$PWD/giscanner" _build/
#	ln -s -f "/usr/lib/gobject-introspection/giscanner/__pycache__" _build/giscanner/
	ln -s -f /usr/lib/gobject-introspection/giscanner/_giscanner.cpython-*-linux-gnu.so _build/giscanner/
}

run_make() {
	GI_SCANNER_DEBUG=1 \
	CROSS_EXTRA_GISCANNER_CFLAGS="--cflags-begin $(${XMINGW}/cross --cflags) --cflags-end" \
	WINEPATH="$PWD/_build/girepository" \
	${XMINGW}/cross ninja -C _build &&
	CROSS_EXTRA_GISCANNER_CFLAGS="--cflags-begin $(${XMINGW}/cross --cflags) --cflags-end" \
	WINEPATH="$PWD/_build/girepository" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*

	# g-ir-* コマンドは細工したものかホストのものを使用する。
	(cd "${INSTALL_TARGET}/lib/pkgconfig" &&
	sed -i *.pc \
		-e '/^g_ir_/ s/${bindir}\/\|\.exe//g'
	)
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" lib/girepository-1.0/*.typelib &&
	pack_archive "${__DEVZIP}" bin/g-ir-{compiler,generate,inspect,scanner}* include lib/*.a lib/pkgconfig lib/gobject-introspection share/aclocal share/gir-* share/gobject-introspection-* share/man/man1 &&
	pack_archive "${__TOOLSZIP}" bin/g-ir-{annotation,doc,inspection}*  &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
#	put_exclude_files bin/g-ir-* share/man
}



