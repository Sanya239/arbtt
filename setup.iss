#ifndef MyAppVersion
  #define MyAppVersion "0.12.0.3"
#endif

#ifndef SourceDir
  #define SourceDir "dist\windows"
#endif

#ifndef OutputDir
  #define OutputDir "dist\installer"
#endif

[Setup]
AppId={{1DB6EA4F-D387-432D-A739-283E0E916AF6}
AppName=arbtt
AppVerName=arbtt {#MyAppVersion}
AppVersion={#MyAppVersion}
AppPublisher=Joachim Breitner and contributors
AppPublisherURL=https://arbtt.nomeata.de/
AppSupportURL=https://github.com/nomeata/arbtt/issues
AppUpdatesURL=https://github.com/nomeata/arbtt/releases
AppReadmeFile={app}\README.Win32.txt
DefaultDirName={localappdata}\Programs\arbtt
DefaultGroupName=arbtt
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
AllowNoIcons=yes
ChangesEnvironment=yes
CloseApplications=yes
CloseApplicationsFilter=arbtt-capture.exe
RestartApplications=no
Compression=lzma2/max
SolidCompression=yes
OutputDir={#OutputDir}
OutputBaseFilename=arbtt-setup-{#MyAppVersion}-windows-x86_64
SetupLogging=yes
UninstallDisplayIcon={app}\bin\arbtt-capture.exe
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany=arbtt contributors
VersionInfoDescription=Automatic Rule-Based Time Tracker
VersionInfoProductName=arbtt
VersionInfoProductVersion={#MyAppVersion}
WizardStyle=modern

[Tasks]
Name: "modifypath"; Description: "Add arbtt to my PATH"; GroupDescription: "Command-line integration:"
Name: "autorun"; Description: "Start arbtt-capture when I sign in"; GroupDescription: "Automatic capture:"
Name: "runcapture"; Description: "Start arbtt-capture after installation"; GroupDescription: "Automatic capture:"

[Files]
Source: "{#SourceDir}\bin\arbtt-capture.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\bin\arbtt-stats.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\bin\arbtt-dump.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\bin\arbtt-import.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\bin\arbtt-recover.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\bin\libpcre-1.dll"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "{#SourceDir}\categorize.cfg"; DestDir: "{userappdata}\arbtt"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "{#SourceDir}\README.Win32.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\THIRD-PARTY-LICENSES\PCRE.txt"; DestDir: "{app}\THIRD-PARTY-LICENSES"; Flags: ignoreversion

[Icons]
Name: "{group}\Edit categorization rules"; Filename: "{sys}\notepad.exe"; Parameters: """{userappdata}\arbtt\categorize.cfg"""
Name: "{group}\User guide"; Filename: "https://arbtt.nomeata.de/doc/users_guide/"; Flags: shellexec
Name: "{group}\Uninstall arbtt"; Filename: "{uninstallexe}"
Name: "{userstartup}\arbtt-capture"; Filename: "{app}\bin\arbtt-capture.exe"; Comment: "Collects data for computer usage statistics"; Tasks: autorun

[Run]
Filename: "{app}\bin\arbtt-capture.exe"; Description: "Start collecting usage data"; Flags: nowait postinstall skipifsilent; Tasks: runcapture

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Code]
const
  EnvironmentKey = 'Environment';
  InstallerKey = 'Software\arbtt\Installer';
  PathMarkerName = 'PathEntryInstalled';

function NormalizePathEntry(Value: String): String;
begin
  Value := RemoveQuotes(Trim(Value));
  while (Length(Value) > 3) and
        ((Value[Length(Value)] = '\') or (Value[Length(Value)] = '/')) do
    Delete(Value, Length(Value), 1);
  Result := Value;
end;

function PathContains(const PathValue, Entry: String): Boolean;
var
  Remaining, Part: String;
  Delimiter: Integer;
begin
  Result := False;
  Remaining := PathValue;
  while Remaining <> '' do begin
    Delimiter := Pos(';', Remaining);
    if Delimiter = 0 then begin
      Part := Remaining;
      Remaining := '';
    end else begin
      Part := Copy(Remaining, 1, Delimiter - 1);
      Delete(Remaining, 1, Delimiter);
    end;
    if CompareText(NormalizePathEntry(Part), NormalizePathEntry(Entry)) = 0 then begin
      Result := True;
      Exit;
    end;
  end;
end;

function AddToUserPath(const Entry: String): Boolean;
var
  PathValue: String;
begin
  if not RegQueryStringValue(HKCU, EnvironmentKey, 'Path', PathValue) then
    PathValue := '';

  if PathContains(PathValue, Entry) then begin
    Result := False;
    Exit;
  end;

  if (PathValue <> '') and (PathValue[Length(PathValue)] <> ';') then
    PathValue := PathValue + ';';
  Result := RegWriteExpandStringValue(HKCU, EnvironmentKey, 'Path', PathValue + Entry);
end;

procedure RemoveFromUserPath(const Entry: String);
var
  PathValue, Remaining, Part, NewPath: String;
  Delimiter: Integer;
begin
  if not RegQueryStringValue(HKCU, EnvironmentKey, 'Path', PathValue) then
    Exit;

  Remaining := PathValue;
  NewPath := '';
  while Remaining <> '' do begin
    Delimiter := Pos(';', Remaining);
    if Delimiter = 0 then begin
      Part := Remaining;
      Remaining := '';
    end else begin
      Part := Copy(Remaining, 1, Delimiter - 1);
      Delete(Remaining, 1, Delimiter);
    end;

    if (Trim(Part) <> '') and
       (CompareText(NormalizePathEntry(Part), NormalizePathEntry(Entry)) <> 0) then begin
      if NewPath <> '' then
        NewPath := NewPath + ';';
      NewPath := NewPath + Part;
    end;
  end;

  RegWriteExpandStringValue(HKCU, EnvironmentKey, 'Path', NewPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  BinDir: String;
  InstallerOwnsEntry: Cardinal;
begin
  if CurStep <> ssPostInstall then
    Exit;

  BinDir := ExpandConstant('{app}\bin');
  InstallerOwnsEntry := 0;
  RegQueryDWordValue(HKCU, InstallerKey, PathMarkerName, InstallerOwnsEntry);

  if IsTaskSelected('modifypath') then begin
    if AddToUserPath(BinDir) or (InstallerOwnsEntry = 1) then
      RegWriteDWordValue(HKCU, InstallerKey, PathMarkerName, 1);
  end else if InstallerOwnsEntry = 1 then begin
    RemoveFromUserPath(BinDir);
    RegDeleteValue(HKCU, InstallerKey, PathMarkerName);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  InstallerOwnsEntry: Cardinal;
begin
  if CurUninstallStep <> usUninstall then
    Exit;

  InstallerOwnsEntry := 0;
  if RegQueryDWordValue(HKCU, InstallerKey, PathMarkerName, InstallerOwnsEntry) and
     (InstallerOwnsEntry = 1) then begin
    RemoveFromUserPath(ExpandConstant('{app}\bin'));
    RegDeleteValue(HKCU, InstallerKey, PathMarkerName);
    RegDeleteKeyIfEmpty(HKCU, InstallerKey);
    RegDeleteKeyIfEmpty(HKCU, 'Software\arbtt');
  end;
end;
