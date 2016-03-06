#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=libmypaint
	[ "" = "${VER}" ] && VER=git-b89de74
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
json-c
EOS
}

optional_dependencies() {
	cat <<EOS
gegl
EOS
}

license() {
	cat <<EOS
ISC license

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [1.1?git] cross-compile に対応する。
	# [1.1?git] -Werror を設定しているが、使用していない変数があり、エラーにされてしまう。
	# [1.1?git] 最適化オプション -O3 を削る。
	patch_adhoc -p 0 <<\EOS
--- SConstruct.orig
+++ SConstruct
@@ -36,10 +36,12 @@
 opts.Add(BoolVariable('use_glib', 'enable glib (forced on by introspection)', False))
 opts.Add('python_binary', 'python executable to build for', default_python_binary)
 
-tools = ['default', 'textfile']
+tools = ['default', 'textfile', 'mingw']
 
 env = Environment(ENV=os.environ, options=opts, tools=tools)
 
+env['SHLIBSUFFIX'] = '.dll'
+
 Help(opts.GenerateHelpText(env))
 
 # Respect some standard build environment stuff
@@ -58,7 +60,7 @@
 opts.Update(env)
 
 env.Append(CXXFLAGS=' -Wall -Wno-sign-compare -Wno-write-strings')
-env.Append(CCFLAGS='-Wall -Wstrict-prototypes -Werror')
+env.Append(CCFLAGS='-Wall -Wstrict-prototypes')
 env.Append(CFLAGS='-std=c99')
 
 env['GEGL_VERSION'] = 0.3
@@ -73,9 +75,9 @@
 if env['debug']:
     env.Append(CPPDEFINES='HEAVY_DEBUG')
     env.Append(CCFLAGS='-O0', LINKFLAGS='-O0')
-else:
+#else:
     # Overridable defaults
-    env.Prepend(CCFLAGS='-O3', LINKFLAGS='-O3')
+#    env.Prepend(CCFLAGS='-O3', LINKFLAGS='-O3')
 
 if env['enable_profiling'] or env['debug']:
     env.Append(CCFLAGS='-g')
EOS
}

run_make() {
	# scons に設定できる変数一覧は scons -Q -h で表示される。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	${XMINGW}/cross scons prefix="${INSTALL_TARGET}" "${INSTALL_TARGET}" use_sharedlib=yes use_glib=yes enable_gegl=yes
}

pre_pack() {
	mkdir -p "${INSTALL_TARGET}/share/doc/libmypaint" &&
	cp COPYING "${INSTALL_TARGET}/share/doc/libmypaint/." &&
	(cd "${INSTALL_TARGET}" &&
	mkdir -p bin &&
	mv lib/*.dll bin/.
	)
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/locale &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/{doc,libmypaint} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



