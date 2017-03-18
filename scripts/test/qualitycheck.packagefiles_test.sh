#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

IN_PACKAGE_SCRIPT="#"
. "`dirname $0`/../qualitycheck.packagefiles"
. "`dirname $0`/../build_lib.func"

test_dir="`dirname $0`/qualitycheck.packagefiles"


check_pwd() {
local DIR="qualitycheck.packagefiles"
	if [ ! "${DIR}" == "`basename "${PWD}"`" ]
	then
		echo "FAIL(internal): カレント ディレクトリが ${DIR} ではありません。"
		return 1
	fi
	return 0
}

tearDown() {
local DIR="`manifest_dir`"
	pushd "${test_dir}" > /dev/null &&
	check_pwd &&
#	rm "${DIR}"/*
#	rmdir "${DIR}"
	popd > /dev/null
}

__test_manifest_file_make_mft() {
	check_pwd &&
	pack_archive dummyfiles-bin.test bin/*.dll share/doc &&
	pack_archive dummyfiles-dev.test include lib/*.a lib/pkgconfig
}

test_manifest_file() {
local mfts
local list
local e
	pushd "${test_dir}" > /dev/null &&
	__test_manifest_file_make_mft &&
	mfts=`manifest_files` &&
	list="`cat ${mfts} | sort`" &&
	e=`cat <<\EOS
bin/dummypackage.dll
include
include/dummypackage.h
lib/dummypackage.a
lib/dummypackage.dll.a
lib/pkgconfig
lib/pkgconfig/dummypackage.pc
manifest/dummyfiles-bin.test.mft
manifest/dummyfiles-dev.test.mft
share/doc
share/doc/dummypackage
share/doc/dummypackage/license
EOS`
	assertEquals "${e}" "${list}"
	popd > /dev/null
}

__test_exclude_file_make_excludefile() {
	check_pwd &&
	put_exclude_files share/excludefile
}

test_exclude_file() {
local xcfile
local list
local e
	pushd "${test_dir}" > /dev/null &&
	__test_exclude_file_make_excludefile &&
	xcfile=`exclude_file` &&
	list="`cat ${xcfile} | sort`" &&
	e=`cat <<\EOS
lib/dummypackage.la
share/excludefile
EOS`
	assertEquals "${e}" "${list}"
	popd > /dev/null
}

test_noncapture_files() {
local DIR="`manifest_dir`"
local list
local e
	pushd "${test_dir}" > /dev/null &&
	check_pwd &&
	__test_manifest_file_make_mft &&
	__test_exclude_file_make_excludefile &&
	find_noncaptured_files . > /dev/null &&
	list="`cat "${DIR}/${__NONCAPTURED_FILE}"`"
	e=`cat <<\EOS
etc/noncapture
EOS`
	assertEquals "${e}" "${list}"
	popd > /dev/null
}


# load shunit2
. "`dirname $0`/shunit2/shunit2"



