{..............................................................................}
{ Test05_PinesDirecto.pas                                                     }
{ En vez de anidar iteradores (Componente -> sus Pines), iteramos los Pin     }
{ directamente a nivel del documento completo, y para cada uno preguntamos    }
{ quien es su componente dueno. Evita el problema de iteradores anidados      }
{ que vimos en Test04.                                                        }
{..............................................................................}

Procedure PinesDirecto;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    Iterator : ISch_Iterator;
    Pin      : ISch_Pin;
    Msg      : String;
    OwnerDes : String;
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
        Msg := Msg + 'Pin ' + Pin.Designator + '  (' + Pin.Name + ')' +
               '  en (' + IntToStr(CoordToMils(Pin.Location.X)) + ', ' + IntToStr(CoordToMils(Pin.Location.Y)) + ') mil' + #13#10;

        Pin := Iterator.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(Iterator);

    If Msg = '' Then
        Msg := 'No se encontraron pines a nivel de documento (puede que los pines no sean primitivas de primer nivel).';

    ShowMessage(Msg);
End;
