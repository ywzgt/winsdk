@echo off
cd /d %~dp0

for /f "delims=" %%i in ('dir /b "%ProgramFiles(x86)%\Windows Kits\10\Redist"') do set winver=%%i
for /f "usebackq tokens=*" %%i in (`"%programfiles(x86)%\microsoft visual studio\installer\vswhere.exe" -version [17.0^,18.0^) -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property catalog_productDisplayVersion`) do set vs_ver=%%i

echo %vs_ver% > vs_version
echo %winver% > win_version
echo ::Visual Studio (%vs_ver%)
set path=%~dp0\bin;%path%

:: Unnecessary files
rd /s/q "%ProgramFiles(x86)%\Windows Kits\10\Tools"
rd /s/q "%ProgramFiles(x86)%\Windows Kits\10\Include\%winver%\km"
rd /s/q "%ProgramFiles(x86)%\Windows Kits\10\Lib\%winver%\km"
python3 package_from_installed.py -w %winver% 2022
