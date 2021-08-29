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
	MOD=gexiv2
	[ "" = "${VER}" ] && VER=0.12.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
exiv2
glib
EOS
}

optional_dependencies() {
	cat <<EOS
gobject-introspection
python2
python3
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
	if [[ "${VER}" == "0.12.0" ]]
	then
		# Error: invalid new-expression of abstract class type ‘{anonymous}::GioIo’ になっていた。
		patch_adhoc -p 1 <<\EOS
--- gexiv2-0.12.0.orig/gexiv2/gexiv2-metadata.cpp
+++ gexiv2-0.12.0/gexiv2/gexiv2-metadata.cpp
@@ -201,6 +201,10 @@
         return "GIO Wrapper";
     }
 
+    std::wstring wpath() const {
+        return L"GIO Wrapper";
+    }
+
 #if EXIV2_TEST_VERSION(0,27,99)
     Exiv2::BasicIo::UniquePtr temporary() const {
         return Exiv2::BasicIo::UniquePtr(nullptr);
EOS
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Dgtk_doc=false  -Dintrospection=true -Dvapi=true \
		-Dpython2_girdir=no -Dpython3_girdir=no
}

run_make() {
	WINEPATH="${PWD}/_build/gexiv2" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="${PWD}/_build/gexiv2" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/girepository-* share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/gir-* share/vala/vapi/ &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



