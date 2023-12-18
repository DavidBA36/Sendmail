program SendMail;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, IdExplicitTLSClientServerBase, IdSSL, IdSSLOpenSSL, IdGlobal, IdBaseComponent, System.Generics.Collections, System.RegularExpressions, IdText, IdMessage,
  IdAttachmentFile, IdSMTPBase, IdSMTP;

var
  i: integer;
  Servidor: String;
  Port: String;
  ToAddr: String;
  FromAddr: String;
  ABody: String;
  Subject: String;
  Attachments: String;
  Login: String;
  TLS: Boolean;
  Quiet: Boolean;

procedure ShowHelp;
begin
  Writeln('--------------------------------------------------------------------------------------');
  Writeln('Emite Networks SendMail: Send mails by cmd');
  Writeln('--------------------------------------------------------------------------------------');
  Writeln('Use SendMail.exe [/S] [/P] [/T] [/F] [/B] [/A] [/M] [/L] [/TLS]');
  Writeln('-------------------------------------------------------------------------------------');
  Writeln('Delimit the data of the parameters with double quotes when you need to include spaces');
  Writeln('-------------------------------------------------------------------------------------');
  Writeln('/H     Show this report');
  Writeln('/S     SMTP Server Name');
  Writeln('/P     SMTP Port Number (optional, default 25)');
  Writeln('/T     To: Address (Use ; token for multiple values)');
  Writeln('/F     From:Address');
  Writeln('/B     Body text of message (Optional, will be encapsulated in html format)');
  Writeln('/A     Subject (mandatory)');
  Writeln('/M     Attachments (Use ; token for multiple values)');
  Writeln('/L     Login (Required, use user@password)');
  Writeln('/TLS   Use TLS Security (Optional)');
  Writeln('/Q     Works in quiet mode, no message will be shown in stdout');
end;

procedure SendEmail;
var
  Correo: TIdSMTP;
  MailMessage: TIdMessage;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  i: integer;
  Arr: TArray<String>;
begin
  SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Correo := TIdSMTP.Create(nil);
  MailMessage := TIdMessage.Create(nil);
  try
    try
      Correo.IOHandler := nil;
      Correo.UseTLS := TIdUseTLS.utNoTLSSupport;
      if TLS then
      begin
        SSL.Host := Servidor;
        SSL.Port := StrToIntDef(Port, 25);
        SSL.ReuseSocket := rsTrue;
        SSL.SSLOptions.Method := sslvSSLv23;
        SSL.SSLOptions.Mode := sslmClient;
        SSL.Destination := Servidor + ':' + Port;
        Correo.IOHandler := SSL;
        Correo.UseTLS := TIdUseTLS.utUseExplicitTLS;
      end;
      Correo.AuthType := satDefault;
      Correo.Host := Servidor;
      Correo.Port := StrToIntDef(Port, 25);
      if Login <> '' then
      begin
        Arr := TRegEx.Split(Login, '\:');
        if Length(Arr) = 2 then
        begin
          Correo.UserName := Arr[0];
          Correo.Password := Arr[1];
        end;
      end;

      MailMessage.From.Address := FromAddr;
      MailMessage.Recipients.EMailAddresses := ToAddr;
      MailMessage.Subject := Subject;

      with TIdText.Create(MailMessage.MessageParts, nil) do
      begin
        Body.Clear;
        Body.Add('<html><body><p>' + ABody + '</p><p> Mail sent by Emite Networks SendMail application </p></body></html>');
        ContentType := 'text/html';
      end;

      if Attachments <> '' then
      begin
        Arr := TRegEx.Split(Attachments, '\;');
        for i := 0 to Length(Arr) - 1 do
        begin
          if FileExists(Arr[i]) then
            TIdAttachmentFile.Create(MailMessage.MessageParts, Arr[i]);
        end;
      end;
      Correo.ConnectTimeout := 5000;
      Correo.Connect;
      if Correo.Authenticate then
      begin
        Correo.Send(MailMessage);
        if not Quiet then
          Writeln('email sent to ' + ToAddr + ' sucessfuly');
      end
      else if not Quiet then
        Writeln('Error: email could not be sent');
    except
      on e: Exception do
      begin
        if not Quiet then
          Writeln('Exception:' + e.Message);
        if Correo.Connected then
          Correo.Disconnect;
      end;
    end;
  finally
    if Correo.Connected then
      Correo.Disconnect;
    Correo.Free;
    MailMessage.Free;
    SSL.Free;
  end;
end;

begin
  try
    TLS := False;
    Port := '25';
    Login := '';
    Attachments := '';
    Quiet := False;
    for i := 1 to ParamCount do
    begin
      if Odd(i) then
      begin
        if UpperCase(ParamStr(i)) = '/S' then
          Servidor := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/P' then
          Port := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/T' then
          ToAddr := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/F' then
          FromAddr := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/B' then
          ABody := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/A' then
          Subject := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/M' then
          Attachments := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/L' then
          Login := ParamStr(i + 1)
        else if UpperCase(ParamStr(i)) = '/TLS' then
          TLS := True
        else if UpperCase(ParamStr(i)) = '/Q' then
          Quiet := True
        else if UpperCase(ParamStr(i)) = '/H' then
        begin
          if not Quiet then
            ShowHelp;
          Exit;
        end
        else
        begin
          if not Quiet then
          begin
            Writeln('unkonwn parameter: ' + UpperCase(ParamStr(i)));
            ShowHelp;
          end;
          Exit;
        end;
      end;
    end;
    if (Servidor <> '') and (FromAddr <> '') and (ToAddr <> '') and (Subject <> '') and (Subject <> '') then
      SendEmail
    else if not Quiet then
      Writeln('Error: some required parameters are missing');
  except
    on e: Exception do
      Writeln(e.ClassName, ': ', e.Message);
  end;

end.
