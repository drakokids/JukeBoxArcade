unit maxiWindowFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Direct2D, Winapi.D2D1;

type
  TmaxiWindowForm = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  protected
        procedure CreateWnd; override;
  private
    { Private declarations }
    function CreateD2DCanvas(Handle: HWND): Boolean;
    procedure ApplicationEventsIdle(Sender: TObject; var Done: Boolean);
  public
    { Public declarations }
    procedure Render(Sender: TObject);
  end;

var
  maxiWindowForm: TmaxiWindowForm;
  FD2DCanvas : TDirect2DCanvas;
  CanvasActive: Boolean;

implementation

{$R *.dfm}

uses mainunit;

{ TmaxiWindowForm }

procedure TmaxiWindowForm.CreateWnd;
begin
    inherited;
    CreateD2DCanvas(Handle);
end;

procedure TmaxiWindowForm.ApplicationEventsIdle(Sender: TObject;
  var Done: Boolean);
begin
      if CanvasActive then
        Render(self);
      Done := False;
end;

function TmaxiWindowForm.CreateD2DCanvas(Handle: HWND): Boolean;
begin
   try
      FD2DCanvas.Free;
      FD2DCanvas    := TDirect2DCanvas.Create(Handle);
      Result        := TRUE;
   except
      Result        := FALSE;
   end;
end;

procedure TmaxiWindowForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CanvasActive:=false;
  //FD2DCanvas.Free;
  action:=caFree;
  FormMaxi:=nil;
end;

procedure TmaxiWindowForm.FormCreate(Sender: TObject);
begin
   //CreateD2DCanvas(self.Handle);
   Application.OnIdle := ApplicationEventsIdle;
   CanvasActive:=true;
end;

procedure TmaxiWindowForm.FormResize(Sender: TObject);
var
        Size: D2D1_SIZE_U;
begin
   Size := D2D1SizeU(ClientWidth, ClientHeight);
   ID2D1HwndRenderTarget(FD2DCanvas.RenderTarget).Resize(Size);
   Invalidate;
end;

procedure TmaxiWindowForm.Render(Sender: TObject);
begin
    FD2DCanvas.BeginDraw;
    try
       // Erase background
       FD2DCanvas.RenderTarget.Clear(D2D1ColorF(RGB(220,210,200)));

       // Clear all transformations
       FD2DCanvas.RenderTarget.SetTransform(TD2DMatrix3x2F.Identity);
    finally
       FD2DCanvas.EndDraw;
    end;
end;

end.
