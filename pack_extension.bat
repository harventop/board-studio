 @echo off
setlocal

cd /d "%~dp0"

echo Packaging Board Studio extension...

if exist "board_studio.rbz" del /f /q "board_studio.rbz"
if exist "board_studio_temp.zip" del /f /q "board_studio_temp.zip"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path 'board_studio.rb', 'board_studio' -DestinationPath 'board_studio_temp.zip' -Force"

if exist "board_studio_temp.zip" (
    ren "board_studio_temp.zip" "board_studio.rbz"
    echo.
    echo Successfully created board_studio.rbz!
) else (
    echo.
    echo Error: Failed to create archive.
)

pause

