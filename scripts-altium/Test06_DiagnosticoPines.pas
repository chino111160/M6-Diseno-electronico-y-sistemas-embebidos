{..............................................................................}
{ Test06_DiagnosticoPines.pas                                                 }
{ Hipotesis: los 4 pines "fantasma" en realidad son 2 pines x 2              }
{ representaciones graficas (Normal vs Alternate/DeMorgan) del mismo          }
{ componente. Este script imprime OwnerPartId y OwnerPartDisplayMode de cada  }
{ pin encontrado para confirmar o descartar esto.                             }
{..............................................................................}

Procedure DiagnosticoPines;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    Iterator : ISch_Iterator;
    Pin      : ISch_Pin;
    Msg      : String;
    PartInfo : String;
    ModeInfo : String;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;

    If Doc = Nil Then
    Begin
        ShowMessage('No hay ningun documento activo/enfocado.');
        Exit;
    End;

    If Doc.DM_DocumentKind <> 'SCH' Then
    Begin
        ShowMessage('El documento activo no es un esquema. Es: ' + Doc.DM_DocumentKind);
        Exit;
    End;

    SchDoc := SchServer.GetCurrentSchDocument;

    If SchDoc = Nil Then
    Begin
        ShowMessage('No pude obtener el ISch_Document actual.');
        Exit;
    End;

    Msg := '';

    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(ePin));

    Pin := Iterator.FirstSchObject;
    While Pin <> Nil Do
    Begin
        PartInfo := '?';
        ModeInfo := '?';

        Try
            PartInfo := IntToStr(Pin.OwnerPartId);
        Except
            PartInfo := '(sin OwnerPartId)';
        End;

        Try
            ModeInfo := IntToStr(Pin.OwnerPartDisplayMode);
        Except
            ModeInfo := '(sin OwnerPartDisplayMode)';
        End;

        Msg := Msg + 'Pin ' + Pin.Designator + '  PartId=' + PartInfo + '  DisplayMode=' + ModeInfo +
               '  en (' + IntToStr(CoordToMils(Pin.Location.X)) + ', ' + IntToStr(CoordToMils(Pin.Location.Y)) + ')' + #13#10;

        Pin := Iterator.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(Iterator);

    If Msg = '' Then
        Msg := 'No se encontraron pines.';

    ShowMessage(Msg);
End;
