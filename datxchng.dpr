library datxchng;

uses
  SysUtils, StrUtils, IniFiles,
  Classes;

{$R *.res}

type TRecord = record
        Key: shortstring;
        Value:  shortstring;
     end;

type TPRecord = record
        Key: PChar;
        Value:  PChar;
     end;

type TDB = record
        Count: integer;
        Records: array [0..255] of TRecord;
      end;
     PTDB = ^TDB;

const
    EBU: array [128..254] of Char =
    ('á','a','é','e','í','i','ó','o','ú','u','N','Ç','ª','ß','I', #0,
     'â','ä','e','ë','î','i','ô','ö','u','ü','n','ç','º', #0,'i', #0,
      #0, #0,'©','‰', #0,'ì','ò','õ', #0, #0, #0,'$', #0, #0, #0, #0,
      #0, #0, #0, #0,'±','I','ñ','û','µ','?','÷','°', #0, #0, #0,'§',
     'Á','A','É','E','Í','I','Ó','O','Ú','U','Ø','È','Š','Ž','Ð','L',
     'Â','Ä','E','Ë','Î','I','Ô','Ö','U','Ü','ø','è','š','ž','ð','l',
      #0, #0, #0, #0, #0,'Ý', #0, #0, #0, #0,'À','Æ','Œ','', #0, #0,
      #0, #0, #0, #0, #0,'ý', #0, #0, #0, #0,'à','æ','œ','Ÿ', #0);

var
    Param1: array [0..1023] of char;
    Param2: array [0..1023] of char;
    WorkDir: string;

function ReadValue(Key: PChar; DBPointer: PTDB): PChar; stdcall;
var a,i: integer;
    SKey: shortstring;
begin
Result:='';
SKey:=shortstring(Key);
a:=DBPointer^.Count;
if (a>length(DBPointer^.Records)) then a:=length(DBPointer^.Records);  //ochrana
for i:=1 to a do
  begin
  if (DBPointer^.Records[i-1].Key=SKey) then
    begin Result:=StrPCopy(Param1,DBPointer^.Records[i-1].Value); exit; end;
  end;
end;

function ReadRecord(Index: integer; DBPointer: PTDB): TPRecord; stdcall;
begin
if (Index>=DBPointer^.Count) or (Index>=length(DBPointer^.Records)) then
  begin
  Result.Key:='';
  Result.Value:='';
  end else begin
  Result.Key:=StrPCopy(Param1,DBPointer^.Records[Index].Key);
  Result.Value:=StrPCopy(Param2,DBPointer^.Records[Index].Value);
  end;
end;

procedure AddValue(Key, Value: PChar; DBPointer: PTDB); stdcall;
var a,i: integer;
    SKey, SValue: shortstring;
    ASValue: string;
begin
SKey:=shortstring(Key);
ASValue:=Value;
if (length(ASValue)>255) then ASValue:=LeftStr(ASValue,252)+'...';
SValue:=shortstring(ASValue);
a:=DBPointer^.Count;
if (a>length(DBPointer^.Records)) then a:=length(DBPointer^.Records);  //ochrana
for i:=1 to a do
  begin
  if (DBPointer^.Records[i-1].Key=SKey) then
    begin DBPointer^.Records[i-1].Value:=SValue; exit; end;
  end;
if (a<length(DBPointer^.Records)-1) then
  begin
  DBPointer^.Count:=a+1;
  DBPointer^.Records[a].Value:=SValue;
  DBPointer^.Records[a].Key:=SKey;
  exit;
  end;
if (SKey='COMMAND') then
  begin
  a:=length(DBPointer^.Records)-1;
  DBPointer^.Records[a].Key:=SKey;
  DBPointer^.Records[a].Value:=SValue;
  end;
end;

procedure ResetValues(DBPointer: PTDB); stdcall;
begin
DBPointer^.Count:=0;
end;

function CountRecords(DBPointer: PTDB): integer; stdcall;
var a: integer;
begin
a:=DBPointer^.Count;
if (a>length(DBPointer^.Records)) then a:=length(DBPointer^.Records);
Result:=a;
end;

procedure SavePChar(Filename, Section, Key, Value: PChar); stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Reg.WriteString(string(Section), string(Key), string(Value));
    finally
    Reg.Free;
    end;
  except
  end;
end;

procedure SaveInteger(Filename, Section, Key: Pchar; Value: integer); stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Reg.WriteInteger(string(Section), string(Key), Value);
    finally
    Reg.Free;
    end;
  except
  end;
end;

procedure SaveBoolean(Filename, Section, Key: Pchar; Value: boolean); stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Reg.WriteBool(string(Section), string(Key), Value);
    finally
    Reg.Free;
    end;
  except
  end;
end;

function LoadPChar(Filename, Section, Key, DefaultValue: PChar): PChar; stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
Result:=DefaultValue;
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Result:=StrPCopy(Param1,Reg.ReadString(string(Section), string(Key), string(DefaultValue)));
    finally
    Reg.Free;
    end;
  except
  end;
end;

function LoadInteger(Filename, Section, Key: Pchar; DefaultValue: integer): integer; stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
Result:=DefaultValue;
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Result:=Reg.ReadInteger(string(Section), string(Key), DefaultValue);
    finally
    Reg.Free;
    end;
  except
  end;
end;

function LoadBoolean(Filename, Section, Key: Pchar; DefaultValue: boolean): boolean; stdcall;
var Reg: TIniFile;
begin
Chdir(WorkDir);
Result:=DefaultValue;
try
  Reg:=TIniFile.Create(string(Filename));
  try
    Result:=Reg.ReadBool(string(Section), string(Key), DefaultValue);
    finally
    Reg.Free;
    end;
  except
  end;
end;

function CharConv(Ch, CT: Byte): Byte; stdcall;
begin
Result:=Ch;
if (Ch>=128) and (Ch<255) then
  if (EBU[Ch]<>#0) then Result:=Ord(EBU[Ch]);
end;

Exports
  ReadValue, ReadRecord, AddValue, ResetValues, CountRecords,
  SavePChar, SaveInteger, SaveBoolean, LoadPChar, LoadInteger, LoadBoolean,
  CharConv;

begin
WorkDir:=ExtractFilePath(ParamStr(0));
end.

