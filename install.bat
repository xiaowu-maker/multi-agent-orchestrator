@echo off
chcp 65001 >nul
echo ========================================
echo   多Agent协同框架 - Windows 安装
echo ========================================
echo.

set TARGET=%USERPROFILE%\.claude\templates\multi-agent

echo 创建目录: %TARGET%
mkdir "%TARGET%\prompts" 2>nul
mkdir "%TARGET%\presets" 2>nul

echo 复制模板文件...
copy /Y "%~dp0templates\multi-agent\prompts\*.md" "%TARGET%\prompts\" >nul
copy /Y "%~dp0templates\multi-agent\presets\*.yaml" "%TARGET%\presets\" >nul

echo.
echo ✓ 安装完成！
echo.
echo 模板已安装到: %TARGET%
echo.
echo 使用方法:
echo   1. 在你的项目根目录创建 CLAUDE.md
echo   2. 复制下面的内容到 CLAUDE.md 中
echo   3. 在 Claude Code 中说"帮我开发XXX"即可
echo.
echo 详细说明请查看 README.md
echo ========================================
pause
