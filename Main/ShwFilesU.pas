unit ShwFilesU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ValEdit, System.Actions, Vcl.ActnList,
  Vcl.StdCtrls, Math, System.IOUtils, System.JSON, System.DateUtils, System.IniFiles,  System.Generics.Collections,
  VirtualTrees, VirtualTrees.Header, VirtualTrees.Types, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, System.ImageList,
  Vcl.ImgList, ShellAPI, CommCtrl, Vcl.Menus, Vcl.ComCtrls;

type
  TShwFiles = class(TForm)
    btnReFresh: TButton;
    ActionList1: TActionList;
    actSave: TAction;
    actReFresh: TAction;
    actWakeSelected: TAction;
    actRemoveSelected: TAction;
    ImageListIcons: TImageList;
    VST: TVirtualStringTree;
    PopupVST: TPopupMenu;
    Jetztaufwecken1: TMenuItem;
    N11: TMenuItem;
    Snooze1: TMenuItem;
    N5Min1: TMenuItem;
    N5Min2: TMenuItem;
    N30Min1: TMenuItem;
    N30Min2: TMenuItem;
    N2h1: TMenuItem;
    N2h2: TMenuItem;
    N8h1: TMenuItem;
    N8h2: TMenuItem;
    StatusBar1: TStatusBar;
    Individuell1: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure actReFreshExecute(Sender: TObject);
    procedure Individuell1Click(Sender: TObject);
    procedure Jetztaufwecken1Click(Sender: TObject);
    procedure PopupVSTClose(Sender: TObject);
    procedure PopupVSTPopup(Sender: TObject);
    procedure VSTxBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
        Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode;
        CellRect: TRect; var ContentRect: TRect);
    procedure VSTxCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode;
        Column: TColumnIndex; var Result: Integer);
    procedure VSTxGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind:
        TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex:
        TImageIndex);
    procedure VSTxGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column:
        TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure ApplySnoozeToSelection(Sender: TObject);
 private
    procedure LoadJsonToVST;
    procedure ApplyWakeDialogToSelection;
  public
    { Public-Deklarationen }
  protected
  end;

type
  PFileNodeData = ^TFileNodeData;
  TFileNodeData = record
    Directory: string;
    FileName: string;
    HideTime: TDateTime;
    WakeTime: TDateTime;
    MinutesToWake: Integer;
  end;

procedure WakeFileNow(const FilePath: string; Manual: Boolean = False);

var
  ShwFiles: TShwFiles;
  SysImageList: HIMAGELIST;
  FrstRun : Boolean = True;
  bTskBarEnabled: Boolean;

implementation

{$R *.dfm}

uses WakeHiddenU, WakeTimeDialog;

procedure TShwFiles.FormCreate(Sender: TObject);
begin
  ShwFiles.Visible := False;
  ShwFiles.Hide;

  bTskBarEnabled := TaskbarIconEnabled;
  if (FrstRun) and (bTskBarEnabled) then
    WindowState := wsMinimized;

  VST.NodeDataSize := SizeOf(TFileNodeData);
  VST.Header.Options := VST.Header.Options + [hoVisible];
  VST.Header.Columns.Clear;
  VST.DefaultNodeHeight := 36;
  VST.Font.Name := 'Segoe UI';
  VST.Font.Size := 10;        // z. B. 11 oder 12
  VST.Font.Style := [];       // [] = normal, [fsBold] = fett etc.
  VST.Header.Font.Style := [fsBold];
  VST.Header.Font.Size := 10;

  with VST.Header.Columns.Add do begin
    Text := 'Verzeichnis';
    Width := 500;
  end;
  with VST.Header.Columns.Add do begin
    Text := 'Dateiname';
    Width := 800;
  end;
  with VST.Header.Columns.Add do begin
    Text := 'Versteckt';
    Width := 360;
  end;
  with VST.Header.Columns.Add do begin
    Text := 'Aufwachen';
    Width := 360;
  end;
  with VST.Header.Columns.Add do begin
    Text := 'Minuten';
    Width := 300;
  end;

  VST.TreeOptions.PaintOptions := VST.TreeOptions.PaintOptions + [toShowButtons, toShowRoot, toShowTreeLines];
  VST.TreeOptions.SelectionOptions := VST.TreeOptions.SelectionOptions + [toFullRowSelect];
  VST.TreeOptions.MiscOptions := VST.TreeOptions.MiscOptions + [toEditable];
  VST.TreeOptions.AutoOptions := VST.TreeOptions.AutoOptions + [toAutoSpanColumns];
  //VST.TreeOptions.AutoOptions := VST.TreeOptions.AutoOptions - [toAutoSort];
  VST.Header.Options := VST.Header.Options + [hoAutoResize, hoColumnResize, hoVisible, hoShowSortGlyphs];

  VST.NodeDataSize := SizeOf(TFileNodeData);

  with VST.TreeOptions do
  begin
    SelectionOptions := SelectionOptions + [toMultiSelect, toFullRowSelect, toExtendedFocus];
    MiscOptions      := MiscOptions + [toGridExtensions];
    PaintOptions     := PaintOptions + [toUseBlendedImages];
  end;

  LoadJsonToVST;
end;

procedure TShwFiles.FormShow(Sender: TObject);
begin
  actRefresh.Execute;
end;

procedure TShwFiles.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (TaskbarIconEnabled) then
  begin
    Action := caNone; // NICHT schließen!
    WindowState := wsMinimized; // nur minimieren
  end
  else
    Action := caHide;
end;

procedure TShwFiles.FormActivate(Sender: TObject);
begin
  if (FrstRun) and (bTskBarEnabled) then
    if WindowState = wsMinimized then
      WindowState := wsNormal
  else
    FrstRun := False;

  BringToFront;
  SetForegroundWindow(Handle);
end;

procedure TShwFiles.LoadJsonToVST;
var
  jsonFile, jsonStr, filePath, hideStr, wakeStr: string;
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  dirPath, fileName: string;
  hideTime, wakeTime: TDateTime;
  node: PVirtualNode;
  data: PFileNodeData;
  i: Integer;
begin
  // Merke aktuellen Sortierzustand
  var savedSortColumn := VST.Header.SortColumn;
  var savedSortDirection := VST.Header.SortDirection;

  // Temporär deaktivieren
  VST.Header.SortColumn := -1;

  jsonFile := GetJsonFilePath;
  if not FileExists(jsonFile) then Exit;

  jsonStr := TFile.ReadAllText(jsonFile);
  jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
  if not Assigned(jsonArr) then Exit;

  iNumberOfFiles := jsonArr.Count;
  StatusBar1.SimpleText := GetInfoText(iNumberOfFiles);

  VST.Clear;

  for i := 0 to jsonArr.Count - 1 do
  begin
    jsonObj := jsonArr.Items[i] as TJSONObject;
    filePath := jsonObj.GetValue<string>('path');
    hideStr := jsonObj.GetValue<string>('hideTime');
    wakeStr := jsonObj.GetValue<string>('wakeTime');

    dirPath := ExtractFileDir(filePath);
    fileName := ExtractFileName(filePath);

    hideTime := ISO8601ToDate(hideStr, True);
    wakeTime := ISO8601ToDate(wakeStr, True);

    node := VST.AddChild(nil);
    data := VST.GetNodeData(node);
    data^.Directory := dirPath;
    data^.FileName := fileName;
    data^.HideTime := hideTime;
    data^.WakeTime := wakeTime;
    data^.MinutesToWake := Round((wakeTime - Now) * 24 * 60);
  end;

  jsonArr.Free;

  // Sortierung reaktivieren
  VST.Header.SortColumn := savedSortColumn;
  VST.Header.SortDirection := savedSortDirection;
  VST.SortTree(savedSortColumn, savedSortDirection, False);
end;

procedure TShwFiles.actReFreshExecute(Sender: TObject);
begin
  LoadJsonToVST;

  if not (CurrentTrayState = tisRed) and
    (not (CurrentTrayState = tisBlue) or (FormWake.Taskleistensymbol1.Checked = True)) then
  begin
    FormWake.ShowBlueBadgeIcon;
    UpdateTrayIconStatus;
    UpdateSnoozeMenuItems(False);
  end;
end;

procedure WakeFileNow(const FilePath: string; Manual: Boolean = False);
var
  jsonFile, jsonStr: string;
  jsonArr, newArr: TJSONArray;
  jsonObj: TJSONObject;
  i: Integer;
  fileAttr: DWORD;
begin
  if Manual then
    Log('🙋‍♂️ Manuell aufgeweckt: ' + FilePath)
  else
    Log('🌞 Automatisch aufgeweckt: ' + FilePath);

  if not FileExists(filePath) then
  begin
    Log('❌ Aufwecken abgebrochen – Datei nicht gefunden: ' + filePath);
    Exit;
  end;

  // Hidden-Attribut entfernen
  fileAttr := GetFileAttributes(PChar(filePath));
  if (fileAttr and FILE_ATTRIBUTE_HIDDEN) <> 0 then
  begin
    SetFileAttributes(PChar(filePath), fileAttr and not FILE_ATTRIBUTE_HIDDEN);
    Log('🌞 Datei manuell aufgeweckt: ' + filePath);
  end
  else
    Log('🔍 Datei war bereits sichtbar: ' + filePath);

  // JSON-Datei laden
  jsonFile := GetJsonFilePath;
  if not TFile.Exists(jsonFile) then Exit;

  jsonStr := TFile.ReadAllText(jsonFile);
  jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
  if not Assigned(jsonArr) then Exit;

  newArr := TJSONArray.Create;
  try
    for i := 0 to jsonArr.Count - 1 do
    begin
      jsonObj := jsonArr.Items[i] as TJSONObject;
      if jsonObj.GetValue<string>('path') <> filePath then
        newArr.AddElement(jsonObj.Clone as TJSONValue)
      else
        Log('🧹 JSON-Eintrag gelöscht nach manuellem Wakeup: ' + filePath);
    end;

    TFile.WriteAllText(jsonFile, newArr.ToJSON);
  finally
    jsonArr.Free;
    newArr.Free;
  end;

  FormWake.ShowBlueBadgeIcon;
  UpdateTrayIconStatus;
  UpdateSnoozeMenuItems(False);

  if ShwFiles.Visible then
    ShwFiles.actReFreshExecute(nil);

end;

procedure TShwFiles.Jetztaufwecken1Click(Sender: TObject);
var
  Node: PVirtualNode;
  Data: PFileNodeData;
  Paths: TList<string>;
begin
  FormWake.Timer1.Enabled := False;
  Paths := TList<string>.Create;
  try
    Node := VST.GetFirstSelected;
    while Assigned(Node) do
    begin
      Data := VST.GetNodeData(Node);
      if Assigned(Data) then
        Paths.Add(IncludeTrailingPathDelimiter(Data^.Directory) + Data^.FileName);
      Node := VST.GetNextSelected(Node);
    end;

    // Doppelte Einträge eliminieren
    Paths.Sort;
    for var i := Paths.Count-1 downto 1 do
      if SameText(Paths[i], Paths[i-1]) then
        Paths.Delete(i);

    // Alle Dateien sofort aufwecken
    for var path in Paths do
      WakeFileNow(path, True);

  finally
    Paths.Free;
    FormWake.Timer1.Enabled := True;
  end;
end;

procedure TShwFiles.PopupVSTPopup(Sender: TObject);
begin
  FormWake.Timer1.Enabled := False;
end;

procedure TShwFiles.PopupVSTClose(Sender: TObject);
begin
  FormWake.Timer1.Enabled := True;
end;

procedure TShwFiles.VSTxBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas:
    TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellPaintMode:
    TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
begin
  if VST.GetNodeLevel(Node) = 0 then
  begin
    if Node.Index mod 2 = 0 then
      TargetCanvas.Brush.Color := clWhite
    else
      TargetCanvas.Brush.Color := $F0F0F0; // hellgrau

    TargetCanvas.FillRect(CellRect);
  end;
end;

procedure TShwFiles.VSTxCompareNodes(Sender: TBaseVirtualTree; Node1, Node2:
    PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  Data1, Data2: PFileNodeData;
begin
  Data1 := Sender.GetNodeData(Node1);
  Data2 := Sender.GetNodeData(Node2);

  case Column of
    0: Result := CompareText(Data1^.Directory, Data2^.Directory);
    1: Result := CompareText(Data1^.FileName, Data2^.FileName);
    2: Result := CompareDateTime(Data1^.HideTime, Data2^.HideTime);
    3: Result := CompareDateTime(Data1^.WakeTime, Data2^.WakeTime);
    4: Result := Data1^.MinutesToWake - Data2^.MinutesToWake;
  end;
end;

procedure TShwFiles.VSTxGetImageIndex(Sender: TBaseVirtualTree; Node:
    PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted:
    Boolean; var ImageIndex: TImageIndex);

var
  Data: PFileNodeData;
begin
  if Kind <> ikNormal then Exit;
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  case Column of
    0: ImageIndex := 0; // Verzeichnis
    1: ImageIndex := 1; // Datei
    2: ImageIndex := 2; // Versteckt seit
    3: ImageIndex := 3; // WakeTime
    4: ImageIndex := 4; // Minuten
  end;
end;

procedure SleepFile(const filePath: string; minutes: Integer = 0; wakeTime: TDateTime = 0; autoHideAfter: Integer = 0);
var
  jsonFile: string;
  jsonStr: string;
  jsonArr: TJSONArray;
  jsonObj: TJSONObject;
  i: Integer;
  found: Boolean;
  finalWake: TDateTime;
begin
if wakeTime > 0 then
    finalWake := wakeTime
  else
    finalWake := IncMinute(Now, minutes);

  jsonFile := GetJsonFilePath;

  // JSON laden oder neue Liste erzeugen
  if TFile.Exists(jsonFile) then
    jsonStr := TFile.ReadAllText(jsonFile)
  else
    jsonStr := '[]';

  jsonArr := TJSONObject.ParseJSONValue(jsonStr) as TJSONArray;
  if not Assigned(jsonArr) then
  begin
    jsonArr := TJSONArray.Create;
    Log('⚠️ Fehler beim Parsen der JSON – neue Liste angelegt (Sleep)');
  end;

  found := False;

  for i := 0 to jsonArr.Count - 1 do
  begin
    jsonObj := jsonArr.Items[i] as TJSONObject;
    if jsonObj.GetValue<string>('path') = filePath then
    begin
      jsonObj.RemovePair('wakeTime');
      jsonObj.AddPair('wakeTime', DateToISO8601(finalWake, True));
      jsonObj.RemovePair('hideTime');
      jsonObj.AddPair('hideTime', DateToISO8601(Now, True));

      jsonObj.RemovePair('autoHideAfter');
      jsonObj.AddPair('autoHideAfter', TJSONNumber.Create(autoHideAfter));

      found := True;
      Break;
    end;
  end;

  if not found then
  begin
    jsonObj := TJSONObject.Create;
    jsonObj.AddPair('path', filePath);
    jsonObj.AddPair('hideTime', DateToISO8601(Now, True));
    jsonObj.AddPair('wakeTime', DateToISO8601(finalWake, True));
    jsonObj.AddPair('autoHideAfter', TJSONNumber.Create(autoHideAfter));
    jsonArr.AddElement(jsonObj);
  end;

  TFile.WriteAllText(jsonFile, jsonArr.ToJSON);
  jsonArr.Free;

  if minutes > 0 then
    Log(Format('💤 SleepFile: %s für %d min', [filePath, minutes]))
  else
    Log(Format('💤 SleepFile: %s bis %s', [filePath, DateTimeToStr(finalWake)]));

  if ShwFiles.Visible then
    ShwFiles.actReFreshExecute(nil);
end;

procedure TShwFiles.VSTxGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PFileNodeData;
begin
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  case Column of
    0: CellText := Data.Directory;
    1: CellText := Data.FileName;
    2: CellText := FormatDateTime('dd.mm.yyyy hh:nn:ss', Data.HideTime);
    3: CellText := FormatDateTime('dd.mm.yyyy hh:nn:ss', Data.WakeTime);
    4: CellText := Data.MinutesToWake.ToString;
  end;
end;

procedure TShwFiles.ApplySnoozeToSelection(Sender: TObject);
var
  minutes: Integer;
  Node: PVirtualNode;
  Data: PFileNodeData;
  filePath: string;
  SelNodes: TArray<PVirtualNode>;
  Count, i: Integer;
begin
  if VST.SelectedCount = 0 then Exit;

  minutes := TMenuItem(Sender).Tag;

  // Auswahl sichern
  SetLength(SelNodes, VST.SelectedCount);
  Node := VST.GetFirstSelected;
  Count := 0;
  while Assigned(Node) do
  begin
    SelNodes[Count] := Node;
    Inc(Count);
    Node := VST.GetNextSelected(Node);
  end;

  VST.BeginUpdate;
  try
    for i := 0 to High(SelNodes) do
    begin
      Data := VST.GetNodeData(SelNodes[i]);
      if Assigned(Data) then
      begin
        filePath := IncludeTrailingPathDelimiter(Data^.Directory) + Data^.FileName;
        SleepFile(filePath, minutes);
      end;
    end;
  finally
    VST.EndUpdate;
  end;

  actRefresh.Execute;
end;

procedure TShwFiles.Individuell1Click(Sender: TObject);
begin
  FormWake.Timer1.Enabled := False;
  ApplyWakeDialogToSelection;
  FormWake.Timer1.Enabled := True;
end;

procedure TShwFiles.ApplyWakeDialogToSelection;
var
  SelNodes: TArray<PVirtualNode>;
  Node: PVirtualNode;
  Data: PFileNodeData;
  WakeTime: TDateTime;
  AutoHideAfter: Integer; // Minuten, 0 = kein AutoHide
  FilePath: string;
  Count, i: Integer;
begin
  if VST.SelectedCount = 0 then Exit;

  // Dialog EINMAL: liefert WakeTime + optional AutoHideAfter (Minuten)
  if not TfrmWakeTimeDialog.Execute(WakeTime, AutoHideAfter) then
    raise Exception.Create('Auswahl abgebrochen. Keine WakeTime festgelegt.');

  // Auswahl sichern (wichtig: sonst zerhaut Refresh/Invalidate die Iteration)
  SetLength(SelNodes, VST.SelectedCount);
  Node := VST.GetFirstSelected;
  Count := 0;
  while Assigned(Node) do
  begin
    SelNodes[Count] := Node;
    Inc(Count);
    Node := VST.GetNextSelected(Node);
  end;

  VST.BeginUpdate;
  try
    for i := 0 to High(SelNodes) do
    begin
      Data := VST.GetNodeData(SelNodes[i]);
      if not Assigned(Data) then Continue;

      FilePath := IncludeTrailingPathDelimiter(Data^.Directory) + Data^.FileName;

      // Speichern: absolutes Datum + optional AutoHideAfter
      if AutoHideAfter > 0 then
        SleepFile(FilePath, 0, WakeTime, AutoHideAfter)
      else
        SleepFile(FilePath, 0, WakeTime);

      // Model/Anzeige aktualisieren
      Data^.HideTime      := Now;
      Data^.WakeTime      := WakeTime;
      Data^.MinutesToWake := Round((WakeTime - Now) * 24 * 60);

      VST.InvalidateNode(SelNodes[i]);
    end;
  finally
    VST.EndUpdate;
  end;

  actRefresh.Execute;
end;

end.
