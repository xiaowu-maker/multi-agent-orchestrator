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

echo 复制角色模板...
copy /Y "%~dp0prompts\*.md" "%TARGET%\prompts\" >nul
copy /Y "%~dp0presets\*.yaml" "%TARGET%\presets\" >nul

echo 复制编排器入口文件...
copy /Y "%~dp0CLAUDE.md" "%TARGET%\CLAUDE.md" >nul
copy /Y "%~dp0README.md" "%TARGET%\README.md" >nul

echo.
echo ✓ 安装完成！
echo.
echo 模板已安装到: %TARGET%
echo.
echo 使用方法:
echo   1. 复制 "%TARGET%\CLAUDE.md" 到你的项目根目录
echo   2. 在 Claude Code 中说"帮我开发XXX"即可
echo.
echo 详细说明请查看 README.md
echo ========================================
pause
