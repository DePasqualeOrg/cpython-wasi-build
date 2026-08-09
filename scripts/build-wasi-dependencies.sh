#!/usr/bin/env bash
set -euo pipefail

: "${WASI_SDK_PATH:?Set WASI_SDK_PATH to the installed WASI SDK directory}"

CHECKOUT_ROOT="$(realpath -m "$PWD")"
PREFIX="$(realpath -m "${WASI_DEPENDENCY_PREFIX:-$CHECKOUT_ROOT/.wasi-deps}")"
SYSROOT="$WASI_SDK_PATH/share/wasi-sysroot"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"

CC="$WASI_SDK_PATH/bin/clang --sysroot=$SYSROOT"
AR="$WASI_SDK_PATH/bin/llvm-ar"
RANLIB="$WASI_SDK_PATH/bin/llvm-ranlib"

if [[ "$PREFIX" != "$CHECKOUT_ROOT/"* ]]; then
    printf 'WASI_DEPENDENCY_PREFIX must be an absolute path below the checkout: %s\n' "$PREFIX" >&2
    exit 2
fi

WORK_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

download() {
    local url="$1"
    local destination="$2"
    curl --proto '=https' --tlsv1.2 -fsSLo "$destination" "$url"
}

verify_sha256() {
    local expected="$1"
    local path="$2"
    printf '%s  %s\n' "$expected" "$path" | sha256sum -c -
}

verify_sha512() {
    local expected="$1"
    local path="$2"
    printf '%s  %s\n' "$expected" "$path" | sha512sum -c -
}

verify_sha3_256() {
    local expected="$1"
    local path="$2"
    local actual
    actual="$(openssl dgst -sha3-256 "$path" | sed 's/^.*= //')"
    if [[ "$actual" != "$expected" ]]; then
        printf 'SHA3-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        return 1
    fi
}

rm -rf "$PREFIX"
mkdir -p "$PREFIX/include" "$PREFIX/lib" "$PREFIX/licenses"

ZLIB_VERSION=1.3.2
ZLIB_ARCHIVE="$WORK_DIR/zlib-$ZLIB_VERSION.tar.gz"
download "https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz" "$ZLIB_ARCHIVE"
verify_sha256 bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16 "$ZLIB_ARCHIVE"
tar --no-same-owner -xzf "$ZLIB_ARCHIVE" -C "$WORK_DIR"
(
    cd "$WORK_DIR/zlib-$ZLIB_VERSION"
    CHOST=wasm32-wasi CC="$CC" AR="$AR" RANLIB="$RANLIB" \
        ./configure --static --prefix="$PREFIX"
    make -j"$JOBS"
    make install
)
cp "$WORK_DIR/zlib-$ZLIB_VERSION/LICENSE" "$PREFIX/licenses/zlib.txt"

BZIP2_VERSION=1.0.8
BZIP2_ARCHIVE="$WORK_DIR/bzip2-$BZIP2_VERSION.tar.gz"
download "https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VERSION.tar.gz" "$BZIP2_ARCHIVE"
verify_sha512 083f5e675d73f3233c7930ebe20425a533feedeaaa9d8cc86831312a6581cefbe6ed0d08d2fa89be81082f2a5abdabca8b3c080bf97218a1bd59dc118a30b9f3 "$BZIP2_ARCHIVE"
tar --no-same-owner -xzf "$BZIP2_ARCHIVE" -C "$WORK_DIR"
(
    cd "$WORK_DIR/bzip2-$BZIP2_VERSION"
    make -j"$JOBS" libbz2.a CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS='-O2 -Wall -Winline'
)
cp "$WORK_DIR/bzip2-$BZIP2_VERSION/bzlib.h" "$PREFIX/include/"
cp "$WORK_DIR/bzip2-$BZIP2_VERSION/libbz2.a" "$PREFIX/lib/"
cp "$WORK_DIR/bzip2-$BZIP2_VERSION/LICENSE" "$PREFIX/licenses/bzip2.txt"

XZ_VERSION=5.8.3
XZ_ARCHIVE="$WORK_DIR/xz-$XZ_VERSION.tar.xz"
download "https://github.com/tukaani-project/xz/releases/download/v$XZ_VERSION/xz-$XZ_VERSION.tar.xz" "$XZ_ARCHIVE"
verify_sha256 fff1ffcf2b0da84d308a14de513a1aa23d4e9aa3464d17e64b9714bfdd0bbfb6 "$XZ_ARCHIVE"
tar --no-same-owner -xJf "$XZ_ARCHIVE" -C "$WORK_DIR"
(
    cd "$WORK_DIR/xz-$XZ_VERSION"
    CC="$CC" AR="$AR" RANLIB="$RANLIB" \
        ./configure \
            --host=wasm32-wasi \
            --prefix="$PREFIX" \
            --disable-shared \
            --enable-static \
            --disable-threads \
            --disable-nls \
            --disable-doc \
            --disable-scripts \
            --disable-xz \
            --disable-xzdec \
            --disable-lzmadec \
            --disable-lzmainfo
    make -j"$JOBS" -C src/liblzma install
)
cp "$WORK_DIR/xz-$XZ_VERSION/COPYING" "$PREFIX/licenses/xz.txt"

SQLITE_VERSION=3.53.3
SQLITE_ARCHIVE_NUMBER=3530300
SQLITE_ARCHIVE="$WORK_DIR/sqlite-autoconf-$SQLITE_ARCHIVE_NUMBER.tar.gz"
download "https://sqlite.org/2026/sqlite-autoconf-$SQLITE_ARCHIVE_NUMBER.tar.gz" "$SQLITE_ARCHIVE"
verify_sha3_256 98f2b3f3c11be6a03ea32346937b032c2472ebbd7a716bed36ca2f5693e7ce8b "$SQLITE_ARCHIVE"
tar --no-same-owner -xzf "$SQLITE_ARCHIVE" -C "$WORK_DIR"
"$WASI_SDK_PATH/bin/clang" --sysroot="$SYSROOT" \
    -O2 \
    -DSQLITE_THREADSAFE=0 \
    -DSQLITE_TEMP_STORE=3 \
    -DSQLITE_OMIT_LOAD_EXTENSION \
    -DSQLITE_DQS=0 \
    -c "$WORK_DIR/sqlite-autoconf-$SQLITE_ARCHIVE_NUMBER/sqlite3.c" \
    -o "$WORK_DIR/sqlite3.o"
"$AR" rcs "$PREFIX/lib/libsqlite3.a" "$WORK_DIR/sqlite3.o"
"$RANLIB" "$PREFIX/lib/libsqlite3.a"
cp "$WORK_DIR/sqlite-autoconf-$SQLITE_ARCHIVE_NUMBER/sqlite3.h" "$PREFIX/include/"
cp "$WORK_DIR/sqlite-autoconf-$SQLITE_ARCHIVE_NUMBER/sqlite3ext.h" "$PREFIX/include/"

cat > "$PREFIX/dependency.env" <<EOF
ZLIB_CFLAGS=-I$PREFIX/include
ZLIB_LIBS=$PREFIX/lib/libz.a
BZIP2_CFLAGS=-I$PREFIX/include
BZIP2_LIBS=$PREFIX/lib/libbz2.a
LIBLZMA_CFLAGS=-I$PREFIX/include
LIBLZMA_LIBS=$PREFIX/lib/liblzma.a
LIBSQLITE3_CFLAGS=-I$PREFIX/include
LIBSQLITE3_LIBS=$PREFIX/lib/libsqlite3.a
LDFLAGS=-L$PREFIX/lib
EOF

printf 'Built WASI dependencies in %s\n' "$PREFIX"
