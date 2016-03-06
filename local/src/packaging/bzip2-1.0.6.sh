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
	MOD=bzip2
	[ "" = "${VER}" ] && VER=1.0.6
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/compress"
	__ARCHIVE="${MOD}-${VER}"

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
BZIP2 LICENSE

EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# bzip2.c の sys\stat.h を sys/stat.h に置き換える。
	sed -i.orig -e 's!sys\\stat!sys/stat!' bzip2.c &&
#	# bzlib.h の WINAPI を DECLSPEC_EXPORT に置き換える。
	patch_adhoc -p 0 <<\EOS &&
--- bzlib.h.orig
+++ bzlib.h
@@ -81,12 +81,15 @@
       /* windows.h define small to char */
 #      undef small
 #   endif
+#   ifndef DECLSPEC_EXPORT
+#   define DECLSPEC_EXPORT __declspec(dllexport)
+#   endif
 #   ifdef BZ_EXPORT
-#   define BZ_API(func) WINAPI func
+#   define BZ_API(func) DECLSPEC_EXPORT func
 #   define BZ_EXTERN extern
 #   else
    /* import windows dll dynamically */
-#   define BZ_API(func) (WINAPI * func)
+#   define BZ_API(func) (DECLSPEC_EXPORT * func)
 #   define BZ_EXTERN
 #   endif
 #else
EOS
	# Makefile
	patch_adhoc -p 0 <<\EOS &&
--- Makefile.orig
+++ Makefile
@@ -35,13 +35,15 @@
       decompress.o \
       bzlib.o
 
-all: libbz2.a bzip2 bzip2recover test
+EXEEXT=.exe
 
-bzip2: libbz2.a bzip2.o
-	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2 bzip2.o -L. -lbz2
+all: libbz2.a bzip2$(EXEEXT) bzip2recover$(EXEEXT) # test
 
-bzip2recover: bzip2recover.o
-	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2recover bzip2recover.o
+bzip2$(EXEEXT): libbz2.a bzip2.o
+	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2$(EXEEXT) bzip2.o -L. -lbz2
+
+bzip2recover$(EXEEXT): bzip2recover.o
+	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2recover$(EXEEXT) bzip2recover.o
 
 libbz2.a: $(OBJS)
 	rm -f libbz2.a
@@ -53,7 +55,7 @@
 	fi
 
 check: test
-test: bzip2
+test: bzip2$(EXEEXT)
 	@cat words1
 	./bzip2 -1  < sample1.ref > sample1.rb2
 	./bzip2 -2  < sample2.ref > sample2.rb2
@@ -69,20 +71,20 @@
 	cmp sample3.tst sample3.ref
 	@cat words3
 
-install: bzip2 bzip2recover
+install: bzip2$(EXEEXT) bzip2recover$(EXEEXT)
 	if ( test ! -d $(PREFIX)/bin ) ; then mkdir -p $(PREFIX)/bin ; fi
 	if ( test ! -d $(PREFIX)/lib ) ; then mkdir -p $(PREFIX)/lib ; fi
 	if ( test ! -d $(PREFIX)/man ) ; then mkdir -p $(PREFIX)/man ; fi
 	if ( test ! -d $(PREFIX)/man/man1 ) ; then mkdir -p $(PREFIX)/man/man1 ; fi
 	if ( test ! -d $(PREFIX)/include ) ; then mkdir -p $(PREFIX)/include ; fi
-	cp -f bzip2 $(PREFIX)/bin/bzip2
-	cp -f bzip2 $(PREFIX)/bin/bunzip2
-	cp -f bzip2 $(PREFIX)/bin/bzcat
-	cp -f bzip2recover $(PREFIX)/bin/bzip2recover
-	chmod a+x $(PREFIX)/bin/bzip2
-	chmod a+x $(PREFIX)/bin/bunzip2
-	chmod a+x $(PREFIX)/bin/bzcat
-	chmod a+x $(PREFIX)/bin/bzip2recover
+	cp -f bzip2$(EXEEXT) $(PREFIX)/bin/bzip2$(EXEEXT)
+	cp -f bzip2$(EXEEXT) $(PREFIX)/bin/bunzip2$(EXEEXT)
+	cp -f bzip2$(EXEEXT) $(PREFIX)/bin/bzcat$(EXEEXT)
+	cp -f bzip2recover$(EXEEXT) $(PREFIX)/bin/bzip2recover$(EXEEXT)
+	chmod a+x $(PREFIX)/bin/bzip2$(EXEEXT)
+	chmod a+x $(PREFIX)/bin/bunzip2$(EXEEXT)
+	chmod a+x $(PREFIX)/bin/bzcat$(EXEEXT)
+	chmod a+x $(PREFIX)/bin/bzip2recover$(EXEEXT)
 	cp -f bzip2.1 $(PREFIX)/man/man1
 	chmod a+r $(PREFIX)/man/man1/bzip2.1
 	cp -f bzlib.h $(PREFIX)/include
@@ -109,7 +111,7 @@
 	echo ".so man1/bzdiff.1" > $(PREFIX)/man/man1/bzcmp.1
 
 clean: 
-	rm -f *.o libbz2.a bzip2 bzip2recover \
+	rm -f *.o libbz2.a bzip2$(EXEEXT) bzip2recover$(EXEEXT) \
 	sample1.rb2 sample2.rb2 sample3.rb2 \
 	sample1.tst sample2.tst sample3.tst
 
EOS
	# Makefile-libbz2_so
	patch_adhoc -p 0 <<\EOS
--- Makefile-libbz2_so.orig
+++ Makefile-libbz2_so
@@ -35,8 +35,8 @@
       bzlib.o
 
 all: $(OBJS)
-	$(CC) -shared -Wl,-soname -Wl,libbz2.so.1.0 -o libbz2.so.1.0.6 $(OBJS)
-	$(CC) $(CFLAGS) -o bzip2-shared bzip2.c libbz2.so.1.0.6
+	$(CC) -shared -Wl,--out-implib -Wl,libbz2.dll.a -o bz2-1.dll $(OBJS)
+	$(CC) $(CFLAGS) -o bzip2-shared.exe bzip2.c libbz2.dll.a
 	rm -f libbz2.so.1.0
 	ln -s libbz2.so.1.0.6 libbz2.so.1.0
 
EOS
}

run_make() {
	${XMINGW}/cross make -f Makefile-libbz2_so CFLAGS="`${XMINGW}/cross --archcflags` -O2 -pipe -fomit-frame-pointer -ffast-math '-DDECLSPEC_EXPORT=__declspec(dllexport)' -D_FILE_OFFSET_BITS=64" LDFALGS="-Wl,-s" &&
	${XMINGW}/cross make CFLAGS="`${XMINGW}/cross --archcflags` -O2 -pipe -fomit-frame-pointer -ffast-math '-DDECLSPEC_EXPORT=__declspec(dllexport)' -D_FILE_OFFSET_BITS=64" LDFALGS="-Wl,-s" &&
	${XMINGW}/cross make PREFIX=${INSTALL_TARGET} install
}

pre_pack() {
	cp bz2-1.dll ${INSTALL_TARGET}/bin/.
	cp libbz2.dll.a ${INSTALL_TARGET}/lib/.
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.a &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} bin/bz{cmp,diff,egrep,fgrep,grep,less,more} man &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



