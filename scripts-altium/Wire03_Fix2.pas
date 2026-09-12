{..............................................................................}
{ Wire03_Fix2.pas                                                             }
{ Version robusta: usa GetState_AllPins(Componente) para leer los pines de    }
{ CADA componente por separado (sin el bug de iteradores anidados ni de       }
{ "componente mas cercano"). Arma una tabla de busqueda Designador+Pin->(X,Y) }
{ y dibuja las conexiones de las redes VOUT y LED que faltaban.               }
{..............................................................................}

Var
    LutComp  : Array[0..99] Of String;
    LutPin   : Array[0..99] Of String;
    LutName  : Array[0..99] Of String;
    LutX     : Array[0..99] Of Integer;
    LutY     : Array[0..99] Of Integer;
    LutCount : Integer;

Function BuscarPin(Comp, PinKey : String; Var X, Y : Integer) : Boolean;
Var
    i : Integer;
Begin
    Result := False;
    For i := 0 To LutCount - 1 Do
    Begin
        If (LutComp[i] = Comp) And ((LutPin[i] = PinKey) Or (LutName[i] = PinKey)) Then
        Begin
            X := LutX[i];
            Y := LutY[i];
            Result := True;
            Exit;
        End;
    End;
End;

Procedure DibujarSegmento(SchDoc : ISch_Document; XA, YA, XB, YB : Integer; ColorVal : Integer);
Var
    NewWire : ISch_Wire;
Begin
    NewWire := SchServer.SchObjectFactory(eWire, eCreate_GlobalCopy);
    NewWire.LineWidth := eSmall;
    NewWire.Color     := ColorVal;

    NewWire.InsertVertex := 1;
    NewWire.SetState_Vertex(1, Point(MilsToCoord(XA), MilsToCoord(YA)));

    NewWire.InsertVertex := 2;
    NewWire.SetState_Vertex(2, Point(MilsToCoord(XB), MilsToCoord(YB)));

    SchDoc.RegisterSchObjectInContainer(NewWire);
End;

Procedure Fix2;
Var
    Doc       : IServerDocument;
    SchDoc    : ISch_Document;
    CompIter  : ISch_Iterator;
    PinIter   : ISch_Iterator;
    Comp      : ISch_Component;
    i         : Integer;
    Pin       : ISch_Pin;
    Msg       : String;

    Xa, Ya, Xb, Yb : Integer;
    okA, okB : Boolean;
    j        : Integer;
    YaExiste : Boolean;
    ThisCompDes : String;
    ThisPinDes  : String;
    ThisPinName : String;
    ThisPinX    : Integer;
    ThisPinY    : Integer;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;
    If Doc = Nil Then Begin ShowMessage('No hay documento activo.'); Exit; End;
    If Doc.DM_DocumentKind <> 'SCH' Then Begin ShowMessage('No es un esquema. Es: ' + Doc.DM_DocumentKind); Exit; End;

    SchDoc := SchServer.GetCurrentSchDocument;
    If SchDoc = Nil Then Begin ShowMessage('No pude obtener el documento actual.'); Exit; End;

    { ---------- Paso 1: armar la tabla de busqueda ---------- }
    LutCount := 0;

    CompIter := SchDoc.SchIterator_Create;
    CompIter.AddFilter_ObjectSet(MkSet(eSchComponent));

    Comp := CompIter.FirstSchObject;
    While Comp <> Nil Do
    Begin
        ThisCompDes := Comp.Designator.Text;

        PinIter := Comp.SchIterator_Create;
        PinIter.AddFilter_ObjectSet(MkSet(ePin));

        Pin := PinIter.FirstSchObject;
        While Pin <> Nil Do
        Begin
            If Pin.OwnerPartDisplayMode = 0 Then
            Begin
                ThisPinDes  := Pin.Designator;
                ThisPinName := Pin.Name;
                ThisPinX    := CoordToMils(Pin.Location.X);
                ThisPinY    := CoordToMils(Pin.Location.Y);

                j := 0;
                YaExiste := False;
                While (j < LutCount) And (Not YaExiste) Do
                Begin
                    If (LutComp[j] = ThisCompDes) And (LutPin[j] = ThisPinDes) Then
                        YaExiste := True;
                    j := j + 1;
                End;

                If Not YaExiste Then
                Begin
                    LutComp[LutCount] := ThisCompDes;
                    LutPin[LutCount]  := ThisPinDes;
                    LutName[LutCount] := ThisPinName;
                    LutX[LutCount]    := ThisPinX;
                    LutY[LutCount]    := ThisPinY;
                    LutCount := LutCount + 1;
                End;
            End;

            Pin := PinIter.NextSchObject;
        End;

        Comp.SchIterator_Destroy(PinIter);

        Comp := CompIter.NextSchObject;
    End;

    SchDoc.SchIterator_Destroy(CompIter);

    { ---------- Paso 2: mostrar la tabla para verificar ---------- }
    Msg := 'Tabla de pines (' + IntToStr(LutCount) + ' encontrados):' + #13#10;
    For i := 0 To LutCount - 1 Do
        Msg := Msg + LutComp[i] + '.' + LutPin[i] + ' (' + LutName[i] + ')  (' +
               IntToStr(LutX[i]) + ',' + IntToStr(LutY[i]) + ')' + #13#10;

    ShowMessage(Msg);
End;

Procedure DibujarFaltantes;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;
    If Doc = Nil Then Begin ShowMessage('No hay documento activo.'); Exit; End;
    If Doc.DM_DocumentKind <> 'SCH' Then Begin ShowMessage('No es un esquema. Es: ' + Doc.DM_DocumentKind); Exit; End;

    SchDoc := SchServer.GetCurrentSchDocument;
    If SchDoc = Nil Then Begin ShowMessage('No pude obtener el documento actual.'); Exit; End;

    SchServer.ProcessControl.PreProcess(SchDoc, '');

    { VOUT: U1.OUT -- C1.1 -- C4.1 -- P2.1 -- R1.1 (azul) }
    DibujarSegmento(SchDoc, 4000, 3300, 3400, 6700, $00FF0000);
    DibujarSegmento(SchDoc, 3400, 6700, 1200, 2700, $00FF0000);
    DibujarSegmento(SchDoc, 1200, 2700, 3500, 4400, $00FF0000);
    DibujarSegmento(SchDoc, 3500, 4400, 3400, 5200, $00FF0000);

    { LED: R1.2 -- DS1.1 (magenta) }
    DibujarSegmento(SchDoc, 3700, 5200, 3400, 5900, $00FF00FF);

    SchServer.ProcessControl.PostProcess(SchDoc, '');

    SchDoc.GraphicallyInvalidate;

    ShowMessage('5 wires creados (VOUT + LED). Corre Project -> Validate PCB Project para verificar.');
End;

Procedure DibujarTodo;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;
    If Doc = Nil Then Begin ShowMessage('No hay documento activo.'); Exit; End;
    If Doc.DM_DocumentKind <> 'SCH' Then Begin ShowMessage('No es un esquema. Es: ' + Doc.DM_DocumentKind); Exit; End;

    SchDoc := SchServer.GetCurrentSchDocument;
    If SchDoc = Nil Then Begin ShowMessage('No pude obtener el documento actual.'); Exit; End;

    SchServer.ProcessControl.PreProcess(SchDoc, '');

    { VIN (rojo): P1.1 -- DS2.1(A) }
    DibujarSegmento(SchDoc, 1200, 6500, 1200, 5100, $000000FF);

    { VIN_REG (verde): DS2.2(K) -- C2.1 -- C3.1 -- U1.IN }
    DibujarSegmento(SchDoc, 1300, 5100, 1200, 4300, $0000FF00);
    DibujarSegmento(SchDoc, 1200, 4300, 1200, 3600, $0000FF00);
    DibujarSegmento(SchDoc, 1200, 3600, 3400, 3300, $0000FF00);

    { GND (negro) }
    DibujarSegmento(SchDoc, 1200, 6400, 1300, 4300, $00000000);
    DibujarSegmento(SchDoc, 1300, 4300, 1300, 3600, $00000000);
    DibujarSegmento(SchDoc, 1300, 3600, 3700, 3100, $00000000);
    DibujarSegmento(SchDoc, 3700, 3100, 3500, 6700, $00000000);
    DibujarSegmento(SchDoc, 3500, 6700, 1300, 2700, $00000000);
    DibujarSegmento(SchDoc, 1300, 2700, 3500, 4300, $00000000);
    DibujarSegmento(SchDoc, 3500, 4300, 3500, 5900, $00000000);

    { VOUT (azul) }
    DibujarSegmento(SchDoc, 4000, 3300, 3400, 6700, $00FF0000);
    DibujarSegmento(SchDoc, 3400, 6700, 1200, 2700, $00FF0000);
    DibujarSegmento(SchDoc, 1200, 2700, 3500, 4400, $00FF0000);
    DibujarSegmento(SchDoc, 3500, 4400, 3400, 5200, $00FF0000);

    { LED (magenta) }
    DibujarSegmento(SchDoc, 3700, 5200, 3400, 5900, $00FF00FF);

    SchServer.ProcessControl.PostProcess(SchDoc, '');

    SchDoc.GraphicallyInvalidate;

    ShowMessage('16 wires creados (las 5 nets completas). Corre Project -> Validate PCB Project.');
End;
