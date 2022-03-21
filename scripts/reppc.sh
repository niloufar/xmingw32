#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

PREFIX=`dirname "$0"`
if [ "" = "${XMINGW}" ]
then
  echo "WARNING: XMINGW 環境のそとで実行しています。 env.sh の既定の環境で実行します。"
  . "${PREFIX}/scripts/env.sh" ""
fi

for dir in `find "${XLIBRARY}" -type d -name pkgconfig`
do
  pre="`dirname "${dir}"`"
  pre="`dirname "${pre}"`"
  for pc_file in `find "${dir}" -type f -name \*.pc`
  do
    imp_prefix="$(sed "${pc_file}" -ne '/^prefix\s*=\s*/ {' \
    	-e 's/^[^=]\+=\s*//p' -e 'q' -e '}' 2>&1)"
    case "${imp_prefix}" in
    ${pre})
      # ignore
      ;;
    "")
:      echo "reppc.sh:INFO: ${pc_file} に prefix 行がありません。"
      ;;
    *)
      echo "reppc.sh:INFO: ${pc_file} の prefix 行を置き換えています。"
      sed "${pc_file}" -e "s&^prefix\s*=.*&prefix=${pre}&" > "${pc_file}.rep"
      mv "${pc_file}.rep" "${pc_file}"
      ;;
    esac
  done
done

