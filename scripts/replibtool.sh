#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

__SCRIPT_NAME=`basename "$0"`

__version() {
  echo "0.2"
}
__usage() {
  echo "usage: ${__SCRIPT_NAME} [command...]"
}
__help() {
  __usage
  echo "
command:
  shared          shared ライブラリーのリンク関係の修正を行う.
  static-libgcc   libgcc と libstdc++ を静的リンクする.
  stdcall         __stdcall な関数を適切にエクスポートできない問題を修正する.
  mix             shared と static ライブラリーを混合リンクする.

option:
  -h  --help      show this message.
      --version   print the version.
"
}


lt=libtool
fl="${lt}.orig"
if test ! -e ${fl}
then
  cp "${lt}" "${fl}"
fi

e_default=yes
e_shared=no
e_static_libgcc=no
e_stdcall=no
e_mix=no
e_all=no

while [ 0 -lt $# ]
do
  e_default=no
  case "$1" in
  all)
    e_all=yes
    ;;
  shared)
    e_shared=yes
    ;;
  static-libgcc)
    e_static_libgcc=yes
    ;;
  stdcall)
    e_stdcall=yes
    ;;
  mix)
    e_mix=yes
    ;;
  -h|--help)
    __help
    exit 1;;
  --version)
    __version
    exit 0;;
  -*|--*|*)
    echo "${__SCRIPT_NAME}: unsupported option \`$1'."
    echo "${__SCRIPT_NAME}: try \`${__SCRIPT_NAME} --help' for more information."
    exit 1;;
  esac
  shift
done

if [ "yes" = "${e_default}" ]
then
  e_shared=yes
fi

cp "${fl}" "${lt}"

if [ "yes" = "${e_shared}" -o "yes" = "${e_all}" ]
then
  sed -i -e 's/^allow_undefined_flag="unsupported"/allow_undefined_flag="supported"/' \
		-e 's/^always_export_symbols=no/always_export_symbols=yes/' \
		"${lt}"
fi

if [ "yes" = "${e_static_libgcc}" -o "yes" = "${e_all}" ]
then
  sed -i -e'/^postdeps=/{s/-lstdc[+][+]//}' \
		-e'/^postdeps=/{s/-lgcc_s -lgcc /-lgcc -lgcc_eh /g}' \
		-e'/^archive_cmds=/{s/-nostdlib/-static-libgcc -static-libstdc++/}' \
		-e'/^\s\+\\$CC\s\+-shared/{s/-nostdlib/-static-libgcc -static-libstdc++/}' \
		-e's/^predep_objects=".\+"/predep_objects=""/' \
		-e's/^postdep_objects=".\+"/postdep_objects=""/' \
		"${lt}"
fi

if [ "yes" = "${e_stdcall}" -o "yes" = "${e_all}" ]
then
  sed -i \
		-e '/^global_symbol_pipe=/{' -e 's/0-9\]/0-9@]/' -e '}' \
		-e '/^archive_expsym_cmds=/,/^$/{' -e 's!"$! -Wl,--kill-at;\n	\\$DLLTOOL --kill-at --compat-implib --input-def \\$output_objdir/\\$soname.def --dllname \\$output_objdir/\\$soname --output-lib \\$output_objdir/\\$library_names_spec"!' -e '}' \
		"${lt}"
fi

if [ "yes" = "${e_mix}" -o "yes" = "${e_all}" ]
then
  sed -i -e 's/^\(deplibs_check_method="\).*\?"/\1pass_all"/' \
		"${lt}"
fi



