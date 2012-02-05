#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

lt=libtool
fl="${lt}.orig"
if test ! -e ${fl}
then
  cp "${lt}" "${fl}"
fi

cat "${fl}" | \
sed -e 's/^allow_undefined_flag="unsupported"/allow_undefined_flag="supported"/' | \
sed -e 's/^always_export_symbols=no/always_export_symbols=yes/' \
> "${lt}"



