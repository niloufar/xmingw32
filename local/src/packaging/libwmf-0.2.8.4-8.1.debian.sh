#!/use/bin/bash
if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func

#XLIBRARY_SET=${XLIBRARY}/gimp_build_set


MOD=libwmf
VER=0.2.8.4
REV=8.1.debian
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
ARCHIVE="${MOD}-${VER} ${MOD}_${VER}.orig"
DIRECTORY="${MOD}-${VER}"
LIBNAME="libwmf"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}" &&
	(cd ${DIRECTORY} &&
	 expand_archive "${ARCHIVEDIR}/`echo \"${name}\" | sed -e 's/\.orig.\+$//'`-${REV}.tar.gz" &&
	 for p in debian/patches/*.patch; do patch -p 1 -i $p; done
	 )
}

pre_configure() {
	# configure が -lpng 決め打ちで依存チェックしているのでごまかす。
	mkdir -p libpng &&
	ln -f -s ${XLIBRARY}/lib/include/libpng16 libpng/include &&
	mkdir -p libpng/lib &&
	ln -f -s ${XLIBRARY}/lib/lib/libpng16.dll.a libpng/lib/libpng.dll.a &&
	patch -p 1 <<\EOF
--- libwmf-0.2.8.4.orig/src/ipa/ipa/bmp.h
+++ libwmf-0.2.8.4/src/ipa/ipa/bmp.h
@@ -66,7 +66,7 @@
 		return;
 	}
 
-	if (setjmp (png_ptr->jmpbuf))
+	if (png_jmpbuf (png_ptr))
 	{	WMF_DEBUG (API,"Failed to write bitmap as PNG! (setjmp failed)");
 		png_destroy_write_struct (&png_ptr,&info_ptr);
 		wmf_free (API,buffer);
EOF
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --with-libxml2 --without-expat --with-png=${PWD}/libpng --without-x --without-sys-gd --disable-gd --prefix="${INSTALL_TARGET}"
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
local NAME="${INSTALL_TARGET}/bin/${LIBNAME}-config"
	sed -i -e "s#^\s*\(prefix=\).*${INSTALL_TARGET}\$#\1\`dirname \$0\`/..#" "${NAME}"
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll share/libwmf `find lib -name \*.dll` &&
	pack_archive "${DEVZIP}" bin/libwmf-config include `find lib -name \*.a` &&
	pack_archive "${TOOLSZIP}" bin/*.{exe,manifest,local} bin/libwmf-fontmap &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} freetype2 libjpeg libpng libxml2 zlib`

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

