unit SemVerCompare;

interface

uses
  System.SysUtils, System.StrUtils, System.Types, Math;

type
  TSemVer = record
    Major, Minor, Patch: Integer;
    PreRelease: string;  // z.B. 'alpha.1'
    BuildMeta:  string;  // z.B. 'build.5'

    class function TryParse(const S: string; out V: TSemVer): Boolean; static;
    class function Compare(const A, B: TSemVer): Integer; static; // -1=A<B, 0=eq, 1=A>B
  end;

/// True, wenn Latest > Current (strikt neuer)
function IsVersionNewer(const Current, Latest: string): Boolean;

implementation

function IsNumeric(const S: string): Boolean;
var
  i: Integer;
begin
  Result := (S <> '');
  if not Result then Exit;
  for i := 1 to Length(S) do
    if not CharInSet(S[i], ['0'..'9']) then
      Exit(False);
end;

function SafeToInt(const S: string): Integer;
begin
  Result := 0;
  if S = '' then Exit;
  TryStrToInt(S, Result);
end;

function SplitFirst(const S: string; const Delim: Char; out LeftPart, RightPart: string): Boolean;
var
  p: Integer;
begin
  p := S.IndexOf(Delim);
  Result := p > 0;
  if Result then
  begin
    LeftPart  := Copy(S, 1, p);
    RightPart := Copy(S, p+1, MaxInt);
  end
  else
  begin
    LeftPart  := S;
    RightPart := '';
  end;
end;

{ TSemVer }

class function TSemVer.TryParse(const S: string; out V: TSemVer): Boolean;
var
  work, core, rest, pre, build: string;
  parts: TArray<string>;
begin
  V.Major := 0; V.Minor := 0; V.Patch := 0; V.PreRelease := ''; V.BuildMeta := '';
  Result := False;

  work := Trim(S);
  if work = '' then Exit;

  // optionales 'v' / 'V' droppen (Tags wie 'v1.2.3')
  if (work[1] in ['v', 'V']) then
    work := work.Substring(1);

  // split Build-Metadaten (+)
  SplitFirst(work, '+', core, build);
  V.BuildMeta := build;

  // split PreRelease (-)
  SplitFirst(core, '-', core, pre);
  V.PreRelease := pre;

  // Core X.Y.Z
  parts := core.Split(['.']);
  if Length(parts) < 1 then Exit;

  V.Major := SafeToInt(parts[0]);
  if Length(parts) >= 2 then V.Minor := SafeToInt(parts[1]);
  if Length(parts) >= 3 then V.Patch := SafeToInt(parts[2]);

  Result := True;
end;

class function TSemVer.Compare(const A, B: TSemVer): Integer;

  function CmpInt(a, b: Integer): Integer; inline;
  begin
    if a < b then Exit(-1);
    if a > b then Exit(1);
    Result := 0;
  end;

  // SemVer-Regel: PreRelease vergleicht nach dot-getrennten Identifiers.
  // - Numerisch < Alphanumerisch
  // - Numerisch: numerischer Vergleich
  // - Kürzere Liste < längere Liste, wenn Prefix gleich
  function CmpPre(const P1, P2: string): Integer;
  var
    a1, a2: TArray<string>;
    i, n: Integer;
    n1, n2, bothNum: Boolean;
    v1, v2: Integer;
  begin
    // leer hat höhere Priorität (Release > PreRelease)
    if (P1 = '') and (P2 = '') then Exit(0);
    if (P1 = '') then Exit(1);   // A hat kein Pre ? A > B
    if (P2 = '') then Exit(-1);  // B hat kein Pre ? A < B

    a1 := P1.Split(['.']);
    a2 := P2.Split(['.']);
    n  := Min(Length(a1), Length(a2));

    for i := 0 to n-1 do
    begin
      n1 := IsNumeric(a1[i]);
      n2 := IsNumeric(a2[i]);

      if n1 and n2 then
      begin
        v1 := SafeToInt(a1[i]);
        v2 := SafeToInt(a2[i]);
        Result := CmpInt(v1, v2);
        if Result <> 0 then Exit;
      end
      else if n1 <> n2 then
      begin
        // numerisch < alphanumerisch
        if n1 then Exit(-1) else Exit(1);
      end
      else
      begin
        // beides alphanumerisch: lexikographisch
        Result := CompareStr(a1[i], a2[i]);
        if Result <> 0 then Exit;
      end;
    end;

    // gleicher Prefix ? kürzere Liste ist kleiner
    Result := CmpInt(Length(a1), Length(a2));
  end;

begin
  Result := CmpInt(A.Major, B.Major);
  if Result <> 0 then Exit;

  Result := CmpInt(A.Minor, B.Minor);
  if Result <> 0 then Exit;

  Result := CmpInt(A.Patch, B.Patch);
  if Result <> 0 then Exit;

  Result := CmpPre(A.PreRelease, B.PreRelease);
end;

function IsVersionNewer(const Current, Latest: string): Boolean;
var
  VC, VL: TSemVer;
  okC, okL: Boolean;
begin
  okC := TSemVer.TryParse(Current, VC);
  okL := TSemVer.TryParse(Latest,  VL);

  if okC and okL then
    Result := TSemVer.Compare(VC, VL) < 0  // Latest > Current?
  else
  begin
    // Fallback: wenn Parsing fehlschlägt ? einfache Heuristik
    Result := not SameText(Current.Trim, Latest.Trim);
  end;
end;

end.
