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
	MOD=gettext
	[ "" = "${VER}" ] && VER=0.18.2
	[ "" = "${REV}" ] && REV=1
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

run_patch() {
local flag
	# 0.19.5.1 では cldr-plurals.exe のビルドでエラーになる。
	if grep gettext-tools/src/Makefile.in -e "cldr-plurals" > /dev/null 2>&1
	then
		if grep gettext-tools/src/Makefile.in -e "cldr_plurals_CPPFLAGS" > /dev/null 2>&1
		then
			: # ignore
		else
			flag="YES"
		fi
	fi
	if [ "${flag}" == "YES" ]
	then
		patch_adhoc -p 1 <<\EOS
--- gettext-0.19.5.1.orig/gettext-tools/src/Makefile.in
+++ gettext-0.19.5.1/gettext-tools/src/Makefile.in
@@ -2110,6 +2110,7 @@
 recode_sr_latin_CPPFLAGS = $(AM_CPPFLAGS) -DINSTALLDIR=\"$(bindir)\"
 hostname_CPPFLAGS = $(AM_CPPFLAGS) -DINSTALLDIR=\"$(pkglibdir)\"
 urlget_CPPFLAGS = $(AM_CPPFLAGS) -DINSTALLDIR=\"$(pkglibdir)\"
+cldr_plurals_CPPFLAGS = $(AM_CPPFLAGS) -DINSTALLDIR=\"$(pkglibdir)\"
 @RELOCATABLE_VIA_LD_TRUE@msgcmp_LDFLAGS = `$(RELOCATABLE_LDFLAGS) $(bindir)`
 @RELOCATABLE_VIA_LD_TRUE@msgfmt_LDFLAGS = `$(RELOCATABLE_LDFLAGS) $(bindir)`
 @RELOCATABLE_VIA_LD_TRUE@msgmerge_LDFLAGS = `$(RELOCATABLE_LDFLAGS) $(bindir)`
@@ -2967,6 +2968,12 @@
 urlget-urlget.obj: urlget.c
 	$(AM_V_CC)$(CC) $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(urlget_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -c -o urlget-urlget.obj `if test -f 'urlget.c'; then $(CYGPATH_W) 'urlget.c'; else $(CYGPATH_W) '$(srcdir)/urlget.c'; fi`
 
+cldr-plurals.o: cldr-plurals.c
+	$(AM_V_CC)$(CC) $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(cldr_plurals_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -c -o cldr-plurals.o `test -f 'cldr-plurals.c' || echo '$(srcdir)/'`cldr-plurals.c
+
+cldr-plurals.obj: cldr-plurals.c
+	$(AM_V_CC)$(CC) $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(cldr_plurals_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -c -o cldr-plurals.obj `if test -f 'cldr-plurals.c'; then $(CYGPATH_W) 'cldr-plurals.c'; else $(CYGPATH_W) '$(srcdir)/cldr-plurals.c'; fi`
+
 xgettext-xgettext.o: xgettext.c
 	$(AM_V_CC)$(CC) $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(xgettext_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -c -o xgettext-xgettext.o `test -f 'xgettext.c' || echo '$(srcdir)/'`xgettext.c
 
EOS
	fi
	# [0.19.8.1] rpl_printf 関数にリンクできない。 gnulib のバグ。
	# printf-posix: Fix mingw build · coreutils/gnulib@68b6ade · GitHub <https://github.com/coreutils/gnulib/commit/68b6adebef05670a312fb92b05e7bd089d2ed43a>
	patch_adhoc -p 1 <<\EOS
--- gettext-0.19.8.1.orig/gettext-tools/gnulib-m4/asm-underscore.m4
+++ gettext-0.19.8.1/gettext-tools/gnulib-m4/asm-underscore.m4
@@ -29,7 +29,7 @@
 EOF
      # Look for the assembly language name in the .s file.
      AC_TRY_COMMAND(${CC-cc} $CFLAGS $CPPFLAGS $gl_c_asm_opt conftest.c) >/dev/null 2>&1
-     if LC_ALL=C grep -E '(^|[^a-zA-Z0-9_])_foo([^a-zA-Z0-9_]|$)' conftest.$gl_asmext >/dev/null; then
+     if LC_ALL=C grep -E '(^|[[^a-zA-Z0-9_]])_foo([[^a-zA-Z0-9_]]|$)' conftest.$gl_asmext >/dev/null; then
        gl_cv_prog_as_underscore=yes
      else
        gl_cv_prog_as_underscore=no
EOS
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	${XMINGW}/cross-configure --disable-static --disable-java --disable-native-java --disable-rpath --disable-openmp --enable-threads=win32 --enable-relocatable --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
#	bash ${XMINGW}/replibtool.sh shared
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
	for subdir in gettext-runtime gettext-runtime/libasprintf gettext-tools
	do
		(
			cd ${subdir} &&
			bash ${XMINGW}/replibtool.sh static-libgcc
		)
	done
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
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
	put_exclude_files share/**/its
}


