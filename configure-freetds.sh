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
env CFLAGS="-fPIC" LDFLAGS="-L${install_dir}/lib -Wl,-rpath,'\$\$ORIGIN'" CPPFLAGS="-I${install_dir}/include" "${src_dir}/autogen.sh" --prefix="$install_dir" --enable-krb5 --with-iodbc="$install_dir"
