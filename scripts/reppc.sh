#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

PREFIX=`dirname "$0"`
if [ "" = "${XMINGW}" ]
then
  . "${PREFIX}/scripts/env.sh"
fi

for dir in `find "${XLIBRARY}" -type d -name pkgconfig`
do
  pre=`dirname "${dir}"`
  pre=`dirname "${pre}"`
  for f in `find "${dir}" -type f -name \*.pc`
  do
    if grep 'prefix=.*' "${f}" >/dev/null 2>&1; then
#      echo "try ${f}"
      cat "${f}" | sed -e "s&^prefix=.*&prefix=${pre}&" > "${f}.rep"
      mv "${f}.rep" "${f}"
    fi
  done
done

