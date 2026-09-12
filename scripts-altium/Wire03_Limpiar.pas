{..............................................................................}
{ Wire03_Limpiar.pas                                                          }
{ Busca y borra cualquier Wire cuyo vertice caiga fuera de un rango razonable }
{ (posible cable perdido creado por error). Rango normal de este esquema:     }
{ X entre 0 y 5000 mil, Y entre 0 y 8000 mil aprox. Usamos margen generoso.   }
{..............................................................................}

Procedure Limpiar;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    Iterator : ISch_Iterator;
    W        : ISch_Wire;
    i        : Integer;
    vx, vy   : Integer;
    FueraDeRango : Boolean;
    Borrados : Integer;
    Msg      : String;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;
    If Doc = Nil Then Begin ShowMessage('No hay documento activo.'); Exit; End;
    If Doc.DM_DocumentKind <> 'SCH' Then Begin ShowMessage('No es un esquema. Es: ' + Doc.DM_DocumentKind); Exit; End;

    SchDoc := SchServer.GetCurrentSchDocument;
    If SchDoc = Nil Then Begin ShowMessage('No pude obtener el documento actual.'); Exit; End;

    Borrados := 0;
    Msg := '';

    Iterator := SchDoc.SchIterator_Create;
    Iterator.AddFilter_ObjectSet(MkSet(eWire));

    W := Iterator.FirstSchObject;
    While W <> Nil Do
    Begin
        FueraDeRango := False;

        For i := 1 To W.VerticesCount Do
        Begin
            vx := CoordToMils(W.Vertex[i].X);
            vy := CoordToMils(W.Vertex[i].Y);

            If (vx < -500) Or (vx > 5000) Or (vy < -500) Or (vy > 7500) Then
                FueraDeRango := True;
        End;

        If FueraDeRango Then
        Begin
            Msg := Msg + 'Wire fuera de rango borrado, vertices: ';
            For i := 1 To W.VerticesCount Do
                Msg := Msg + '(' + IntToStr(CoordToMils(W.Vertex[i].X)) + ',' + IntToStr(CoordToMils(W.Vertex[i].Y)) + ') ';
            Msg := Msg + #13#10;

            SchDoc.RemoveSchObject(W);
            Borrados := Borrados + 1;
        End;

        W := Iterator.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(Iterator);

    SchDoc.GraphicallyInvalidate;

    If Msg = '' Then
        Msg := 'No se encontro ningun wire fuera de rango.'
    Else
        Msg := Msg + #13#10 + 'Total borrados: ' + IntToStr(Borrados);

    ShowMessage(Msg);
End;
