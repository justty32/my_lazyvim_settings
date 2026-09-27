#!/usr/bin/env bash
# 使用既有 Janet/jpm 相依建置獨立 image，不覆蓋全域 janet-lsp。
set -euo pipefail
config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
revision=e31cd7f78608c2516aa43532888b040c2a5900b1
install_dir=${1:-${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}/janet-lsp-fixed}
for tool in git janet jpm bwrap; do
  command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done
# 缺依賴即停止，交由使用者既有 jpm 環境處理；不暗中更新全域套件。
janet -e '(import judge) (import cmd) (import spork/path) (import spork/rpc)'
build_dir=$(mktemp -d)
trap 'rm -rf -- "$build_dir"' EXIT
git -C "$build_dir" init -q
git -C "$build_dir" remote add origin https://github.com/CFiggers/janet-lsp.git
git -C "$build_dir" fetch -q --depth=1 origin "$revision"
git -C "$build_dir" checkout -q --detach FETCH_HEAD
git -C "$build_dir" apply "$config_dir/patches/janet-lsp-safe-def.patch"
(cd "$build_dir" && janet "$config_dir/tests/janet-lsp-eval.janet" "$build_dir")
(cd "$build_dir" && jpm build)
mkdir -p -- "$install_dir"
install -m 644 "$build_dir/build/janet-lsp.jimage" "$install_dir/janet-lsp.jimage.new"
mv -- "$install_dir/janet-lsp.jimage.new" "$install_dir/janet-lsp.jimage"
printf '%s\n' "$revision + patches/janet-lsp-safe-def.patch" > "$install_dir/source.txt"
echo "Installed: $install_dir/janet-lsp.jimage"
