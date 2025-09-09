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
    procedure VSTxGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column:
        TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure VSTPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure VSTxGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: TImageIndex);
    procedure ApplySnoozeToSelection(Sender: TObject);
 private
    procedure LoadJsonToVST;
    procedure ApplyWakeDialogToSelection;
    procedure MergeQueueIntoTree;
  public
    { Public-Deklarationen }
  protected
  end;

type
  TItemStatus = (isHidden, isQueued);

  PFileNodeData = ^TFileNodeData;
  TFileNodeData = record
    Directory: string;
    FileName: string;
    HideTime: TDateTime;
    WakeTime: TDateTime;
    MinutesToWake: Integer;
    Status: TItemStatus;     // NEU
  end;

procedure WakeFileNow(const FilePath: string; Manual: Boolean = False);

var
  ShwFiles: TShwFiles;
  SysImageList: HIMAGELIST;
  FrstRun : Boolean = True;
  bTskBarEnabled: Boolean;
  ActiveWakeScheduled: TDateTime = 0;  // geplante WakeTime des aktuell angezeigten Toast-Items
  ActiveHideTime: TDateTime = 0;       // << NEU

const
  QUEUE_ICON_IDX = 5; // anpassen, falls anderes Index

implementation

{$R *.dfm}

uses WakeHiddenU, WakeTimeDialog;

function FormatIfSet(const DT: TDateTime): string;
begin
  if DT <= 0 then
    Result := ''
  else
    Result := FormatDateTime('dd.mm.yyyy hh:nn:ss', DT);
end;

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

  VST.TreeOptions.PaintOptions     := VST.TreeOptions.PaintOptions + [toShowButtons, toShowRoot, toShowTreeLines, toUseBlendedImages];
  VST.TreeOptions.SelectionOptions := VST.TreeOptions.SelectionOptions + [toMultiSelect, toFullRowSelect, toExtendedFocus];
  VST.TreeOptions.MiscOptions      := VST.TreeOptions.MiscOptions + [toEditable, toGridExtensions];
  VST.TreeOptions.AutoOptions      := VST.TreeOptions.AutoOptions + [toAutoSpanColumns];
  //VST.TreeOptions.AutoOptions      := VST.TreeOptions.AutoOptions - [toAutoSort];

  VST.Header.Options               := VST.Header.Options + [hoAutoResize, hoColumnResize, hoVisible, hoShowSortGlyphs];
  VST.NodeDataSize                 := SizeOf(TFileNodeData);

//  LoadJsonToVST;

  // Wichtig: Icons wirklich anzeigen lassen
  VST.Images := ImageListIcons;

  // Spalten nicht „wegauto-resizen“
  VST.Header.Options := VST.Header.Options - [hoAutoResize];
  VST.TreeOptions.AutoOptions := VST.TreeOptions.AutoOptions - [toAutoSpanColumns];
  VST.Header.Options := VST.Header.Options + [hoAutoSpring];

  // OnGetImageIndex eindeutig setzen
  VST.OnGetImageIndex := VSTxGetImageIndex;

  // NICHT anzeigen
  Visible := False;
  Hide;
end;

procedure TShwFiles.FormShow(Sender: TObject);
begin
  // Beim Boot unsichtbar bleiben, aber Daten laden
  if FrstRun then
  begin
    FrstRun := False;

    // Taskbar-Setting respektieren: Fenster NICHT sichtbar machen
    if TaskbarIconEnabled then
    begin
//      Visible := False;   // bleibt zu
//      Hide;
      // Daten trotzdem laden
      LoadJsonToVST;
      Exit;
    end;
  end;

  // Normale Anzeige (wenn der Benutzer wirklich öffnet)
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
  if FrstRun then Exit; // Startaktivierung ignorieren

  // Nur wenn der User das Fenster wirklich geöffnet hat:
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
    data^.Status := isHidden;
  end;

  jsonArr.Free;

  MergeQueueIntoTree;

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

procedure SleepFile(const filePath: string; minutes: Integer = 0;
                    wakeTime: TDateTime = 0; autoHideAfter: Integer = 0;
                    doRefresh: Boolean = True);
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

  if doRefresh and ShwFiles.Visible then
    ShwFiles.actReFreshExecute(nil);
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

procedure TShwFiles.VSTxGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean; var ImageIndex: TImageIndex);
var
  Data: PFileNodeData;
begin
  if Kind <> ikNormal then Exit;

  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  // Queue-Zeile: nur in der Minuten-Spalte (4) das Schlange-Icon anzeigen
  if Data^.Status = isQueued then
  begin
    if Column = 4 then
      ImageIndex := QUEUE_ICON_IDX
    else
      ImageIndex := -1;
    Exit;
  end;

//  // Queue-Icon hat in Spalte 0 Vorrang
//  if (Column = 4) and (Data^.Status = isQueued) then
//  begin
//    ImageIndex := QUEUE_ICON_IDX;
//    Ghosted := False;   // sicherheitshalber
//    Exit;
//  end;

  // Standard-Zuordnung (deine bisherigen Spalten-Icons)
  case Column of
    0: ImageIndex := 0; // Verzeichnis
    1: ImageIndex := 1; // Datei
    2: ImageIndex := 2; // Versteckt seit
    3: ImageIndex := 3; // WakeTime
    4: ImageIndex := 4; // Minuten
  else
    ImageIndex := -1;
  end;
end;

procedure TShwFiles.MergeQueueIntoTree;
var
  qs: TQueueSnapshot;
  i: Integer;
  Node: PVirtualNode;
  Data: PFileNodeData;
begin
  qs := GetQueueSnapshot;

  for i := 0 to High(qs) do
  begin
    Node := VST.AddChild(nil);
    Data := VST.GetNodeData(Node);
    Data^.Directory     := ExtractFilePath(qs[i].Path);
    Data^.FileName      := ExtractFileName(qs[i].Path);
    Data^.HideTime      := qs[i].HideTime;      // << NEU: echte Versteckt-Zeit!
    Data^.WakeTime      := qs[i].Scheduled;     // geplante Weckung
    Data^.MinutesToWake := 0;                   // optional
    Data^.Status        := isQueued;
  end;

  // Aktives Toast-Item ebenfalls zeigen (solange Toast oder Rot-Hold)
  if (LastWokenFile <> '') and (IsActiveWake or InRedHold) then
  begin
    Node := VST.AddChild(nil);
    Data := VST.GetNodeData(Node);
    Data^.Directory     := ExtractFilePath(LastWokenFile);
    Data^.FileName      := ExtractFileName(LastWokenFile);
    Data^.HideTime      := ActiveHideTime;       // << NEU
    Data^.WakeTime      := ActiveWakeScheduled;  // falls 0 → bleibt leer formatiert
    Data^.MinutesToWake := 0;
    Data^.Status        := isQueued;
  end;
end;

procedure TShwFiles.VSTPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
var
  Data: PFileNodeData;
begin
  Data := VST.GetNodeData(Node);
  if Assigned(Data) and (Data^.Status = isQueued) then
  begin
    TargetCanvas.Font.Color := clGrayText;   // Graustufen-Optik
    TargetCanvas.Font.Style := [fsItalic];   // optional
  end;
end;

procedure TShwFiles.VSTxGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
var
  Data: PFileNodeData;
begin
  CellText := '';
  Data := Sender.GetNodeData(Node);
  if not Assigned(Data) then Exit;

  if Data^.Status = isQueued then
  begin
    case Column of
      0: CellText := Data.Directory;
      1: CellText := Data.FileName;
      2: CellText := FormatIfSet(Data.HideTime);   // << NEU: jetzt sichtbar
      3: CellText := FormatIfSet(Data.WakeTime);
//      4: CellText := 'Queued';                     // falls Spalte 4 weiterhin existiert
    end;
    Exit;
  end;

  // normale (hidden) Items
  case Column of
    0: CellText := Data.Directory;
    1: CellText := Data.FileName;
    2: CellText := FormatIfSet(Data.HideTime);
    3: CellText := FormatIfSet(Data.WakeTime);
    4: if Data.MinutesToWake > 0 then
         CellText := Data.MinutesToWake.ToString;
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
  // Nur wenn die Form sichtbar & fokussiert ist (echte Benutzerinteraktion)
  if not Self.Visible then Exit;
  if not Self.Focused and not VST.Focused then Exit;

  FormWake.Timer1.Enabled := False;
  try
    ApplyWakeDialogToSelection;
  finally
    FormWake.Timer1.Enabled := True;
  end;
end;

procedure TShwFiles.ApplyWakeDialogToSelection;
var
  SelNodes: TArray<PVirtualNode>;
  Node: PVirtualNode;
  Data: PFileNodeData;
  WakeTime: TDateTime;
  AutoHideAfter: Integer; // Minuten, 0 = kein AutoHide
  Paths: TList<string>;
  Count, i: Integer;
begin
  if VST.SelectedCount = 0 then Exit;

  // Init, sonst liest du Müll
  AutoHideAfter := 0;

  if not TfrmWakeTimeDialog.Execute(WakeTime) then
    raise Exception.Create('Auswahl abgebrochen. Keine WakeTime festgelegt.');

  // Auswahl sichern (Nodes) -> daraus gleich Strings extrahieren
  SetLength(SelNodes, VST.SelectedCount);
  Node := VST.GetFirstSelected;
  Count := 0;
  while Assigned(Node) do
  begin
    SelNodes[Count] := Node;
    Inc(Count);
    Node := VST.GetNextSelected(Node);
  end;

  // Pfade als STRINGS puffern (unabhängig von Node-Lebensdauer)
  Paths := TList<string>.Create;
  try
    for i := 0 to High(SelNodes) do
    begin
      Data := VST.GetNodeData(SelNodes[i]);
      if Assigned(Data) then
        Paths.Add(IncludeTrailingPathDelimiter(Data^.Directory) + Data^.FileName);
    end;

    // Jetzt Batch-Operation: KEIN Refresh zwischendurch!
    FormWake.Timer1.Enabled := False;
    VST.BeginUpdate;
    try
      for i := 0 to Paths.Count - 1 do
      begin
        if AutoHideAfter > 0 then
          SleepFile(Paths[i], 0, WakeTime, AutoHideAfter, False)  // doRefresh=False
        else
          SleepFile(Paths[i], 0, WakeTime, 0, False);             // doRefresh=False
      end;

      // (Optional) lokale Anzeige aktualisieren – kann man sich sparen,
      // weil wir gleich komplett refreshen. Wenn du es behalten willst:
      {
      for i := 0 to High(SelNodes) do
      begin
        Data := VST.GetNodeData(SelNodes[i]);
        if Assigned(Data) then
        begin
          Data^.HideTime      := Now;
          Data^.WakeTime      := WakeTime;
          Data^.MinutesToWake := Round((WakeTime - Now) * 24 * 60);
          // Wenn du Queue/Status hier setzen willst:
          // Data^.Status := isHidden;
          VST.InvalidateNode(SelNodes[i]);
        end;
      end;
      }
    finally
      VST.EndUpdate;
      FormWake.Timer1.Enabled := True;
    end;

  finally
    Paths.Free;
  end;

  // EIN finaler Refresh
  actRefresh.Execute;
end;

end.
