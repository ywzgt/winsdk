#!/bin/bash -ex

PATH="$PATH:/c/Users/$(id -un)/AppData/Local/Microsoft/WindowsApps"
#"C:\Program Files (x86)\Microsoft Visual Studio\Installer\InstallCleanup.exe"

#for sdk in `yes | winget list | grep -i WindowsSDK | cut -d' ' -f7`
#do
#	[[ $sdk ]] || continue
#	winget uninstall $sdk
#done
#rm -rf "C:\Program Files (x86)\Windows Kits\10"

yes | winget install --id Microsoft.VisualStudio.2022.Community --verbose --override "--passive --config $PWD/vsconfig.json"
