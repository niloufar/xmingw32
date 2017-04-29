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
  pre=`dirname "${dir}"`
  pre=`dirname "${pre}"`
  for f in `find "${dir}" -type f -name \*.pc`
  do
    if grep '^prefix\s*=.*' "${f}" >/dev/null 2>&1; then
#      echo "try ${f}"
      cat "${f}" | sed -e "s&^prefix\s*=.*&prefix=${pre}&" > "${f}.rep"
      mv "${f}.rep" "${f}"
    fi
  done
done

