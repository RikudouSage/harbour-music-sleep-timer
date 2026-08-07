#!/bin/sh
set -eu

repo="RikudouSage/MusicSleepTimerDaemon"
out=""
arch=""
build_dir=""

usage() {
    echo "Usage: $0 --output DIR [--arch ARCH] [--build-dir DIR]" >&2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --output)
            [ "$#" -ge 2 ] || { usage; exit 2; }
            out=$2
            shift 2
            ;;
        --arch)
            [ "$#" -ge 2 ] || { usage; exit 2; }
            arch=$2
            shift 2
            ;;
        --build-dir)
            [ "$#" -ge 2 ] || { usage; exit 2; }
            build_dir=$2
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

[ -n "$out" ] || { usage; exit 2; }

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Required command not found: $1" >&2
        exit 1
    fi
}

require_command curl

detect_arch_from_text() {
    printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]' | sed -n \
        -e 's/.*\(armv7hl\).*/\1/p' \
        -e 's/.*\(armv7l\).*/armv7hl/p' \
        -e 's/.*\(armv7\).*/armv7hl/p' \
        -e 's/^\(arm\)$/armv7hl/p' \
        -e 's/.*\(aarch64\).*/\1/p' \
        -e 's/.*\(arm64\).*/aarch64/p' \
        -e 's/.*\(i486\).*/\1/p' \
        -e 's/.*\(i386\).*/i486/p' \
        -e 's/.*\(i586\).*/i486/p' \
        -e 's/.*\(i686\).*/i486/p' \
        -e 's/.*\(x86_64\).*/\1/p' \
        -e 's/.*\(amd64\).*/x86_64/p' |
        sed -n '1p'
}

normalize_arch() {
    case "$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')" in
        arm|armv7|armv7l|armv7hl)
            printf '%s\n' armv7hl
            ;;
        arm64|aarch64)
            printf '%s\n' aarch64
            ;;
        i386|i486|i586|i686)
            printf '%s\n' i486
            ;;
        amd64|x86_64)
            printf '%s\n' x86_64
            ;;
        *)
            printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]'
            ;;
    esac
}

if [ -z "$arch" ] || [ "$arch" = "auto" ]; then
    for candidate in "${RPM_ARCH:-}" "${MERSDK_ARCH:-}" "${MER_BUILD_ARCH:-}" "$build_dir" "$(pwd)"; do
        arch=$(detect_arch_from_text "$candidate")
        [ -z "$arch" ] || break
    done
fi

arch=$(normalize_arch "$arch")

matches_arch() {
    name=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')

    case "$name" in
        *noarch*.rpm)
            return 0
            ;;
    esac

    case "$arch" in
        armv7hl)
            case "$name" in *armv7hl*.rpm|*armv7*.rpm) return 0 ;; esac
            ;;
        aarch64)
            case "$name" in *aarch64*.rpm|*arm64*.rpm) return 0 ;; esac
            ;;
        i486)
            case "$name" in *i486*.rpm|*i586*.rpm|*i686*.rpm) return 0 ;; esac
            ;;
        x86_64)
            case "$name" in *x86_64*.rpm|*amd64*.rpm) return 0 ;; esac
            ;;
    esac

    return 1
}

mkdir -p "$out"
rm -f "$out"/harbour*.rpm "$out"/harbour*.rpm.tmp

assets=$(
    curl -fsSL \
        -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: harbour-music-sleep-timer-build' \
        "https://api.github.com/repos/$repo/releases/latest" |
        awk '
            {
                line = $0
                while (match(line, /"browser_download_url"[[:space:]]*:[[:space:]]*"https:[^"]*\/harbour[^"\/]*\.rpm"/)) {
                    value = substr(line, RSTART, RLENGTH)
                    sub(/^"browser_download_url"[[:space:]]*:[[:space:]]*"/, "", value)
                    sub(/"$/, "", value)
                    print value
                    line = substr(line, RSTART + RLENGTH)
                }
            }
        '
)

if [ -z "$assets" ]; then
    echo "No harbour RPM assets found in latest $repo release" >&2
    exit 1
fi

selected=$(printf '%s\n' "$assets" | while IFS= read -r url; do
    [ -n "$url" ] || continue
    name=${url##*/}

    if [ -z "$arch" ] || [ "$arch" = "all" ] || matches_arch "$name"; then
        printf '%s\n' "$url"
    fi
done)

if [ -z "$selected" ] && [ -n "$arch" ] && [ "$arch" != "all" ]; then
    echo "No harbour RPM assets matched architecture '$arch'" >&2
    echo "Pass DAEMON_RPM_ARCH=all to qmake if you really want to bundle every harbour RPM asset." >&2
    exit 1
fi

printf '%s\n' "$selected" | while IFS= read -r url; do
    [ -n "$url" ] || continue
    name=${url##*/}

    tmp="$out/$name.tmp"
    final="$out/$name"

    echo "Downloading $name"
    curl -fsSL --retry 3 --retry-delay 2 -o "$tmp" "$url"
    mv "$tmp" "$final"
done

if ! ls "$out"/harbour*.rpm >/dev/null 2>&1; then
    echo "No harbour RPM assets were downloaded" >&2
    exit 1
fi

if [ -n "$arch" ]; then
    echo "Bundled harbour RPM assets for architecture preference: $arch"
else
    echo "Bundled all harbour RPM assets; target architecture could not be inferred"
fi
