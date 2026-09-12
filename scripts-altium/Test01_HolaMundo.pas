{..............................................................................}
{ Test01_HolaMundo.pas                                                        }
{ Primer script de prueba: solo confirma que el motor de scripting de Altium  }
{ Designer funciona y que podemos leer el documento activo. No modifica nada. }
{..............................................................................}

Procedure HolaMundo;
Var
    Doc : IServerDocument;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;

    If Doc = Nil Then
    Begin
        ShowMessage('No hay ningun documento activo/enfocado.');
        Exit;
    End;

    ShowMessage('Script corriendo OK.' + #13#10 +
                'Documento activo: ' + Doc.DM_FullPath + #13#10 +
                'Tipo: ' + Doc.DM_DocumentKind);
End;
