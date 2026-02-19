#!/bin/bash -e

PATH="/c/Users/$(id -un)/AppData/Local/Microsoft/WindowsApps:$PATH"
mv "C:\Program Files (x86)\Microsoft Visual Studio\Installer\InstallCleanup.exe" .

for sdk in `yes | winget list | grep -i WindowsSDK | cut -d' ' -f7`
do
	[[ $sdk ]] || continue
	printf ":: Uninstalling $sdk..."
	winget uninstall $sdk >/dev/null
	printf "done.\n"
done
rm -rf "C:\Program Files (x86)\Windows Kits"
rm -rf /c/Program\ Files*/Microsoft\ Visual\ Studio
timeout 30 ./InstallCleanup.exe || timeout 90 ./InstallCleanup.exe || true

wget -nv -c https://aka.ms/vs/17/release/vs_enterprise.exe
echo y | winget install --id Microsoft.VisualStudio.2022.Enterprise >log || echo ":: Winget install VS failed"

printf ":: Update VisualStudio installer...\n"
./vs_enterprise.exe --quiet --wait --norestart --installerOnly >log
printf ":: Install VisualStudio from config-file: vsconfig.json...\n"
./vs_enterprise.exe --quiet --wait --norestart --config vsconfig.json >vs.log || true
test -d "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC" || \
./vs_enterprise.exe --quiet --wait --norestart --add Microsoft.VisualStudio.Component.VC.ATLMFC --add Microsoft.VisualStudio.Component.VC.MFC.ARM64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Workload.NativeDesktop

# https://developer.microsoft.com/windows/downloads/windows-sdk
SDKURL="https://download.microsoft.com/download/f4b30f2a-4fc3-430e-9b03-c842b5f5f9f1/26100.7705.260126-1049.ge_release_svc_prod3_WindowsSDK.iso"
echo ":: Download WindowsSDK ISO"
wget -nv -cO WindowsSDK.iso "$SDKURL"
7z x WindowsSDK.iso -oSDK.iso

printf ":: Install WindowsSDK..."
./install_winsdk.cmd
printf "done.\n"
