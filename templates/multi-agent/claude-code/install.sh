#!/usr/bin/env bash
set -e

echo "========================================"
echo "  多Agent协同框架 - 安装 (Claude Code 版)"
echo "========================================"
echo ""

TARGET="$HOME/.claude/templates/multi-agent"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE="$(dirname "$SCRIPT_DIR")"   # templates/ 目录（共用文件所在）

echo "创建目录: $TARGET"
mkdir -p "$TARGET/prompts"
mkdir -p "$TARGET/presets"

echo "复制角色模板（三版共用）..."
cp "$BASE/prompts/"*.md "$TARGET/prompts/"
cp "$BASE/presets/"*.yaml "$TARGET/presets/"

echo "复制编排器规范（Claude Code 版）..."
cp "$SCRIPT_DIR/orchestrator.md" "$TARGET/prompts/orchestrator.md"

echo "复制编排器入口文件..."
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$BASE/README.md" "$TARGET/README.md"

echo ""
echo "✓ 安装完成！"
echo ""
echo "模板已安装到: $TARGET"
echo ""
echo "使用方法:"
echo "  1. 复制 $TARGET/CLAUDE.md 到你的项目根目录"
echo "  2. 在 Claude Code 中说'帮我开发XXX'即可"
echo ""
echo "========================================"
