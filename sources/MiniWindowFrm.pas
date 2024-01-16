unit MiniWindowFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,Vcl.Direct2D, Winapi.D2D1;

type
 TMainButton=record
   id: integer;
   Caption: string;
   Key: string;
 end;


type
  TFormMiniWindow = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
  protected
        procedure CreateWnd; override;
  private
    { Private declarations }
    procedure SetButton(skey, scaption: string);
    function CreateD2DCanvas(Handle: HWND): Boolean;
    procedure ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
  public
    { Public declarations }
    procedure Render(Sender: TObject);
    procedure DrawButton(index: integer; Text: String; ButColor ,FontColor: cardinal);
    procedure DrawRadioButtons;
    procedure DrawVolumeBar;
  end;

var
  FormMiniWindow: TFormMiniWindow;
  FD2DCanvas : TDirect2DCanvas;
  CanvasActive: Boolean;
  Buttons: array of TMainButton;


implementation

{$R *.dfm}

uses mainunit,sqlitefunctions,bass;

procedure TFormMiniWindow.CreateWnd;
begin
    inherited;
    CreateD2DCanvas(Handle);
end;

procedure TFormMiniWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CanvasActive:=false;
  //FD2DCanvas.Free;
  action:=caFree;
  FormMini:=nil;

end;

procedure TFormMiniWindow.SetButton(skey, scaption: string);
var index: integer;
begin
    index:=length(Buttons);
    Setlength(Buttons,Index+1);
    Buttons[index].id:=index;
    Buttons[index].Caption:=sCaption;
    Buttons[index].key:=sKey;
end;

procedure TFormMiniWindow.FormCreate(Sender: TObject);
begin

    //Default Values
    SelectedButton:=0;
    SelectedRadio:=0;
    SelectedAlbum:=0;
    SelectedMusic:=0;
    CurrentScene:=0; //Menu

    SetButton('RADIO','Radio Stream');
    SetButton('ALBUNS','Music Albuns');
    SetButton('ALL_MUSIC','All Music');
    SetButton('DVD','DVD');
    SetButton('VIDEOS','Videos');
    SetButton('KARAOKE','Karaoke');
    SetButton('WEATHER','Weather');
    SetButton('GAMES','Games');
    SetButton('WWW','Internet');

   //CreateD2DCanvas(self.Handle);
   Application.OnIdle := ApplicationEventsIdle;
   CanvasActive:=true;

end;

procedure TFormMiniWindow.FormResize(Sender: TObject);
var
        Size: D2D1_SIZE_U;
begin
   Size := D2D1SizeU(ClientWidth, ClientHeight);
   ID2D1HwndRenderTarget(FD2DCanvas.RenderTarget).Resize(Size);
   Invalidate;
end;

function TFormMiniWindow.CreateD2DCanvas(Handle: HWND): Boolean;
begin
   try
      FD2DCanvas.Free;
      FD2DCanvas    := TDirect2DCanvas.Create(Handle);
      Result        := TRUE;
   except
      Result        := FALSE;
   end;
end;

procedure TFormMiniWindow.ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
begin
      if CanvasActive then
        Render(self);
      Done := False;
end;

procedure TFormMiniWindow.Render(Sender: TObject);
var
   Rect1 : D2D1_RECT_F;
   Rect2: D2D1_ROUNDED_RECT;
   Angle : Single;
   I     : Integer;
const
   RECT_SIZE  = 50;
   ANGLE_STEP = 15.0;
begin
FD2DCanvas.BeginDraw;
 try
   // Erase background
   FD2DCanvas.RenderTarget.Clear(D2D1ColorF(RGB(80,80,80)));

   // Clear all transformations
   FD2DCanvas.RenderTarget.SetTransform(TD2DMatrix3x2F.Identity);

   //Main Menu
   if CurrentScene=0 then
    begin
      for i := 0 to Length(buttons)-1 do
        DrawButton(i,Buttons[i].Caption,RGB(50,50,50), clWhite);
      DrawVolumeBar;
    end;

   //Radios Browse
   if CurrentScene=2 then
    begin
     DrawRadioButtons;
     DrawVolumeBar;
    end;

   FD2DCanvas.Font.Size:=6;
   FD2DCanvas.Font.Color:=clRED;
   FD2DCanvas.TextOut(0,clientheight-60,debugString);
 finally
   FD2DCanvas.EndDraw;
 end;
end;

procedure TFormMiniWindow.DrawButton(index: integer; Text: String; ButColor ,FontColor: cardinal);
var Rect2: D2D1_ROUNDED_RECT;
    wdiv3, hdiv3, x,y, maxw, maxh: integer;
    textw,texth: integer;
    col,row:integer;
begin
    row:=index div MENU_COLS;
    col:=index-row*MENU_COLS;
    maxw:=ClientWidth-(ClientWidth div 10);
    maxh:=ClientHeight;
    wdiv3:=(maxw  div MENU_COLS);
    hdiv3:=(maxh div MENU_ROWS);
    x:=col*wdiv3;
    y:=row*hdiv3;
    Rect2.rect:=Rect(x+1,y+2,x+wdiv3-2,y+hdiv3-2);
    Rect2.radiusX:=10;
    Rect2.radiusY:=10;
    FD2DCanvas.Brush.Color:= ButColor;
    FD2DCanvas.Brush.Style:=bsSolid;
    FD2DCanvas.FillRoundedRectangle(Rect2);
    If SelectedButton=index then
     begin
       FD2DCanvas.Pen.Color:=RGB(255,255,255);
       FD2DCanvas.Pen.Width:=3;
       FD2DCanvas.Font.Size:=20;
     end
    else
     begin
       FD2DCanvas.Pen.Color:=RGB(128,128,128);
       FD2DCanvas.Pen.Width:=1;
       FD2DCanvas.Font.Size:=12;
     end;
    FD2DCanvas.DrawRoundedRectangle(rect2);
    FD2DCanvas.Font.Color:=FontColor;
    textw:=FD2DCanvas.TextWidth(text);
    texth:=FD2DCanvas.TextHeight(text);
    FD2DCanvas.TextOut(x+1+(wdiv3 div 2)-(textw div 2),y+1+3*(hdiv3 div 4)-(texth div 2),Text);

end;

procedure TFormMiniWindow.DrawRadioButtons;
var Rect2: D2D1_ROUNDED_RECT;
    wdiv3,  x,y, maxw, maxh: integer;
    textw,texth: integer;
    index,col,row,cols:integer;
    caption: string;
begin
    maxw:=ClientWidth-(ClientWidth div 10);
    maxh:=ClientHeight;
    cols:=maxw div 160;
    wdiv3:=(maxw  div cols);

    for index := 0 to Length(AllRadios)-1 do
     begin
      row:=index div cols;
      col:=index-row*cols;
      x:=col*wdiv3;
      y:=row*160;

      Rect2.rect:=Rect(x+1,y+2,x+wdiv3-2,y+160-2);
      Rect2.radiusX:=10;
      Rect2.radiusY:=10;
      FD2DCanvas.Brush.Color:= RGB(0,0,0);
      FD2DCanvas.Brush.Style:=bsSolid;
      FD2DCanvas.FillRoundedRectangle(Rect2);

      If SelectedRadio=index then
       begin
         FD2DCanvas.Pen.Color:=clYellow;
         FD2DCanvas.Pen.Width:=3;
         FD2DCanvas.Font.Size:=16;
       end
      else
       begin
         FD2DCanvas.Pen.Color:=RGB(128,128,128);
         FD2DCanvas.Pen.Width:=1;
         FD2DCanvas.Font.Size:=9;
       end;

      FD2DCanvas.DrawRoundedRectangle(rect2);

      if (AllRadios[index].coverid>=0) and (AllRadios[index].coverid<length(AllCovers)) then
       if AllCovers[AllRadios[index].coverid]<>nil then
        FD2DCanvas.Draw(x+((wdiv3-160) div 2),y+5,AllCovers[AllRadios[index].coverid]);

      FD2DCanvas.Font.Color:=clWhite;
      textw:=FD2DCanvas.TextWidth(text);
      texth:=FD2DCanvas.TextHeight(text);

      caption:=DecodeString(AllRadios[index].name);
      FD2DCanvas.TextOut(x+1+(wdiv3 div 2)-(textw div 2),y+1+4*(160 div 5)-(texth div 2),caption);

     end;

end;

procedure TFormMiniWindow.DrawVolumeBar;
var maxw,barw,barh, xc,y: integer;
    Rect2,Rect3,rect4,rect5: D2D1_RECT_F;
    mainvalue, atenvalue: integer;
begin
    maxw:=ClientWidth div 10;
    barw:=maxw div 4;
    barh:=clientheight-maxw-barw*2;
    xc:=ClientWidth-(maxw div 2);
    y:=barw;
    FD2DCanvas.Brush.Color:= clGreen;
    FD2DCanvas.Brush.Style:=bsSolid;
    //Main Volume Bar (Volume of PC)
    Rect2:=Rect(xc-barw-(barw div 2),y,xc-barw+(barw div 2),clientheight-maxw-barw);
    rect3:=rect2;
    //The green bar in main volume
    mainvalue:=trunc(barh*Mainvolume);
    rect3.top:=rect2.top+barh-mainvalue;
    FD2DCanvas.FillRectangle(rect3);
    FD2DCanvas.Pen.Color:=clWhite;
    FD2DCanvas.DrawRectangle(Rect2);
    //Attenuation Bar ( volume of channel )
    Rect4:=Rect(xc+barw-(barw div 2),y,xc+barw+(barw div 2),clientheight-maxw-barw);
    rect5:=rect4;
    //The green bar in attenuation volume
    atenvalue:=trunc(barh*volume/100);
    rect5.top:=rect4.top+barh-atenvalue;
    FD2DCanvas.FillRectangle(rect5);
    FD2DCanvas.DrawRectangle(Rect4);
    //Text on TOP
    FD2DCanvas.Font.Color:=clwhite;
    FD2DCanvas.Font.Size:=8;
    FD2DCanvas.Brush.Style:=bsClear;
    FD2DCanvas.TextOut(trunc(Rect2.left),1,'Vol');
    FD2DCanvas.TextOut(trunc(Rect4.left),1,'Att');


end;

end.
