#!/bin/bash
src_dir="$1"
build_dir="$2"
install_dir="$3"
set -ex
cd "$build_dir"
if [ -f "Makefile" ]; then
  make distclean
fi
cd "$build_dir"
export PKG_CONFIG_PATH="$install_dir/lib/pkgconfig"
env CFLAGS="-fPIC" LDFLAGS="-L${install_dir}/lib -Wl,-rpath,\$\$ORIGIN" CPPFLAGS="-I${install_dir}/include" "${src_dir}/configure" --prefix="$install_dir" --without-readline
