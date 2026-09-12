{..............................................................................}
{ Test04_LeerPines.pas                                                        }
{ Recorre todos los componentes del esquema activo y, para cada uno, lista    }
{ sus pines con nombre/numero y posicion absoluta (en mils). Si esto funciona,}
{ podemos ubicar automaticamente los pines de cualquier componente ya         }
{ colocado, sin importar donde ni como lo hayas rotado, para despues dibujar  }
{ wires entre ellos por script.                                               }
{..............................................................................}

Procedure LeerPines;
Var
    Doc       : IServerDocument;
    SchDoc    : ISch_Document;
    CompIter  : ISch_Iterator;
    PinIter   : ISch_Iterator;
    Comp      : ISch_Component;
    Pin       : ISch_Pin;
    Msg       : String;
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

    CompIter := SchDoc.SchIterator_Create;
    CompIter.AddFilter_ObjectSet(MkSet(eSchComponent));

    Comp := CompIter.FirstSchObject;
    While Comp <> Nil Do
    Begin
        Msg := Msg + 'Componente: ' + Comp.Designator.Text + '  (LibRef: ' + Comp.LibReference + ')' + #13#10;

        PinIter := Comp.SchIterator_Create;
        PinIter.AddFilter_ObjectSet(MkSet(ePin));

        Pin := PinIter.FirstSchObject;
        While Pin <> Nil Do
        Begin
            Msg := Msg + '   Pin ' + Pin.Designator + '  (' + Pin.Name + ')  en (' +
                   IntToStr(CoordToMils(Pin.Location.X)) + ', ' + IntToStr(CoordToMils(Pin.Location.Y)) + ') mil' + #13#10;
            Pin := PinIter.NextSchObject;
        End;

        Comp.SchIterator_Destroy(PinIter);

        Comp := CompIter.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(CompIter);

    If Msg = '' Then
        Msg := 'No se encontraron componentes en el documento.';

    ShowMessage(Msg);
End;
