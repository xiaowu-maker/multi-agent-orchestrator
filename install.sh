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

echo "复制模板文件..."
cp "$SCRIPT_DIR/templates/multi-agent/prompts/"*.md "$TARGET/prompts/"
cp "$SCRIPT_DIR/templates/multi-agent/presets/"*.yaml "$TARGET/presets/"

echo ""
echo "✓ 安装完成！"
echo ""
echo "模板已安装到: $TARGET"
echo ""
echo "使用方法:"
echo "  1. 在你的项目根目录创建 CLAUDE.md"
echo "  2. 参考 README.md 中的 CLAUDE.md 模板"
echo "  3. 在 Claude Code 中说'帮我开发XXX'即可"
echo ""
echo "========================================"
