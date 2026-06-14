[Setup]
AppName=덜어냄
AppVersion=0.4.0-alpha
AppPublisher=ScopeWorks
DefaultDirName={autopf}\ScopeWorks\DeoReoNem
DefaultGroupName=ScopeWorks\DeoReoNem
OutputDir=..\..\dist
OutputBaseFilename=DeoReoNem-0.4-alpha-setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest

[Files]
Source: "..\..\apps\deoreonem_desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\덜어냄"; Filename: "{app}\deoreonem_desktop.exe"
Name: "{group}\덜어냄 (작은 자리)"; Filename: "{app}\deoreonem_desktop.exe"; Parameters: "--garden"
Name: "{commondesktop}\덜어냄"; Filename: "{app}\deoreonem_desktop.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "바탕화면에 바로가기 만들기"; GroupDescription: "추가 아이콘:"

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
