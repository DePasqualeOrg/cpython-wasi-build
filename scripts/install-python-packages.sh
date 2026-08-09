#!/usr/bin/env bash
set -euo pipefail

: "${SITE_PACKAGES:?Set SITE_PACKAGES to the destination site-packages directory}"

WORK_DIR="$(mktemp -d)"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

install_wheel() {
    local filename="$1"
    local url="$2"
    local expected_sha256="$3"
    local path="$WORK_DIR/$filename"

    case "$filename" in
        *-none-any.whl) ;;
        *)
            printf 'Refusing non-universal wheel: %s\n' "$filename" >&2
            return 1
            ;;
    esac

    curl --proto '=https' --tlsv1.2 -fsSLo "$path" "$url"
    printf '%s  %s\n' "$expected_sha256" "$path" | sha256sum -c -
    unzip -q "$path" -d "$SITE_PACKAGES"
}

mkdir -p "$SITE_PACKAGES"

install_wheel \
    tzdata-2026.2-py2.py3-none-any.whl \
    https://files.pythonhosted.org/packages/ce/e4/dccd7f47c4b64213ac01ef921a1337ee6e30e8c6466046018326977efd95/tzdata-2026.2-py2.py3-none-any.whl \
    bbe9af844f658da81a5f95019480da3a89415801f6cc966806612cc7169bffe7

install_wheel \
    packaging-26.2-py3-none-any.whl \
    https://files.pythonhosted.org/packages/df/b2/87e62e8c3e2f4b32e5fe99e0b86d576da1312593b39f47d8ceef365e95ed/packaging-26.2-py3-none-any.whl \
    5fc45236b9446107ff2415ce77c807cee2862cb6fac22b8a73826d0693b0980e

install_wheel \
    python_dateutil-2.9.0.post0-py2.py3-none-any.whl \
    https://files.pythonhosted.org/packages/ec/57/56b9bcc3c9c6a792fcbaf139543cee77261f3651ca9da0c93f5c1221264b/python_dateutil-2.9.0.post0-py2.py3-none-any.whl \
    a8b2bc7bffae282281c8140a97d3aa9c14da0b136dfe83f850eea9a5f7470427

install_wheel \
    six-1.17.0-py2.py3-none-any.whl \
    https://files.pythonhosted.org/packages/b7/ce/149a00dd41f10bc29e5921b496af8b574d8413afcd5e30dfa0ed46c2cc5e/six-1.17.0-py2.py3-none-any.whl \
    4721f391ed90541fddacab5acf947aa0d3dc7d27b2e1e8eda2be8970586c3274

printf 'Installed verified universal wheels in %s\n' "$SITE_PACKAGES"
