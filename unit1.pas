unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, SQLite3Conn, SQLDB, DB, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, StdCtrls, ComCtrls, Menus, DBCtrls, BASS,
  dbcntrlgrid, Classes;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    DataSource1: TDataSource;
    DBCntrlGrid1: TDBCntrlGrid;
    DBMemo1: TDBMemo;
    Label3: TLabel;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLScript1: TSQLScript;
    SQLTransaction1: TSQLTransaction;
    Timer1: TTimer;
    TrackBar1: TTrackBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);


    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    {procedure SQLQuery1AfterScroll(DataSet: TDataSet); }
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Click(Sender: TObject);

  private
    function getcurrentlength(): string;
    function getcurrentpos(): string;
    procedure playfile(mfilename: UnicodeString);


  public
    channel: HSTREAM;
    PlaySync: HSYNC;

  end;

var
  Form1: TForm1;
  filename: UnicodeString;
  currentfilename: string;
  check: boolean;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Application.Terminate;
  BASS_Free();
  SQLite3Connection1.Close();
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  m: UnicodeString;
begin
  form1.Caption:='advanced player';
  m := DBMemo1.Text;
  currentfilename := '';
  currentfilename := IntToStr(DBCntrlGrid1.DataSource.DataSet.RecNo);
  //ShowMessage(m);
  playfile(m);
  form1.Caption:=form1.Caption + ' (playing: ' + ExtractFileName(DBMemo1.Text) + ' )';
end;

procedure TForm1.Button2Click(Sender: TObject);

begin
  if check = False then
  begin
    BASS_ChannelPause(channel);
    check := True;
  end
  else
  begin
    BASS_ChannelPlay(channel, False);
    check := False;
  end;

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  BASS_Channelstop(channel);
  form1.Caption:='advanced player';
  Timer1.Enabled := False;
  TrackBar1.Position := 0;
  Label3.Caption := '00:00:00';
  Label2.Caption := '00:00:00';
end;

{procedure TForm1.DBCntrlGrid1MouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: boolean);
begin
  if (channel > 0) then
  begin
    if IntToStr(DBCntrlGrid1.DataSource.DataSet.RecNo) <> currentfilename then
    begin
      Timer1.Enabled := False;
      TrackBar1.Position := 0;
      Label2.Caption := '';
      Label3.Caption := '';
    end
    else
    begin
      Timer1.Enabled := True;
      Label2.Caption := getcurrentpos();

    end;

  end;
end;}

{procedure TForm1.DBCntrlGrid1MouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: boolean);
begin
  if (channel > 0) then
  begin

    if IntToStr(DBCntrlGrid1.DataSource.DataSet.RecNo) <> currentfilename then
    begin
      Timer1.Enabled := False;
      TrackBar1.Position := 0;
      Label2.Caption := '';
      Label3.Caption := '';
    end
    else
    begin
      Timer1.Enabled := True;
      Label2.Caption := getcurrentpos();

    end;

  end;
end;}


procedure TForm1.FormCreate(Sender: TObject);
begin
  //SQLiteLibraryName:='sqlite3.dll';
  SQLite3Connection1.DatabaseName := 'files.db';
  if not BASS_Init(-1, 44100, 0, Handle, nil) then
    ShowMessage('Error initializing audio!');

end;

procedure Tform1.playfile(mfilename: UnicodeString);
begin
  if channel > 0 then
  begin                                     //this from previous video
    BASS_StreamFree(channel);
    channel := 0;
    Timer1.Enabled := False;
  end;
  channel := BASS_StreamCreateFile(False, PWideChar(mfilename), 0, 0, BASS_UNICODE);
  //play sound file
  BASS_ChannelPlay(channel, True);
  Timer1.Enabled := True;
  Label2.Caption := getcurrentlength();
  TrackBar1.Position := 0;

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
var
  i: integer;
begin
  SQLite3Connection1.Open;
  SQLScript1.Script.Text := 'delete from filesnames';
  //<--- removed the vacuum command from the script
  SQLScript1.Execute;
  SQLTransaction1.Commit;
  SQLite3Connection1.ExecuteDirect('End Transaction');
  SQLite3Connection1.ExecuteDirect('vacuum');               //<--- and added it back here
  SQLite3Connection1.ExecuteDirect('Begin Transaction');

  // SQLiteVacuum(SQLite3Connection1);
  if OpenDialog1.Execute() then
  begin                                           //this from previous sound player video
    //BASS_ChannelStop(channel);
    Button3.Click;
    SQLTransaction1.action := caCommit;
    SQLTransaction1.Active := True;
    SQLQuery1.SQL.Clear;
    SQLQuery1.Close;
    SQLQuery1.SQL.Add(
      'INSERT INTO filesnames (f_id, filepath) VALUES (:filenum,:filename)');
    for i := 0 to OpenDialog1.Files.Count - 1 do
    begin
      SQLQuery1.Params.ParamByName('filenum').AsInteger := i + 1;
      //inserts a larger deckNum(increments the previous deck)
      SQLQuery1.Params.ParamByName('filename').AsString := OpenDialog1.Files[i];
      //sqlstring:='insert into filenames (f_id, filepath) values (' + s + ',' + OpenDialog1.Files[i] + ')';
      SQLQuery1.execSQL;
    end;
    SQLTransaction1.Commit;
    SQLQuery1.SQL.Clear;
    SQLQuery1.Close;
    //------------- load files in sqlquery1
    SQLQuery1.SQL.Add('SELECT * FROM filesnames');
    //DBText1.DataField:=filename;
    SQLite3Connection1.Connected := True;
    SQLQuery1.Open;
    SQLQuery1.Last;
    TrackBar1.Position:=0;

  end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
  ShowMessage('This is a gift done in Lazarus 2.0.12' + LineEnding +
    'done by: alaa178@gmail.com');
end;

{procedure TForm1.SQLQuery1AfterScroll(DataSet: TDataSet);
begin
  if channel > 0 then
  begin
    if IntToStr(DBCntrlGrid1.DataSource.DataSet.RecNo) <> currentfilename then
    begin
      Timer1.Enabled := False;
      TrackBar1.Position := 0;
      Label2.Caption := '';
      Label3.Caption := '';
    end
    else
    begin
      Timer1.Enabled := True;
      Label2.Caption := getcurrentpos();

    end;
  end;
end;}

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  // DBCntrlGrid1.selectedr;
  Label3.Caption := getcurrentpos();
  TrackBar1.Max := trunc(BASS_ChannelBytes2Seconds(
    channel, BASS_ChannelGetLength(channel, BASS_POS_BYTE)));
  //set the max value of track bar is the same time of file
  TrackBar1.Position := trunc(BASS_ChannelBytes2Seconds(
    channel, BASS_ChannelGetPosition(channel, BASS_POS_BYTE)));
  //update the track bar position as per playing time
end;

procedure TForm1.TrackBar1Click(Sender: TObject);
begin
  if channel>0 then
  BASS_ChannelSetPosition(channel, BASS_ChannelSeconds2Bytes(channel, TrackBar1.Position), BASS_POS_BYTE);
end;





function tform1.getcurrentpos(): string;
var
  hour: integer;     //variable to count the hours in file
  minute: integer;     //  variable to count the minutes in file
  second: integer;      //variable to count the seconds in file
  time: double;          //to get the file time hh:mm:ss
begin
  time := BASS_ChannelBytes2Seconds(channel, BASS_ChannelGetPosition(
    channel, BASS_POS_BYTE));
  //convert the bytes of file into seconds
  hour := trunc(time / 3600);   // hr =3600 seconds   // trunc(12.75)=12
  time := time - hour * 3600;      //get the balance after getting the hours
  minute := Trunc(time / 60);    // get the minutes
  time := time - minute * 60;
  //get the seconds after counting hr,min
  second := Trunc(time);   // get the seconds   //assign hh:mm:ss to labele 1
  Result := Format('%.2d', [hour]) + ':' + Format('%.2d', [minute]) +
    ':' + Format('%.2d', [second]);
end;

function Tform1.getcurrentlength(): string;
var
  hour1: integer;     //variable to count the hours in file
  minute1: integer;     //  variable to count the minutes in file
  second1: integer;      //variable to count the seconds in file
  time1: double;          //to get the file time hh:mm:ss
begin
  time1 := BASS_ChannelBytes2Seconds(channel, BASS_ChannelGetLength(
    channel, BASS_POS_BYTE));
  //convert the bytes of file into seconds
  hour1 := trunc(time1 / 3600);   // hr =3600 seconds   // trunc(12.75)=12
  time1 := time1 - hour1 * 3600;      //get the balance after getting the hours
  minute1 := Trunc(time1 / 60);    // get the minutes
  time1 := time1 - minute1 * 60;
  //get the seconds after counting hr,min
  second1 := Trunc(time1);   // get the seconds   //assign hh:mm:ss to labele 1
  Result := Format('%.2d', [hour1]) + ':' + Format('%.2d', [minute1]) +
    ':' + Format('%.2d', [second1]);
end;

end.
