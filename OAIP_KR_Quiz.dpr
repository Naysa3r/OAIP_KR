program OAIP_KR_Quiz;

uses
  Vcl.Forms,
  OAIP_KR_Quiz_main in 'OAIP_KR_Quiz_main.pas' {MainMenu},
  AdminUnit in 'AdminUnit.pas' {FormAdmin};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainMenu, MainMenu);
  Application.CreateForm(TFormAdmin, FormAdmin);
  Application.Run;
end.
