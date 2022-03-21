@echo off
set PATH=%PATH%;%MINGW_W64_GCC_RT_PATH%;%XMINGW_BIN_PATH%
echo cross-wine.bat: INFO: ARGS: %*>>&2
%*
