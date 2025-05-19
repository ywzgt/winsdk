@echo off

set ISO="SDK.iso\Installers"

"%ISO%\SDK Debuggers-x86_en-us.msi" /quiet /norestart
"%ISO%\Universal CRT Redistributable-x86_en-us.msi" /quiet /norestart
"%ISO%\Universal CRT Headers Libraries and Sources-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK for Windows Store Apps Headers-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK for Windows Store Apps Libs-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK for Windows Store Apps Tools-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK Desktop Headers x86-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK Desktop Libs arm64-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK Desktop Libs x64-x86_en-us.msi" /quiet /norestart
"%ISO%\Windows SDK Desktop Libs x86-x86_en-us.msi" /quiet /norestart
