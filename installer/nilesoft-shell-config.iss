; ============================================================================
;  Nilesoft Shell Config - Inno Setup project
;  Builds a single setup .exe that installs this config into an existing
;  Nilesoft Shell installation and reloads the right-click menu.
;
;  Build:  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" nilesoft-shell-config.iss
;  Output: Output\nilesoft-shell-config-setup.exe
; ============================================================================

#define MyAppName      "Nilesoft Shell Config"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "Abdullah Masood"
#define MyAppURL       "https://github.com/Abdullah-Masood-05/nilesoft-shell-config"

[Setup]
AppId={{B4E7B7C2-9A3D-4F2E-8C1A-2D5E9F0A1B23}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={code:GetDefaultDir}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=Output
OutputBaseFilename=nilesoft-shell-config-setup
SetupIconFile=app.ico
UninstallDisplayIcon={app}\shell.exe
UninstallDisplayName={#MyAppName}
WizardStyle=modern
Compression=lzma2
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\shell.nss";       DestDir: "{app}";          Flags: ignoreversion uninsneveruninstall
Source: "..\imports\*.nss";   DestDir: "{app}\imports";  Flags: ignoreversion uninsneveruninstall

[Run]
Filename: "{app}\shell.exe"; Parameters: "-register"; Flags: runhidden waituntilterminated; StatusMsg: "Registering shell extension..."
Filename: "{app}\shell.exe"; Parameters: "-restart";  Flags: runhidden waituntilterminated; StatusMsg: "Reloading the menu..."

[UninstallRun]
Filename: "{app}\shell.exe"; Parameters: "-restart"; Flags: runhidden waituntilterminated; RunOnceId: "ReloadShell"

[Code]
function NilesoftDir(): String;
var
  loc: String;
begin
  Result := '';
  if FileExists(ExpandConstant('{commonpf}\Nilesoft Shell\shell.exe')) then
    Result := ExpandConstant('{commonpf}\Nilesoft Shell')
  else if FileExists(ExpandConstant('{commonpf32}\Nilesoft Shell\shell.exe')) then
    Result := ExpandConstant('{commonpf32}\Nilesoft Shell')
  else if RegQueryStringValue(HKLM,
            'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Nilesoft Shell',
            'InstallLocation', loc) and (loc <> '') then
    Result := RemoveBackslash(loc);
end;

function GetDefaultDir(Param: String): String;
begin
  Result := NilesoftDir();
  if Result = '' then
    Result := ExpandConstant('{commonpf}\Nilesoft Shell');
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if NilesoftDir() = '' then
  begin
    MsgBox('Nilesoft Shell was not found on this PC.'#13#10#13#10
      + 'Please install it first and run this setup again:'#13#10
      + '    winget install --id Nilesoft.Shell -e'#13#10#13#10
      + 'or download it from https://nilesoft.org',
      mbCriticalError, MB_OK);
    Result := False;
  end;
end;

// Back up the existing config (shell.nss + imports\*.nss) before overwriting.
procedure BackupExisting();
var
  backupDir, importsSrc: String;
  fr: TFindRec;
begin
  backupDir := ExpandConstant('{app}\config-backup-')
             + GetDateTimeString('yyyymmdd-hhnnss', #0, #0);
  ForceDirectories(backupDir + '\imports');

  if FileExists(ExpandConstant('{app}\shell.nss')) then
    CopyFile(ExpandConstant('{app}\shell.nss'), backupDir + '\shell.nss', False);

  importsSrc := ExpandConstant('{app}\imports');
  if FindFirst(importsSrc + '\*.nss', fr) then
  begin
    try
      repeat
        CopyFile(importsSrc + '\' + fr.Name, backupDir + '\imports\' + fr.Name, False);
      until not FindNext(fr);
    finally
      FindClose(fr);
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    BackupExisting();
end;
