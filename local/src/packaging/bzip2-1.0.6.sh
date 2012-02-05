#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=bzip2
VER=1.0.6
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/compress"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	# bzip2.c の sys\stat.h を sys/stat.h に置き換える。
	sed -i.orig -e 's!sys\\stat!sys/stat!' bzip2.c &&
	# bzlib.h の WINAPI を DECLSPEC_EXPORT に置き換える。
	sed -i.orig -e 's/WINAPI/DECLSPEC_EXPORT/' bzlib.h &&
	# Makefile
	patch -p 0 <<\EOS &&
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
	patch -p 0 <<\EOS
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

run_configure() {
	echo skip > /dev/null
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make -f Makefile-libbz2_so CFLAGS="-O2 -mtune=pentium4 -msse -mno-sse2 -pipe -fomit-frame-pointer -ffast-math -D_FILE_OFFSET_BITS=64" LDFALGS="-Wl,-s" &&
	${XMINGW}/cross make CFLAGS="-O2 -mtune=pentium4 -msse -mno-sse2 -pipe -fomit-frame-pointer -ffast-math -D_FILE_OFFSET_BITS=64" LDFALGS="-Wl,-s" &&
	${XMINGW}/cross make PREFIX=${INSTALL_TARGET} install
}

pre_pack() {
	cp bz2-1.dll ${INSTALL_TARGET}/bin/.
	cp libbz2.dll.a ${INSTALL_TARGET}/lib/.
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.a &&
	pack_archive "${TOOLSZIP}" bin/*.{exe,manifest,local} bin/bz{cmp,diff,egrep,fgrep,grep,less,more} man &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

run_expand_archive &&
cd "${DIRECTORY}" &&
pre_configure &&
run_configure &&
post_configure &&

pre_make &&
run_make &&

pre_pack &&
run_pack_archive &&

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.

