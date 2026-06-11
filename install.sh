#!/usr/bin/env bash
#
# visual-web-stack skill 安裝腳本（macOS / Linux）
# 用法：./install.sh [--force]
#   --force  目標已存在時直接覆蓋，不詢問

set -euo pipefail

FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/skill"
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

if [ -d "$DEST_DIR" ]; then
  if [ "$FORCE" -eq 1 ]; then
    echo "偵測到既有安裝（$DEST_DIR），--force 已指定，直接覆蓋。"
  else
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
