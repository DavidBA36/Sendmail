program PrSendMail;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils;

var
  i: integer;

begin

  try
    for i:=1 to ParamCount -1 do
    begin
      Writeln(ParamStr(i));

    end;


    { TODO -oUser -cConsole Main : Insert code here }
      except on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
