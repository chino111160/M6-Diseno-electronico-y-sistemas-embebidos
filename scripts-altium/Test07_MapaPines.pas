{..............................................................................}
{ Test07_MapaPines.pas                                                        }
{ Para el esquema del ejemplo 03 (10 componentes reales). Primero junta la    }
{ posicion (Location) de cada componente, despues recorre todos los Pin del   }
{ documento (filtrando DisplayMode=0, la representacion real) y le asigna a   }
{ cada pin el componente mas cercano por distancia. Evita usar iteradores     }
{ anidados (que vimos que no escalan bien) y no depende de Pin.Owner (que no  }
{ existe).                                                                     }
{..............................................................................}

Procedure MapaPines;
Var
    Doc        : IServerDocument;
    SchDoc     : ISch_Document;
    CompIter   : ISch_Iterator;
    PinIter    : ISch_Iterator;
    Comp       : ISch_Component;
    Pin        : ISch_Pin;
    Msg        : String;

    CompDes    : Array[0..49] Of String;
    CompX      : Array[0..49] Of Integer;
    CompY      : Array[0..49] Of Integer;
    CompCount  : Integer;

    PinX, PinY : Integer;
    BestIdx    : Integer;
    BestDist   : Integer;
    Dist       : Integer;
    Dx, Dy     : Integer;
    i          : Integer;
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

    { Paso 1: juntar todos los componentes y su Location }
    CompCount := 0;

    CompIter := SchDoc.SchIterator_Create;
    CompIter.AddFilter_ObjectSet(MkSet(eSchComponent));

    Comp := CompIter.FirstSchObject;
    While Comp <> Nil Do
    Begin
        CompDes[CompCount] := Comp.Designator.Text;
        CompX[CompCount]   := Comp.Location.X;
        CompY[CompCount]   := Comp.Location.Y;
        CompCount := CompCount + 1;

        Comp := CompIter.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(CompIter);

    { Paso 2: recorrer los pines reales (DisplayMode=0) y asignar el componente mas cercano }
    Msg := 'Componentes encontrados: ' + IntToStr(CompCount) + #13#10#13#10;

    PinIter := SchDoc.SchIterator_Create;
    PinIter.AddFilter_ObjectSet(MkSet(ePin));

    Pin := PinIter.FirstSchObject;
    While Pin <> Nil Do
    Begin
        If Pin.OwnerPartDisplayMode = 0 Then
        Begin
            PinX := Pin.Location.X;
            PinY := Pin.Location.Y;

            BestIdx  := -1;
            BestDist := -1;

            For i := 0 To CompCount - 1 Do
            Begin
                Dx := PinX - CompX[i];
                Dy := PinY - CompY[i];
                Dist := (Dx * Dx) + (Dy * Dy);

                If (BestDist = -1) Or (Dist < BestDist) Then
                Begin
                    BestDist := Dist;
                    BestIdx  := i;
                End;
            End;

            If BestIdx >= 0 Then
                Msg := Msg + CompDes[BestIdx] + '.' + Pin.Designator + '  (' + Pin.Name + ')  en (' +
                       IntToStr(CoordToMils(PinX)) + ', ' + IntToStr(CoordToMils(PinY)) + ')' + #13#10
            Else
                Msg := Msg + '(sin owner)  Pin ' + Pin.Designator + #13#10;
        End;

        Pin := PinIter.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(PinIter);

    ShowMessage(Msg);
End;
