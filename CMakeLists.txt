cmake_minimum_required(VERSION 3.14)
project(iodbc_sql_drivers)

include(FetchContent)
include(ExternalProject)

# Workaround from https://github.com/protocolbuffers/protobuf/issues/12185
set(ABSL_ENABLE_INSTALL ON)
# Show progress during the fetching of dependencies
set(FETCHCONTENT_QUIET OFF)
# Eanble encryption for OPC UA
set(UA_LOGLEVEL 200)
set(UA_ENABLE_ENCRYPTION "OPENSSL" CACHE STRING "OPENSSL")
set(gRPC_SSL_PROVIDER "package" CACHE STRING "package")

set(USE_SYSTEM_TZ_DB OFF CACHE BOOL "" FORCE)
set(MANUAL_TZ_DB ON CACHE BOOL "" FORCE)
set(MANUAL_TZ_DB OFF CACHE BOOL "" FORCE)
set(ENABLE_DATE_INSTALL OFF CACHE BOOL "" FORCE)

enable_testing()

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "/opt/iodbc_sql_drivers" CACHE PATH "Install path" FORCE)
endif()

make_directory(${CMAKE_INSTALL_PREFIX})

# ────────── ExternalProject_Add for icu ──────────
ExternalProject_Add(icu
  URL https://github.com/unicode-org/icu/releases/download/release-78.2/icu4c-78.2-sources.tgz
  URL_HASH SHA256=3e99687b5c435d4b209630e2d2ebb79906c984685e78635078b672e03c89df35
  PREFIX ${CMAKE_INSTALL_PREFIX}
  SOURCE_SUBDIR source
  BUILD_IN_SOURCE 1

  CONFIGURE_COMMAND <SOURCE_DIR>/source/configure
    --prefix=${CMAKE_INSTALL_PREFIX}
    --disable-samples
    --disable-tests

  BUILD_COMMAND $(MAKE) -j 2
  INSTALL_COMMAND $(MAKE) install
)


# ────────── ExternalProject_Add for iODBC ──────────
ExternalProject_Add(iodbc
    URL    https://github.com/openlink/iODBC/releases/download/v3.52.16/libiodbc-3.52.16.tar.gz
    URL_HASH          SHA256=3898b32d07961360f6f2cf36db36036b719a230e476469258a80f32243e845fa
	PREFIX ${CMAKE_INSTALL_PREFIX}
    SOURCE_DIR        "${CMAKE_BINARY_DIR}/_deps/iodbc-src"
    BINARY_DIR        "${CMAKE_BINARY_DIR}/_deps/iodbc-build"
	UPDATE_COMMAND ""
    # run Autotools configure from the build directory
    CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_BINARY_DIR}/_deps/iodbc-src/configure" --prefix=${CMAKE_INSTALL_PREFIX} --enable-static --disable-gui --disable-gtktest

    # build in the build directory
    BUILD_COMMAND "${CMAKE_COMMAND}" -E env make VERBOSE=1

    # install into the staging area
    INSTALL_COMMAND "${CMAKE_COMMAND}" -E env make install
)
add_dependencies(iodbc icu)

ExternalProject_Add(curl
  URL                https://curl.se/download/curl-8.15.0.tar.gz
  URL_HASH           SHA256=d85cfc79dc505ff800cb1d321a320183035011fa08cb301356425d86be8fc53c
  PREFIX             ${CMAKE_INSTALL_PREFIX}
  # Tell curl’s CMake where to install into:
  CMAKE_ARGS
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DBUILD_SHARED_LIBS=ON           # or ON, as you prefer
    -DCURL_STATICLIB=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
	-DCURL_DISABLE_LDAP=ON
	-DCURL_USE_NGHTTP2=OFF
	-DCURL_USE_LIBPSL=OFF
  # Avoid rebuilding unless the source changes:
  UPDATE_COMMAND     ""
)

set(MARIADB_INSTALL_CMD
    ${CMAKE_COMMAND}
    --build
    "${CMAKE_BINARY_DIR}/_deps/mariadb_client-build"
    --target
    install
)
string(REPLACE ";" " " MARIADB_INSTALL_CMD_STR "${MARIADB_INSTALL_CMD}")

ExternalProject_Add(
    mariadb_client
    GIT_REPOSITORY  https://github.com/MariaDB/mariadb-connector-c.git
    GIT_TAG v3.4.8
	PREFIX ${CMAKE_INSTALL_PREFIX}
	UPDATE_COMMAND ""
    SOURCE_DIR ${CMAKE_BINARY_DIR}/_deps/mariadb_client-src
    BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/mariadb_client-build
    CMAKE_ARGS -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SERVER=OFF -DWITH_UNIT_TESTS=OFF -DWITH_IODBC=ON -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DINSTALL_LIBDIR=lib -DINSTALL_PLUGINDIR=lib/plugin -DCMAKE_INSTALL_RPATH="\$ORIGIN" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
	INSTALL_COMMAND /bin/sh -c "${MARIADB_INSTALL_CMD_STR} || true"
)
add_dependencies(mariadb_client iodbc curl)

ExternalProject_Add(
	mariadb_odbc
    GIT_REPOSITORY  https://github.com/mariadb-corporation/mariadb-connector-odbc.git
    GIT_TAG 3.2.8
    SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/mariadb-connector-odbc-src"
    BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/mariadb-connector-odbc-build"
	UPDATE_COMMAND ""
    CMAKE_ARGS -DWITH_UNIT_TESTS=OFF -DWITH_IODBC=ON -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DINSTALL_LIBDIR=lib -DINSTALL_PLUGINDIR=lib/plugin -DCMAKE_INSTALL_RPATH="\$ORIGIN" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
    INSTALL_COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}/_deps/mariadb-connector-odbc-build" --target install
    # UPDATE_COMMAND  ""
)
add_dependencies(mariadb_odbc mariadb_client curl iodbc)

ExternalProject_Add(freetds
    GIT_REPOSITORY https://github.com/FreeTDS/freetds.git

    GIT_TAG v1.5.10

    SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/freetds-src"

    BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/freetds-build"

	UPDATE_COMMAND ""

	CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_CURRENT_SOURCE_DIR}/configure-freetds.sh" "${CMAKE_BINARY_DIR}/_deps/freetds-src" "${CMAKE_BINARY_DIR}/_deps/freetds-build" "${CMAKE_INSTALL_PREFIX}"

    # build in the build directory
    BUILD_COMMAND "${CMAKE_COMMAND}" -E env make VERBOSE=1

    # install into the staging area
    INSTALL_COMMAND "${CMAKE_COMMAND}" -E env make install

    # If you need to apply patches, uncomment this line:
)
add_dependencies(freetds iodbc)

ExternalProject_Add(libpq
	URL https://ftp.postgresql.org/pub/source/v18.1/postgresql-18.1.tar.gz
	URL_HASH SHA256=b0f18c2d6973d2aa023cfc77feda787d7bbe9c31a3977d0f04ac29885fb98ec4
	SOURCE_DIR      "${CMAKE_BINARY_DIR}/_deps/libpq-src"
    BINARY_DIR      "${CMAKE_BINARY_DIR}/_deps/libpq-build"
	UPDATE_COMMAND  ""

 	CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_CURRENT_SOURCE_DIR}/configure-libpq.sh" "${CMAKE_BINARY_DIR}/_deps/libpq-src" "${CMAKE_BINARY_DIR}/_deps/libpq-build" "${CMAKE_INSTALL_PREFIX}"
    BUILD_COMMAND "${CMAKE_COMMAND}" -E env make MAKELEVEL=0 VERBOSE=1
    INSTALL_COMMAND "${CMAKE_COMMAND}" -E env bash -c "make install"
)
add_dependencies(libpq iodbc)

ExternalProject_Add(psqlodbc
	GIT_REPOSITORY  https://github.com/postgresql-interfaces/psqlodbc
	GIT_TAG REL-17_00_0007
	SOURCE_DIR      "${CMAKE_BINARY_DIR}/_deps/psqlodbc-src"
    BINARY_DIR      "${CMAKE_BINARY_DIR}/_deps/psqlodbc-build"
	UPDATE_COMMAND  ""

 	CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_CURRENT_SOURCE_DIR}/configure-psqlodbc.sh" "${CMAKE_BINARY_DIR}/_deps/psqlodbc-src" "${CMAKE_BINARY_DIR}/_deps/psqlodbc-build" "${CMAKE_INSTALL_PREFIX}"
    BUILD_COMMAND "${CMAKE_COMMAND}" -E env make VERBOSE=1
    INSTALL_COMMAND "${CMAKE_COMMAND}" -E env make install
)
add_dependencies(psqlodbc iodbc libpq)

ExternalProject_Add(
  sqlite3
  URL https://www.sqlite.org/2025/sqlite-autoconf-3500000.tar.gz
  URL_HASH SHA256=3bc776a5f243897415f3b80fb74db3236501d45194c75c7f69012e4ec0128327
  SOURCE_DIR      "${CMAKE_BINARY_DIR}/_deps/sqlite3-src"
  BINARY_DIR      "${CMAKE_BINARY_DIR}/_deps/sqlite3-build"
  PREFIX		  

  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_CURRENT_SOURCE_DIR}/configure-sqlite3.sh" "${CMAKE_BINARY_DIR}/_deps/sqlite3-src" "${CMAKE_BINARY_DIR}/_deps/sqlite3-build" "${CMAKE_INSTALL_PREFIX}"

  # build in the build directory
  BUILD_COMMAND "${CMAKE_COMMAND}" -E env make VERBOSE=1

  # install into the staging area
  INSTALL_COMMAND "${CMAKE_COMMAND}" -E env make install

)

ExternalProject_Add(sqliteodbc
    URL http://www.ch-werner.de/sqliteodbc/sqliteodbc-0.99991.tar.gz
	URL_HASH SHA256=4d94adb8d3cde1fa94a28aeb0dfcc7be73145bcdfcdf3d5e225434db31dc8a5c

    SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/sqliteodbc-src"

    BINARY_DIR "${CMAKE_BINARY_DIR}/_deps/sqliteodbc-src"

	UPDATE_COMMAND ""

	CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "${CMAKE_CURRENT_SOURCE_DIR}/configure-sqliteodbc.sh" "${CMAKE_BINARY_DIR}/_deps/sqliteodbc-src" "${CMAKE_BINARY_DIR}/_deps/sqliteodbc-build" "${CMAKE_INSTALL_PREFIX}"

    # build in the build directory
    BUILD_COMMAND "${CMAKE_COMMAND}" -E env make VERBOSE=1

    # install into the staging area
	INSTALL_COMMAND "${CMAKE_COMMAND}" -E env make install

)
add_dependencies(sqliteodbc sqlite3)
add_dependencies(sqliteodbc iodbc)


# ------------------------------------------------------------------------------
# 9) ---------------------------------------------------------------------------
#    Create IMPORTED targets for each driver’s shared library, so downstream code can link directly
#
# 9a) iODBC itself (libiodbc.so)
add_library(iodbc_driver_manager INTERFACE)
add_dependencies(iodbc_driver_manager iodbc)
target_include_directories(iodbc_driver_manager
  INTERFACE "${CMAKE_INSTALL_PREFIX}/include"
)
target_link_libraries(iodbc_driver_manager
  INTERFACE "${CMAKE_INSTALL_PREFIX}/lib/libiodbc.so"
)
