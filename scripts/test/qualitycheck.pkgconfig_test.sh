#! /bin/sh
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

IN_PACKAGE_SCRIPT="#"
. "`dirname $0`/../qualitycheck.pkgconfig"

test_replace() {
local path="/usr/xmingw/xmingw32/local/src/build/8165a865c322c507b4e76db65aee213a"
local s
local e
local a
	s="libdir=${path}/lib"
	e='libdir=${exec_prefix}/lib'
	a=`__qualitycheck_pkgconfig_file_replace "${s}" "${path}" '${exec_prefix}'`
    assertEquals "${e}" "${a}"

	s="Cflags=-I${path}/include -I${path}/include/freetype2"
    e='Cflags=-I${includedir} -I${includedir}/freetype2'
	a=`__qualitycheck_pkgconfig_file_replace "${s}" "${path}/include" '${includedir}'`
    assertEquals "${e}" "${a}"

	s=`dirname ${path}`
    e=${s}
	a=`__qualitycheck_pkgconfig_file_replace "${s}" "${path}" "***"`
    assertEquals "${e}" "${a}"

	# 正規表現が使える場合、望ましくない実装であり、脆弱性につながる。
	s="Cflags=-I${path}/include -I${path}/include/freetype2"
    e="=-//////// -/////////"
	a=`__qualitycheck_pkgconfig_file_replace "${s}" '[a-zA-Z0-9]' ""`
    assertNotEquals "regexp 1-1." "${e}" "${a}"
    assertEquals "regexp 1-2." "${s}" "${a}"

	s="Cflags=-I${path}/include -I${path}/include/freetype2"
    e=${s}
	a=`__qualitycheck_pkgconfig_file_replace "${s}" '/[a-zA-Z0-9]/' ""`
    assertEquals "regexp 2." "${e}" "${a}"

	s="Cflags=-I${path}/include -I${path}/include/freetype2"
    e=${s}
	a=`__qualitycheck_pkgconfig_file_replace "${s}" '" "{print \"***\"}"' ""`
    assertEquals "shell." "${e}" "${a}"
}

test_check() {
local path="/usr/xmingw/xmingw32/local/src/build/8165a865c322c507b4e76db65aee213a"
local s
local e
local a
local d=`dirname $0`
	e="WARNING(qualitycheck.pkgconfig): pkgconfig ファイル ./qualitycheck.pkgconfig_test.a.pc に不具合があります。 libdir, includedir, Libs, Cflags に仮インストール先のアドレスが埋め込まれています( fix コマンドで正規化できます)。 exec_prefix が標準ではない形式で記述されています(望ましくない記述です)。 sharedlibdir に仮インストール先のアドレスが埋め込まれています(影響はないと思われます)。"
	a=`__qualitycheck_pkgconfig_file "${d}/qualitycheck.pkgconfig_test.a.pc" "${path}" 2>&1`
    assertEquals "${e}" "${a}"
}

test_fix() {
local path="/usr/xmingw/xmingw32/local/src/build/8165a865c322c507b4e76db65aee213a"
local s
local e
local a
local d=`dirname $0`
	e='prefix=/usr/xmingw/xmingw32/local/src/build/8165a865c322c507b4e76db65aee213a
exec_prefix=/usr/local
libdir=${exec_prefix}/lib
includedir=${prefix}/include/foo
sharedlibdir=/usr/xmingw/xmingw32/local/src/build/8165a865c322c507b4e76db65aee213a

Name: foo
URL: http://foo.org
Description: A foo.
Version: 17.4.11
Requires:
Requires.private: zlib, harfbuzz >= 0.9.19
Libs: -L${libdir} -lfoo
Libs.private: -lbz2 -L/usr/xmingw/xmingw32/local/libs64/lib/lib -lpng16
Cflags: -I${includedir}'
	a=`__qualitycheck_pkgconfig_file_fix "${d}/qualitycheck.pkgconfig_test.a.pc" "${path}" 2>&1`
    assertEquals "${e}" "${a}"
}

# load shunit2
. "`dirname $0`/shunit2/shunit2"



