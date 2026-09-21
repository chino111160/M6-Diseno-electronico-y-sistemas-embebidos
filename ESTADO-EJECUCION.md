# Estado de ejecución de los ejemplos 01–08 (20-sep-2026)

Todos los proyectos se abren con Altium Designer 26.10.1. Cada carpeta trae su
`.PrjPcb`, esquemas `.SchDoc`, `PCBn.PcbDoc`, la carpeta `Project Outputs for …`
(reporte DRC, Gerbers, taladro NC) y, desde el 04, un `BOM_ejemploNN.csv`.
Los respaldos previos a las correcciones están en `../ejemplos_respaldo_2026-09-20/`
(01, 02 y 03).

| # | Estado | Resultado verificado |
|---|---|---|
| 01 | Corregido | Designadores R1/D1/J1, net labels VCC/GND, contorno 20×15 mm (antes 152×102 mm y componentes fuera de la placa), ECO, DRC solo 2 avisos de serigrafía, Gerbers y taladro regenerados |
| 02 | Corregido | Faltaba conectar J2.2 a GND (red de 3 pines, objetivo del ejemplo): cableado y rutado; R1/C1 anotados; etiquetas IN/OUT/GND; el `.PrjPcb` apuntaba a un `Sheet2.SchDoc` en OneDrive que no existe (repuntado); DRC 4 avisos de serigrafía |
| 03 | Completo | Netlist correcto (se conservó el del usuario), clase de nets Power + regla 25 mil, autorruteo, plano GND inferior, DRC 0 clearance / 0 corto / 0 sin rutar (14 avisos de serigrafía), Gerbers, nota térmica (200 mA, Pd 0,8 W, Tj 77 °C) en el esquema. Falta la variante LM317 |
| 04 | Completo | 74HC14 (símbolo propio, 6 compuertas + parte de alimentación), RC 10 k × 100 nF, ERC sin errores, DRC 0 eléctricos, Gerbers, `reglas-basicas.RUL` exportado |
| 05 | Completo | Ver "desviaciones"; DRC 0 eléctricos, Gerbers |
| 06 | Completo | Top + Power + Channel (Channel instanciado 2 veces: `R10_Channel1/2`), 3 Rooms, ERC 0 errores, ruteo 37/37, DRC 0 eléctricos, Gerbers |
| 07 | Completo | STM32F103C8T6 (símbolo propio, LQFP48 generado con el asistente IPC), pila de 4 capas con planos GND y 3V3, reglas tipo fabricante, DRC 0 clearance / corto / sin rutar / agujeros, Gerbers de 4 capas, taladro, Pick&Place |
| 08 | Hecho con límites | Ver abajo |

## Desviaciones respecto de las guías (importante)

* **04 – pines ocultos.** Los pines VCC/GND ocultos del 74HC14 no se conectaban
  solos en el archivo generado; se dibujó una "parte G" de alimentación visible
  y conectada a las nets VCC/GND. El resto del ejemplo sigue la guía.
* **05 – topología.** El esquema de la guía mezcla un no inversor con el acople
  por la entrada inversora (no funciona como dice). Se dejó un amplificador
  **inversor** referido a Vref (ganancia −10, fc = 159 Hz, −3 dB de 160 Hz a
  271 kHz, verificado con un cálculo analítico) y se añadió un conector de
  alimentación J3 que la BOM no traía. **No se corrió la simulación SPICE ni
  se creó el ActiveBOM dentro de Altium.**
* **05/06/07/08 – librerías.** Se usaron los símbolos/footprints de las
  librerías instaladas (Miscellaneous Devices/Connectors). Símbolos propios:
  74HC14, TL072, MCP6004, AMS1117, BAT54S, IRLZ44N, STM32F103C8T6. Los
  footprints propios son LQFP48 (IPC wizard), y los de las librerías genéricas
  para el resto (SO8, SOT-223, TO-220…): son de aprendizaje, no de producción.
* **07 – no hechos:** Draftsman y revisión 3D.

## Ejemplo 08 (capstone) – qué está y qué no

Hecho: jerarquía Top + Power + Input (×4, multicanal) + Analog + Driver + Mcu,
PCB de 100 × 80 mm con 95 componentes y 199 conexiones, 8 Rooms, reglas
tipo fabricante, autorruteo (182/182 conexiones intentadas), plano GND en
Bottom y Top, Gerbers, taladro y Pick&Place, BOM (`BOM_ejemplo08.csv`,
un canal Input representa los 4).

Límites reales que conviene saber:

* **Mapa de pines, presupuesto de corriente y análisis térmico** vienen de la
  guía y quedaron anotados en las hojas; no se recalcularon.
* **Analog e Input:** ANALOG_IN y ANALOG_OUT comparten el MCP6004 (multi-parte),
  por eso van en una sola hoja `Analog.SchDoc`.
* **DRC final:** 0 clearance, 0 cortos, 0 agujeros; **queda 1 conexión de GND
  sin unir** (J2-1 con una pista inferior), 4 avisos de "máscara de soldadura
  < 4 mil" y ~115 avisos de serigrafía. La regla Silk-to-Silk se dejó activada:
  con ella, el DRC de Altium se detiene a los 500 avisos (texto de designadores
  encimado por la ubicación automática). Se generó el reporte final con esa
  regla desactivada para poder ver el resto; se volvió a activar después.
* **No se ejecutaron:** Output Job, Project Releaser, variantes de ensamblaje,
  Draftsman, bring-up ni design review (son pasos de proceso, no de archivos).
* **Antes de fabricar de verdad:** cerrar el GND pendiente a mano, revisar
  footprints reales (TO-220, SOT-223, LED, conectores) y la ubicación
  (el autoubicador solo agrupó por Room).

## Cómo se generaron

Los `.SchDoc` y `.PcbDoc` se generaron/editaron a nivel de archivo (scripts en
la sesión) y el resto (ECO, ubicación, autorruteo, DRC, Gerbers) se hizo en
Altium con la interfaz. Abrir cada `.PrjPcb`, correr *Project ▸ Validate PCB
Project* y *Tools ▸ Design Rule Check* reproduce los resultados de arriba.
