#!/usr/bin/env bash
#
# visual-web-stack skill 安裝腳本（macOS / Linux）
# 用法：./install.sh [--force]（也可 sh install.sh，全腳本為 POSIX 相容）
#   --force  目標已存在時直接覆蓋，不詢問

# 不用 pipefail：本腳本無管線，且 pipefail 非 POSIX（dash 的 sh 會直接報錯）
set -eu

FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/skills/visual-web-stack"
SKILLS_DIR="$HOME/.claude/skills"
DEST_DIR="$SKILLS_DIR/visual-web-stack"

if [ ! -f "$SRC_DIR/SKILL.md" ]; then
  echo "錯誤：找不到 $SRC_DIR/SKILL.md，請在 repo 根目錄執行本腳本。" >&2
  exit 1
fi

if [ ! -d "$HOME/.claude" ]; then
  echo "錯誤：找不到 ~/.claude/，請先安裝並執行過 Claude Code。" >&2
  exit 1
fi

mkdir -p "$SKILLS_DIR"

# -e 抓不到 dangling symlink，要多檢查 -L（否則殘留的壞連結會讓後面 mkdir 失敗）
if [ -e "$DEST_DIR" ] || [ -L "$DEST_DIR" ]; then
  if [ "$FORCE" -eq 1 ]; then
    echo "偵測到既有安裝（$DEST_DIR），--force 已指定，直接覆蓋。"
  else
    if [ ! -t 0 ]; then
      echo "錯誤：$DEST_DIR 已存在，且目前為非互動環境無法詢問，請改用 --force 覆蓋。" >&2
      exit 1
    fi
    printf '%s 已存在，要覆蓋嗎？ [y/N] ' "$DEST_DIR"
    read -r answer
    case "$answer" in
      y | Y | yes | YES) ;;
      *)
        echo "已取消安裝。"
        exit 0
        ;;
    esac
  fi
  # 路徑刻意不加結尾斜線：若 DEST 是 symlink，只移除連結本身、不動連結目標
  rm -rf "$DEST_DIR"
fi

mkdir -p "$DEST_DIR"
cp -R "$SRC_DIR/." "$DEST_DIR/"

echo ""
echo "✅ 已安裝到 $DEST_DIR"
echo ""
echo "驗證安裝："
echo "  head -5 ~/.claude/skills/visual-web-stack/SKILL.md"
echo ""
echo "建議在使用本技術棧的專案 CLAUDE.md 加入："
echo "  本專案前端技術棧遵循 visual-web-stack skill，跨套件整合規範以該 skill 鐵則為準。"
