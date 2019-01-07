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
  for f in `find "${dir}" -type f -name \*.pc`
  do
    case "`sed "${f}" -ne 's/^prefix\s*=\s*//p' 2>&1`" in
    ${pre})
      # ignore
      ;;
    "")
:      echo "reppc.sh:INFO: ${f} に prefix 行がありません。"
      ;;
    *)
      echo "reppc.sh:INFO: ${f} の prefix 行を置き換えています。"
      sed "${f}" -e "s&^prefix\s*=.*&prefix=${pre}&" > "${f}.rep"
      mv "${f}.rep" "${f}"
      ;;
    esac
  done
done

