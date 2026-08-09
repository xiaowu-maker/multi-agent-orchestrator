#!/usr/bin/env bash
set -e

echo "========================================"
echo "  多Agent协同框架 - 安装"
echo "========================================"
echo ""

TARGET="$HOME/.claude/templates/multi-agent"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "创建目录: $TARGET"
mkdir -p "$TARGET/prompts"
mkdir -p "$TARGET/presets"

echo "复制角色模板..."
cp "$SCRIPT_DIR/prompts/"*.md "$TARGET/prompts/"
cp "$SCRIPT_DIR/presets/"*.yaml "$TARGET/presets/"

echo "复制编排器入口文件..."
cp "$SCRIPT_DIR/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$SCRIPT_DIR/README.md" "$TARGET/README.md"

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
