{..............................................................................}
{ Test02_CrearHilo.pas (v3)                                                   }
{ Tercer intento: usa eCreate_GlobalCopy + InsertVertex/SetState_Vertex +     }
{ SchServer.ProcessControl.PreProcess/PostProcess, segun documentacion real   }
{ encontrada (no solo memoria). Crea un wire en el esquema activo.            }
{..............................................................................}

Procedure CrearHilo;
Var
    Doc      : IServerDocument;
    SchDoc   : ISch_Document;
    NewWire  : ISch_Wire;
Begin
    Doc := GetWorkSpace.DM_FocusedDocument;

    If Doc = Nil Then
    Begin
        ShowMessage('No hay ningun documento activo/enfocado.');
        Exit;
    End;

    If Doc.DM_DocumentKind <> 'SCH' Then
    Begin
        ShowMessage('El documento activo no es un esquema (SCH). Es: ' + Doc.DM_DocumentKind + #13#10 +
                    'Abri Scratch.SchDoc y hacele click para que quede enfocado, despues corre este script de nuevo.');
        Exit;
    End;

    SchDoc := SchServer.GetCurrentSchDocument;

    If SchDoc = Nil Then
    Begin
        ShowMessage('No pude obtener el ISch_Document actual via SchServer.GetCurrentSchDocument.');
        Exit;
    End;

    SchServer.ProcessControl.PreProcess(SchDoc, '');

    NewWire := SchServer.SchObjectFactory(eWire, eCreate_GlobalCopy);

    If NewWire = Nil Then
    Begin
        SchServer.ProcessControl.PostProcess(SchDoc, '');
        ShowMessage('SchObjectFactory devolvio Nil al crear el Wire.');
        Exit;
    End;

    NewWire.LineWidth := eSmall;
    NewWire.Color     := $00FF0000;

    NewWire.Location  := Point(MilsToCoord(1000), MilsToCoord(1000));

    NewWire.InsertVertex := 1;
    NewWire.SetState_Vertex(1, Point(MilsToCoord(1000), MilsToCoord(1000)));

    NewWire.InsertVertex := 2;
    NewWire.SetState_Vertex(2, Point(MilsToCoord(2000), MilsToCoord(1000)));

    SchDoc.RegisterSchObjectInContainer(NewWire);

    SchServer.ProcessControl.PostProcess(SchDoc, '');

    SchDoc.GraphicallyInvalidate;

    ShowMessage('Wire creado (v3) OK entre (1000,1000) y (2000,1000) mil.' + #13#10 +
                'Corre Test03_ContarWires para confirmar.');
End;
