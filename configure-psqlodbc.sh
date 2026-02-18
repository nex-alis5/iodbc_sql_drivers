#!/bin/bash
src_dir="$1"
build_dir="$2"
install_dir="$3"
set -e
cd "$build_dir"
if [ -f "Makefile" ]; then
  make distclean
fi
export PKG_CONFIG_PATH="$install_dir/lib/pkgconfig"
cd "$src_dir"
env CFLAGS="-fPIC" LDFLAGS="-L${install_dir}/lib -Wl,-rpath,'\$\$ORIGIN'" CPPFLAGS="-I${install_dir}/include" ./bootstrap
cd "$build_dir"
env CFLAGS="-fPIC" LDFLAGS="-L${install_dir}/lib -Wl,-rpath,'\$\$ORIGIN'" CPPFLAGS="-I${install_dir}/include" "${src_dir}/configure" --disable-static --with-libpq=$install_dir --with-iodbc=$install_dir --prefix="$install_dir"
