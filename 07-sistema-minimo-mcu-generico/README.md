# 07 — Sistema mínimo de microcontrolador (STM32F103)

## Objetivo de aprendizaje

El ejemplo más grande de la serie: un sistema mínimo real con un
microcontrolador ARM Cortex-M3 (STM32F103C8T6, el mismo chip del popular
"Blue Pill"). Vas a aprender los **5 bloques que se repiten en
absolutamente cualquier diseño con microcontrolador**, sin importar la
familia (STM32, PIC, AVR, ESP32...):

1. **Desacople de alimentación** — un capacitor por cada pin VDD.
2. **Circuito de reset** — cómo asegurar un arranque limpio.
3. **Selección de modo de arranque (boot)** — BOOT0.
4. **Oscilador de cristal externo** — con el cálculo de capacitores de carga.
5. **Conector de programación/debug** — SWD en este caso.

Y del lado de Altium, herramientas que no usaste antes:
- **Layer Stack Manager** — configurar una placa multicapa (4 capas).
- Reglas de diseño según **capacidades de un fabricante real**.
- **Fanout** de un footprint de paso fino (LQFP48).
- **Vista 3D** para chequeo mecánico.
- **Draftsman** para generar un plano de ensamblaje.

## Prerrequisito

Ejemplos 01 a 06 (usa desacople como en el 03, y footprints SMD como en
el 05, pero a mayor escala)

## Cálculos

### Capacitores de carga del cristal
```
CL = 2 × (C_load_deseado - C_stray)
```
El STM32F103 espera un cristal de 8MHz con `C_load = 20pF` (dato de la
hoja de datos del cristal que elijas). Asumiendo `C_stray ≈ 5pF` (parásita
de pistas/pines):
```
CL = 2 × (20pF - 5pF) = 30pF
```
Se usan 2 capacitores de ~22pF a 30pF (valor comercial cercano) desde
cada pata del cristal a GND — confirmá siempre contra la hoja de datos
del cristal específico que uses, este cálculo es orientativo.

### Corriente de fanout / vías
Con un LQFP48 (pitch 0.5mm), no entra un via estándar entre pads
adyacentes — se necesitan vías de "fanout" chiquitas (ej. 0.2mm/8mil de
drill) inmediatamente afuera de cada pad para poder rutar hacia las capas
internas.

## Lista de materiales (BOM)

| Ref | Componente | Valor | Notas |
|---|---|---|---|
| U1 | STM32F103C8T6 | LQFP48 | El microcontrolador |
| C1-C4 | Capacitor cerámico | 100nF | Uno por cada pin VDD (el '103 tiene varios) |
| C5 | Capacitor electrolítico/tantalio | 4.7µF | Bulk, cerca de la alimentación general |
| FB1 | Ferrite bead | — | Entre VDD y VDDA (alimentación analógica filtrada) |
| C6 | Capacitor cerámico | 1µF | Filtro adicional de VDDA |
| C7 | Capacitor cerámico | 100nF | Filtro adicional de VDDA (junto a C6) |
| R1 | Resistencia | 10kΩ | Pull-up de NRST (reset) |
| C8 | Capacitor cerámico | 100nF | De NRST a GND (filtra ruido/rebote del botón) |
| SW1 | Pulsador táctil | — | Reset manual (opcional, aplica lo del ejemplo 04) |
| R2 | Resistencia | 10kΩ | Pull-down de BOOT0 (arranque normal desde flash) |
| Y1 | Cristal | 8MHz | Oscilador principal |
| C9, C10 | Capacitor cerámico | ~22-30pF | Capacitores de carga del cristal (ver cálculo) |
| J1 | Header 2x5 (SWD) | — | SWDIO, SWCLK, GND, 3V3, NRST + reservados |
| J2 | Header | — | Alimentación de entrada (3.3V regulado, de tu ejemplo 03 adaptado a 3.3V) |

## Esquema de referencia (bloques)

```
[Alimentación 3.3V] ──┬── C1..C4 (100nF, uno por VDD) ──► U1 (VDD×N)
                       ├── FB1 ──► VDDA ── C6, C7
                       └── C5 (4.7µF bulk)

VDD ── R1(10k) ──┬── NRST(U1)
                  │
                 C8(100nF)      SW1 (opcional, a GND)
                  │
                 GND

BOOT0 ── R2(10k) ── GND     (arranque desde Flash; a VDD arrancaría desde bootloader del sistema)

         C9(≈27pF)                    C10(≈27pF)
             │                             │
GND ─────────┴── OSC_IN(U1)──Y1──OSC_OUT(U1) ──┴───── GND

J1 (SWD): SWDIO─U1.PA13, SWCLK─U1.PA14, GND, 3V3, NRST
```

## Pasos en Altium Designer

### 1-2. Proyecto y esquema
Como siempre, pero este esquema puede beneficiarse de dividirse en
sub-hojas (aplicá lo del ejemplo 06 si querés: una hoja "Power", una
"MCU+Osc+Reset", una "SWD") — opcional, pero recomendado dado el tamaño.

### 3. Colocar el STM32F103C8T6
1. Buscalo por nombre exacto en el catálogo ("STM32F103C8T6").
2. Al ser un componente grande, el símbolo suele venir dividido en varias
   "partes" (o un símbolo único muy largo) — revisá cómo lo trae este
   catálogo específico antes de empezar a cablear.

### 4. Desacople — uno por pin VDD
1. Contá cuántos pines VDD tiene el chip (revisá el datasheet o el mismo
   símbolo — suelen ser 3-4 en el STM32F103C8T6).
2. Colocá **un capacitor de 100nF por cada uno**, lo más cerca posible de
   su pin correspondiente (esto se define bien en el PCB, en el esquema
   solo hace falta que existan como componentes separados, no un único
   capacitor "compartido").

### 5. Reset, boot, oscilador
Seguí el esquema de referencia. Para el pull-up/pull-down de NRST/BOOT0,
aplicá el mismo criterio del ejemplo 04.

### 6. SWD
1. Colocá un header 2x5 (o el estándar de 4-6 pines si preferís uno
   simplificado) y conectá SWDIO, SWCLK, GND, 3V3 y NRST a los pines
   correspondientes del STM32.

### 7. ERC
`Project → Validate PCB Project`. Con un chip de 48 pines, es normal que
aparezcan más pines sin usar — revisá que ninguno de los que SÍ usaste
quede desconectado por error.

### 8. PCB — Layer Stack Manager
1. `Design → Layer Stack Manager` (puede aparecer como panel o ventana).
2. Configurá **4 capas**: Top Signal, Ground Plane (interna), Power Plane
   (interna), Bottom Signal — el arreglo clásico para placas con
   microcontroladores.
3. Asigná GND a la capa interna 1 y VDD/3.3V a la interna 2 (como planos
   completos, no pistas).

### 9. Reglas según un fabricante real
1. Revisá las capacidades típicas de un fabricador de PCB accesible
   (ej. JLCPCB, PCBWay) para 4 capas: clearance mínimo (~4-5mil), ancho
   mínimo (~4-5mil), drill mínimo (~0.2mm/8mil).
2. Configurá `Design → Rules` con esos valores en vez de los defaults
   genéricos — es la primera vez en la serie que diseñás "para fabricar
   de verdad" en vez de solo para aprender el flujo.

### 10. Fanout del LQFP48
1. Colocá U1 y activá el modo de colocación de vías de fanout (muchas
   veces hay una herramienta o script "Fanout Component" en
   `Tools → Fanout` según la versión) — o hacelo a mano: un via chiquito
   justo afuera de cada pad que necesite ir a una capa interna/opuesta.
2. Sin esto, es prácticamente imposible rutar un chip de este paso a
   mano sin cruces imposibles.

### 11. Vista 3D
1. `View → 3D Layout` (o el ícono correspondiente).
2. Confirmá visualmente que los cuerpos 3D del cristal, los headers y el
   LQFP no se superpongan ni queden fuera del contorno de la placa.

### 12. Rutar y DRC
Con las reglas de fabricante real configuradas, este paso es más
demandante que en los ejemplos anteriores — priorizá primero las señales
críticas (oscilador: pistas cortas y simétricas entre OSC_IN/OSC_OUT;
SWD: razonablemente cortas).

### 13. Draftsman — plano de ensamblaje
1. `Place → Draftsman → New Draftsman Document` (o similar según menú).
2. Generá una vista con la posición de cada componente, designadores, y
   el contorno de la placa — es el documento que le darías a quien
   ensambla la placa a mano o a una línea de SMT.

### 14. Gerbers
Igual que siempre, más el archivo de posición de componentes
(`File → Assembly Outputs → Generate Pick and Place Files`) — necesario
para fabricación real de una placa con SMD.

## Checklist de verificación

- [ ] Cada pin VDD del STM32 tiene su propio capacitor de 100nF cerca.
- [ ] NRST tiene pull-up + capacitor de filtrado.
- [ ] BOOT0 tiene pull-down (arranque normal desde Flash).
- [ ] Los capacitores de carga del cristal coinciden con el cálculo (o
      con la hoja de datos del cristal elegido).
- [ ] El Layer Stack tiene 4 capas con planos de GND y VDD internos.
- [ ] Las reglas de diseño coinciden con las capacidades de un
      fabricante real, no con los defaults de Altium.
- [ ] El fanout del LQFP48 está hecho antes de intentar rutar.
- [ ] Vista 3D sin colisiones visibles.
- [ ] DRC sin errores con las reglas de fabricante.
- [ ] Documento Draftsman generado.

## Errores clásicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| El microcontrolador no arranca / no se programa | BOOT0 no está claramente en 0 o 1 (flotando) | Confirmar el pull-down de BOOT0 esté bien conectado |
| El oscilador no arranca o es inestable | Capacitores de carga mal calculados, o pistas muy largas/asimétricas | Recalcular CL contra la hoja de datos real del cristal, acortar y simetrizar las pistas |
| Imposible rutar el LQFP48 a mano | No se hizo fanout antes de rutar | Volver atrás y colocar vías de fanout en cada pad relevante primero |
| DRC con decenas de errores de clearance | Reglas configuradas con valores de fabricante casero, no del fabricante real elegido | Revisar la hoja de capacidades del fabricante y reconfigurar |
| El SWD no logra conectar con el programador | Falta continuidad en SWDIO/SWCLK, o NRST no llega al conector | Verificar continuidad con el multímetro o revisar el ratsnest antes de rutar |

**Siguiente**: [08 — Placa de entrenamiento integradora](../08-placa-entrenamiento-integradora/README.md)
