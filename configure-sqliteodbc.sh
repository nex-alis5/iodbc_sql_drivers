#!/bin/bash
src_dir="$1"
build_dir="$2"
install_dir="$3"
set -e
cd "${src_dir}"
if [ -f "Makefile" ]; then
  make distclean
fi
export PKG_CONFIG_PATH="$install_dir/lib/pkgconfig"

CFLAGS="-I${install_dir}/include" LDFLAGS="-L${install_dir}/lib -Wl,-rpath,'\$\$ORIGIN'" CPPFLAGS="-I${install_dir}/include" "${src_dir}/configure" --with-odbc="${install_dir}" --with-sqlite="${install_dir}" --with-sqlite3="${install_dir}" --prefix="${install_dir}"
