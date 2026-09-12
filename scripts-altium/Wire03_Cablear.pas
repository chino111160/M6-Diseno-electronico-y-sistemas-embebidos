{..............................................................................}
{ Wire03_Cablear.pas                                                          }
{ Cablea el esquema completo del ejemplo 03 (fuente lineal regulada 7805).    }
{ Coordenadas de pines reales, deducidas manualmente a partir de la salida    }
{ de Test07_MapaPines.pas (nombres de pin: A/K para diodos, IN/GND/OUT para   }
{ el regulador, 1/2 genericos). 16 segmentos de wire agrupados en 5 nets:     }
{ VIN, VIN_REG (post-diodo), GND, VOUT, y el lazo del LED indicador.          }
{..............................................................................}

Procedure Cablear;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    NewWire  : ISch_Wire;
    X1, Y1, X2, Y2 : Array[0..15] Of Integer;
    WColor   : Array[0..15] Of Integer;
    i        : Integer;
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

    { --- NET: VIN (rojo) --- }
    X1[0]:=1200; Y1[0]:=6500; X2[0]:=1200; Y2[0]:=5100; WColor[0]:=$000000FF; { P1.1 -- DS2.1(A) }

    { --- NET: VIN_REG, post-diodo (verde) --- }
    X1[1]:=1300; Y1[1]:=5100; X2[1]:=1200; Y2[1]:=4300; WColor[1]:=$0000FF00; { DS2.2(K) -- C2.1 }
    X1[2]:=1200; Y1[2]:=4300; X2[2]:=1200; Y2[2]:=3600; WColor[2]:=$0000FF00; { C2.1 -- C3.1 }
    X1[3]:=1200; Y1[3]:=3600; X2[3]:=3400; Y2[3]:=3300; WColor[3]:=$0000FF00; { C3.1 -- U1.IN }

    { --- NET: GND (negro) --- }
    X1[4]:=1200; Y1[4]:=6400; X2[4]:=1300; Y2[4]:=4300; WColor[4]:=$00000000; { P1.2 -- C2.2 }
    X1[5]:=1300; Y1[5]:=4300; X2[5]:=1300; Y2[5]:=3600; WColor[5]:=$00000000; { C2.2 -- C3.2 }
    X1[6]:=1300; Y1[6]:=3600; X2[6]:=3700; Y2[6]:=3100; WColor[6]:=$00000000; { C3.2 -- U1.GND }
    X1[7]:=3700; Y1[7]:=3100; X2[7]:=3500; Y2[7]:=6700; WColor[7]:=$00000000; { U1.GND -- C1.2 }
    X1[8]:=3500; Y1[8]:=6700; X2[8]:=1300; Y2[8]:=2700; WColor[8]:=$00000000; { C1.2 -- C4.2 }
    X1[9]:=1300; Y1[9]:=2700; X2[9]:=3500; Y2[9]:=4300; WColor[9]:=$00000000; { C4.2 -- P2.2 }
    X1[10]:=3500; Y1[10]:=4300; X2[10]:=3500; Y2[10]:=5900; WColor[10]:=$00000000; { P2.2 -- DS1.2(K) }

    { --- NET: VOUT (azul) --- }
    X1[11]:=4000; Y1[11]:=3300; X2[11]:=3400; Y2[11]:=6700; WColor[11]:=$00FF0000; { U1.OUT -- C1.1 }
    X1[12]:=3400; Y1[12]:=6700; X2[12]:=1200; Y2[12]:=2700; WColor[12]:=$00FF0000; { C1.1 -- C4.1 }
    X1[13]:=1200; Y1[13]:=2700; X2[13]:=3500; Y2[13]:=4400; WColor[13]:=$00FF0000; { C4.1 -- P2.1 }
    X1[14]:=3500; Y1[14]:=4400; X2[14]:=3400; Y2[14]:=5200; WColor[14]:=$00FF0000; { P2.1 -- R1.1 }

    { --- NET: LED (magenta) --- }
    X1[15]:=3700; Y1[15]:=5200; X2[15]:=3400; Y2[15]:=5900; WColor[15]:=$00FF00FF; { R1.2 -- DS1.1(A) }

    SchServer.ProcessControl.PreProcess(SchDoc, '');

    For i := 0 To 15 Do
    Begin
        NewWire := SchServer.SchObjectFactory(eWire, eCreate_GlobalCopy);

        NewWire.LineWidth := eSmall;
        NewWire.Color     := WColor[i];

        NewWire.InsertVertex := 1;
        NewWire.SetState_Vertex(1, Point(MilsToCoord(X1[i]), MilsToCoord(Y1[i])));

        NewWire.InsertVertex := 2;
        NewWire.SetState_Vertex(2, Point(MilsToCoord(X2[i]), MilsToCoord(Y2[i])));

        SchDoc.RegisterSchObjectInContainer(NewWire);
    End;

    SchServer.ProcessControl.PostProcess(SchDoc, '');

    SchDoc.GraphicallyInvalidate;

    ShowMessage('16 wires creados. Revisa el esquema y despues corre Project -> Validate PCB Project (ERC).');
End;
