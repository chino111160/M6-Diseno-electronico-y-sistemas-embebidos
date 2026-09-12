{..............................................................................}
{ Test03_ContarWires.pas                                                      }
{ Diagnostico: cuenta cuantos objetos Wire existen realmente en el esquema    }
{ activo, usando SchIterator (patron mas robusto que manipular el objeto      }
{ directo). Nos dice si el wire del Test02 realmente quedo registrado.        }
{..............................................................................}

Procedure ContarWires;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    Iterator : ISch_Iterator;
    Obj      : ISch_GraphicalObject;
    Count    : Integer;
    CountTodo : Integer;
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

    SchDoc := SchServer.GetSchDocumentByPath(Doc.DM_FullPath);

    If SchDoc = Nil Then
    Begin
        ShowMessage('No pude obtener el ISch_Document via SchServer.');
        Exit;
    End;

    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eWire));

    Count := 0;
    Obj := Iterator.FirstSchObject;
    While Obj <> Nil Do
    Begin
        Count := Count + 1;
        Obj := Iterator.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(Iterator);

    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(AllObjects);

    CountTodo := 0;
    Obj := Iterator.FirstSchObject;
    While Obj <> Nil Do
    Begin
        CountTodo := CountTodo + 1;
        Obj := Iterator.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(Iterator);

    ShowMessage('Objetos Wire encontrados: ' + IntToStr(Count) + #13#10 +
                'Objetos TOTALES (cualquier tipo) encontrados: ' + IntToStr(CountTodo));
End;
