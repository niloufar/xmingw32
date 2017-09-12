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
	# package に返す変数。
	MOD=glib
	[ "" = "${VER}" ] && VER=2.37.2
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
gettext-runtime
iconv
libffi
libxml2
zlib
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# 2.45.4
	# -Werror=format= に引っかかっていた。
	# また、 g_once_init_enter 関数の使い方がおかしい。実装も変だがまあいい。
	# Threads: GLib Reference Manual <https://developer.gnome.org/glib/stable/glib-Threads.html#g-once-init-enter>
	sed -i.orig \
		-e 's/\(g_debug ("%u undefhandled [^"]\+", \)\(unhandled_\)/\1(unsigned int)\2/' \
		-e 's/static gboolean initialized = FALSE/static gsize initialized = 0/' \
		gio/gwin32appinfo.c
	# 2.45.2
	# msvcrt.dll 未定義の関数を定義済み関数に置き換える。
	# _wstat32i64 関数は msvcr{8,9,10,11}0.dll で実装されている。 msvcrt.dll にはない。
	# _wstati64 関数は msvcrt.dll にある。両関数は時刻型/ファイル長の種類が同じ。
	# _wstati64 関数は _USE_32BIT_TIME_T を定義する。
	# https://msdn.microsoft.com/ja-jp/library/14h5k7ff.aspx
	sed -i.orig -e 's/_wstat32i64/_wstati64/' gio/glocalfile.c
	# 2.45.7
	# GStatBuf の定義の問題で (void*) でキャストしている。
	sed -i.orig -e 's/retval = _wstat (wfilename, buf);/retval = _wstat (wfilename, (void*)buf);/' glib/gstdio.c
	# strerror_r 関数は windows には存在しない。かわりに strerror_s 関数を使用する。
	# strerror_s 関数と strerror_r 関数は引数の並び順が異なることに注意する。
	# strerror_s、_strerror_s、_wcserror_s、__wcserror_s <https://msdn.microsoft.com/ja-jp/library/51sah927.aspx>
	sed -i.orig -e '/#ifdef G_OS_WIN32/,/#endif/ {' \
		-e 's/#endif/\0\n#if !defined(strerror_r) \&\& (defined(_MSC_VER) || defined(_WIN64) || defined(__MINGW32__))\n#ifndef strerror_s\n_CRTIMP errno_t __cdecl strerror_s(char *_Buf,size_t _SizeInBytes,int _ErrNum);\n#endif\n#define strerror_r(e, b, s) strerror_s(b, s, e)\n#endif/' \
		-e '}' glib/gstrfuncs.c
##ifndef strerror_s
#_CRTIMP errno_t __cdecl strerror_s(char *_Buf,size_t _SizeInBytes,int _ErrNum);
##endif
	# [2.52.1] c90 違反。
	if grep configure -e "^PACKAGE_VERSION='2.52.1'" >/dev/null 2>&1
	then
	patch_adhoc -p 1 <<\EOS
--- glib-2.51.1.orig/glib/gfileutils.c
+++ glib-2.51.1/glib/gfileutils.c
@@ -317,6 +317,10 @@
 g_file_test (const gchar *filename,
              GFileTest    test)
 {
+#ifdef G_OS_WIN32
+  int attributes;
+  wchar_t *wfilename = g_utf8_to_utf16 (filename, -1, NULL, NULL, NULL);
+#endif
   g_return_val_if_fail (filename != NULL, FALSE);
 
 #ifdef G_OS_WIN32
@@ -327,8 +331,6 @@
 #  ifndef FILE_ATTRIBUTE_DEVICE
 #    define FILE_ATTRIBUTE_DEVICE 64
 #  endif
-  int attributes;
-  wchar_t *wfilename = g_utf8_to_utf16 (filename, -1, NULL, NULL, NULL);
 
   if (wfilename == NULL)
     return FALSE;
EOS
	fi
	return 0
}

pre_configure() {
	make clean 2>&1 > /dev/null
	# glib 2.37.7 のバグ？
	sed -i.orig -e "s/if test @GLIBC21@ = no; then/if test no = no; then/" glib/libcharset/Makefile.am
	# ubuntu 13.04 では automake のバージョン不一致によりビルドできない。
	# automake >= 1.10 であり 1.11 はサポートされている。
	# ./autogen.sh
	autoreconf --force --install --verbose
	# ビルドに glib-genmarshal が必要なので先に作成する。
	if [ ! -e gobject/_glib-genmarshal -o ! -e gio/_glib-compile-schemas -o ! -e gio/_glib-compile-resources ]
	then
		LIBFFI_CFLAGS="`pkg-config --cflags libffi`" \
		LIBFFI_LIBS="`pkg-config --libs libffi`" \
		./configure -enable-silent-rules --disable-gtk-doc --enable-static --disable-shared &&
		(cd glib; make) &&
		(cd gthread; make) &&
		(cd gmodule; make) &&
		(cd gio/inotify; make) &&
		(cd gio/xdgmime; make) &&
		(cd gobject; make libgobject-2.0.la) &&
		(cd gobject; make glib-genmarshal && mv glib-genmarshal _glib-genmarshal) &&
		# ビルドに glib-compile-schemas が必要なので先に作成する。
		(cd gio; make glib-compile-schemas && mv glib-compile-schemas _glib-compile-schemas) &&
		# ビルドに glib-compile-resources が必要なので先に作成する。
		(cd gio; make glib-compile-resources LIBS=-lffi && cp glib-compile-resources _glib-compile-resources) &&
		make clean 2>&1 > /dev/null
	fi
}

run_configure() {
	# [2.47.5] pcre.h が見つからずエラーになる。 --with-pcre=internal するようにした。
	GLIB_GENMARSHAL="${PWD}/gobject/_glib-genmarshal" \
	GLIB_COMPILE_SCHEMAS="${PWD}/gio/_glib-compile-schemas" \
	GLIB_COMPILE_RESOURCES="${PWD}/gio/_glib-compile-resources" \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-silent-rules --disable-gtk-doc --with-pcre=internal --disable-libelf --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# tests は作らない。
#	sed -i -e 's/^\(SUBDIRS = .\+\) tests /\1 /' Makefile
	# [2.47.6] ソースの変更が充分でないようで、コンパイルエラーになっていた。
	if grep config.h -e 'PACKAGE_VERSION "2.47.6"' >/dev/null 2>&1
	then
		sed -i.orig -e 's/-Werror=implicit-function-declaration//' gio/Makefile
	fi
	# [2.53.1] ヘッダでは #ifndef _WIN64 しているが C ソースは行っていない関数がプロトタイプ未定義エラーになる。
	if grep config.h -e 'PACKAGE_VERSION "2.53.1"' > /dev/null 2>&1
	then
		sed -i.orig -e 's/-Werror=missing-prototypes//' glib/Makefile
	fi
}

pre_make() {
	(cd glib &&
	${XMINGW}/cross make glibconfig.h.win32 &&
	${XMINGW}/cross make glibconfig-stamp &&
	mv glibconfig.h glibconfig.h.autogened &&
	cp glibconfig.h.win32 glibconfig.h) && 
	# gio\tests/dbus-* まわりで面倒なのでビルドしない。
	sed -i.orig -e "s/ tests\$/ #\0/" gio/Makefile
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# 2.41.3 の gio.pc が cflags に gio-win32-2.0 を設定しない。
	if [ -d "${INSTALL_TARGET}/include/gio-win32-2.0" ]
	then
		sed -i -e 's|^Cflags:$|\0 -I${includedir}/gio-win32-2.0|' "${INSTALL_TARGET}/lib/pkgconfig/gio-2.0.pc"
	fi

local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING "${docdir}/." &&

	sed -i -e "s/^\(glib_genmarshal=\)\(glib-genmarshal\)/\1_\2/" "${INSTALL_TARGET}/lib/pkgconfig/glib-2.0.pc" &&
	cp gobject/_glib-genmarshal "${INSTALL_TARGET}/bin/." &&
	cp gio/_glib-compile-schemas "${INSTALL_TARGET}/bin/." &&
	cp gio/_glib-compile-resources "${INSTALL_TARGET}/bin/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/charset.alias share/locale share/doc &&
	pack_archive "${__DEVZIP}" bin/_glib-* include lib/*.{def,a} lib/glib-2.0 lib/gio lib/pkgconfig share/{aclocal,gettext} share/glib-2.0/gettext &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe bin/{gdbus-codegen,glib-gettextize,glib-mkenums} share/bash-completion share/gdb share/glib-2.0/{codegen,gdb,schemas,valgrind} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


