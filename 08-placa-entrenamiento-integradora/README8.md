# 08 — Placa de entrenamiento integradora (capstone)

## Objetivo de aprendizaje

Los siete ejemplos anteriores te enseñaron bloques. Este te enseña lo que
**no** se aprende haciendo bloques: integrarlos. Vas a descubrir que juntar
cinco circuitos que funcionan por separado no produce automáticamente un
sistema que funcione — hay que adaptar interfaces, repartir un presupuesto de
potencia, asignar pines sin conflictos, separar dominios en el layout y,
sobre todo, **decidir antes de dibujar**.

Al terminar vas a saber:

* Escribir una **especificación** y un **diagrama de bloques** antes de abrir
Altium, y por qué ese es el paso que más tiempo ahorra.
* Armar un **mapa de asignación de pines** que respete las funciones
alternativas del MCU y no se rompa cuando agregues un periférico.
* Calcular un **presupuesto de corriente** y verificar térmicamente una
**cascada de dos reguladores**.
* **Re-escalar un bloque** para una alimentación distinta de la original —
el aprendizaje central del ejemplo.
* Decidir con criterio **qué se resuelve en hardware y qué en firmware**.
* **Proteger** entradas analógicas y manejar cargas externas con un MOSFET.
* **Particionar el layout** en dominios analógico y digital, y qué hacer con
los planos de tierra.
* Ejecutar un **bring-up** — encender por primera vez una placa nueva sin
destruirla — y un **design review** antes de mandarla a fabricar.
* En Altium: **Output Job**, **Project Releaser**, **variantes de ensamblaje**
y comparación entre versiones.

## Prerrequisitos

Todos los anteriores. Este ejemplo **reutiliza** sus circuitos:

|Bloque de esta placa|Viene de|
|-|-|
|Fuente 5 V + 3.3 V|[03 — Fuente lineal regulada](../03-fuente-lineal-regulada/README.md)|
|4 canales de pulsador antirrebotado|[04 — Antirrebote](../04-antirrebote-pulsador/README.md)|
|Acondicionador de entrada analógica|[05 — Op-amp](../05-acondicionador-opamp/README.md)|
|Organización multi-hoja y multicanal|[06 — Jerárquico](../06-esquema-jerarquico/README.md)|
|Sistema mínimo STM32|[07 — Sistema mínimo](../07-sistema-minimo-mcu-generico/README.md)|

\---

# Parte 1 — Diseño en papel (antes de abrir Altium)

> \*\*Esta parte no es un trámite.\*\* En la industria, el 60 % del tiempo de un
> diseño se va acá, y las decisiones que tomás en esta etapa son las que no se
> pueden revertir después sin rehacer la placa. Un error de especificación
> cuesta una tirada de PCB; un error de ruteo cuesta media hora.

## 1.1 Especificación

|Requisito|Valor|
|-|-|
|Alimentación de entrada|9 – 12 V DC, jack o bornera, con protección de polaridad|
|Rieles internos|**5 V** (periféricos y expansión) y **3.3 V** (MCU y analógico)|
|Microcontrolador|STM32F103C8T6, LQFP-48, 72 MHz|
|Entradas digitales|4 pulsadores con antirrebote por hardware|
|Entrada analógica|1 canal, ±200 mV pico, acoplada en AC, ancho de banda 3 Hz – 7 kHz, con protección|
|Salida analógica|1 canal, 0 – 3.3 V, generada por PWM filtrado y bufereado|
|Salida de potencia|1 canal, MOSFET low-side, hasta 1 A desde el riel de entrada, con diodo de rueda libre|
|Comunicación|UART (header FTDI) + bus I²C en header + expansión de GPIO|
|Programación|SWD, más jumper BOOT0 para el bootloader UART|
|Indicadores|LED de alimentación, LED de usuario|
|Formato|100 × 80 mm, 2 capas, 4 agujeros M3|

## 1.2 Diagrama de bloques

```
   J1 9-12V ──►┌──────────────────────────────────────────────┐
               │              POWER                           │
               │  D1 ► 7805 ──► +5V ──► AMS1117-3.3 ──► +3V3  │
               └────┬──────────────────────┬──────────────────┘
                    │ +5V                  │ +3V3
                    │                      │
      ┌─────────────┴──────┐  ┌────────────┴─────────────────────────┐
      │  DRIVER (Q1 MOSFET)│  │                MCU                   │
      │  ◄── PWM\_OUT       │  │  STM32F103C8T6 + reloj + reset +     │
      │  J6 carga externa  │  │  boot + SWD + UART + I²C + expansión │
      └────────────────────┘  └──┬────────────┬──────────┬──────────┘
                                 │ BTN\[0..3]  │ ADC\_IN   │ PWM\_DAC
      ┌──────────────────────────┴───┐  ┌─────┴──────┐ ┌─┴───────────────┐
      │        INPUT (×4)            │  │ ANALOG\_IN  │ │  ANALOG\_OUT     │
      │  SW ► RC ► 74HC14 ► BTNn     │  │ J4 ► prot. │ │ PWM ► RC 2º ord.│
      │  (multicanal Repeat)         │  │ ► amp ×7.8 │ │ ► buffer ► J5   │
      └──────────────────────────────┘  └────────────┘ └─────────────────┘
```

## 1.3 La decisión que define todo el resto: ¿a qué tensión trabaja cada cosa?

Los ejemplos 03, 04 y 05 están diseñados a **5 V**. El ejemplo 07 trabaja a
**3.3 V**. No podés simplemente cablearlos entre sí.

**Decisión de este diseño**: todo lo que toca al MCU corre a **3.3 V**.

|Bloque|Tensión|Motivo|
|-|-|-|
|MCU|3.3 V|No tolera 5 V en VDD|
|ANALOG\_IN|3.3 V|Su salida entra al ADC: debe estar en el rango 0–3.3 V|
|ANALOG\_OUT|3.3 V|La referencia de escala es la misma del ADC|
|INPUT (74HC14)|3.3 V|Las salidas van a pines del MCU|
|DRIVER|Compuerta desde 3.3 V|Exige un MOSFET **logic-level**|
|Riel de 5 V|5 V|Solo alimenta la expansión y la entrada del regulador de 3.3 V|

> \*\*La trampa clásica\*\*: "los pines del STM32F103 son 5 V tolerantes, así que
> puedo alimentar el 74HC14 con 5 V". Es cierto para los pines digitales
> marcados FT en el datasheet — pero \*\*no\*\* para PC13/14/15 ni para los pines
> analógicos, y además una salida de 5 V inyecta corriente por los diodos de
> protección del MCU si el riel de 3.3 V arranca después. Si podés evitar el
> cruce de dominios, evitalo. Es más barato que un traductor de niveles.

## 1.4 Mapa de asignación de pines

Este es el documento que **hay que hacer antes de dibujar el esquema**. Una
vez que ruteaste la placa, cambiar un pin significa cortar pistas.

|Pin|Señal|Periférico / función|Bloque|
|-|-|-|-|
|5, 6|OSC\_IN / OSC\_OUT|HSE 8 MHz|MCU|
|7|NRST|Reset + SWD|MCU|
|44|BOOT0|Jumper de arranque|MCU|
|20|PB2 / BOOT1|Pull-down 10 k|MCU|
|34|PA13|SWDIO|SWD|
|37|PA14|SWCLK|SWD|
|30|PA9|USART1\_TX|Header FTDI|
|31|PA10|USART1\_RX|Header FTDI|
|10|PA0|**ADC1\_IN0**|ANALOG\_IN|
|18|PB0|**TIM3\_CH3** (PWM)|ANALOG\_OUT|
|19|PB1|**TIM3\_CH4** (PWM)|DRIVER|
|25|PB12|GPIO + EXTI12|BTN0|
|26|PB13|GPIO + EXTI13|BTN1|
|27|PB14|GPIO + EXTI14|BTN2|
|28|PB15|GPIO + EXTI15|BTN3|
|42|PB6|I2C1\_SCL|Header I²C|
|43|PB7|I2C1\_SDA|Header I²C|
|2|PC13|LED de usuario (**sumidero**, 3 mA máx)|MCU|
|15, 16, 17|PA5, PA6, PA7|SPI1 (SCK/MISO/MOSI) — **reservados**|Expansión|
|11–14|PA1–PA4|Libres|Expansión|
|29, 38–41, 45, 46|PA8, PA15, PB3–PB5, PB8, PB9|Libres|Expansión|

**Las tres verificaciones que hay que hacer sobre esta tabla**:

1. **Conflictos de función alternativa.** Si hubiera puesto el PWM en PA6 y
PA7, habría inutilizado SPI1 (MISO y MOSI). Por eso el PWM va a PB0/PB1:
deja SPI1 entero para la expansión. En el STM32F1 estos conflictos se
resuelven además con **AFIO remap**; revisá la tabla de *Alternate function
mapping* del datasheet, no la del manual de referencia.
2. **Líneas EXTI.** En STM32, la línea de interrupción externa la define el
**número** de pin, no el puerto: PA12 y PB12 comparten EXTI12 y no pueden
usarse las dos como interrupción. Los cuatro botones están en PB12–PB15 →
EXTI12, 13, 14 y 15: **sin conflicto**.
3. **Pines con limitaciones.** PC13/PC14/PC15 dan 3 mA y 2 MHz: sirven para un
LED como sumidero y para poco más.

> \*\*Hacé esta tabla en una hoja de cálculo\*\* y guardala en la carpeta del
> proyecto. Es documentación de diseño, igual que el esquema, y es lo primero
> que vas a consultar cuando escribas el firmware.

## 1.5 Presupuesto de corriente y verificación térmica

### Riel de 3.3 V

|Consumidor|Corriente|
|-|-|
|STM32F103 a 72 MHz, periféricos activos|36 mA|
|MCP6004 (4 amplificadores × \~100 µA)|0.4 mA|
|74HC14 (conmutación de 4 canales)|\~1 mA|
|LED de alimentación|1.3 mA|
|LED de usuario|1.3 mA|
|Display OLED I²C (opcional)|20 mA|
|Margen para expansión|50 mA|
|**Total 3.3 V**|**≈ 110 mA**|

### Riel de 5 V

Periféricos de expansión y reserva: **100 mA** de diseño.

### Corriente que atraviesa el 7805

El regulador de 3.3 V cuelga del riel de 5 V, así que el 7805 carga con
**los dos** consumos:

```
I\_7805 = 100 mA (riel 5 V) + 110 mA (que consume el AMS1117) = 210 mA
```

### Disipación (método del ejemplo 03)

```
7805:      Pd = (12 V − 0.9 V del diodo − 5 V) × 0.21 A = 1.28 W
           θja necesaria = (110 °C − 40 °C) / 1.28 W = 55 °C/W
           TO-220 al aire ≈ 65 °C/W  →  NO ALCANZA

AMS1117:   Pd = (5 V − 3.3 V) × 0.11 A = 0.19 W
           ΔT = 0.19 W × 60 °C/W = 11 °C  →  OK, sin disipador
```

**Conclusión de diseño**: el 7805 **necesita disipador** (uno clip-on de
aletas, θsa ≈ 20 °C/W, deja el total en \~26 °C/W) **o** hay que bajar la
tensión de entrada a 9 V, con lo que `Pd = 0.65 W` y `θja necesaria = 108 °C/W`
→ alcanza con un área de cobre generosa bajo la lengüeta.

> \*\*Decisión recomendada\*\*: dejá previsto el disipador en el layout (espacio
> mecánico y agujero de montaje) y especificá en la documentación
> "Vin ≤ 9 V sin disipador; hasta 12 V con HS1 montado". Eso es hacer
> ingeniería: no elegir un único punto de operación, sino documentar el rango
> válido y su condición.

## 1.6 ¿Hardware o firmware? El caso del antirrebote

Es la pregunta que te van a hacer en la defensa del proyecto, así que
conviene tener la respuesta razonada.

||Antirrebote por hardware (este diseño)|Antirrebote por firmware|
|-|-|-|
|Costo|4 R + 4 C + 1 IC ≈ 0.40 USD|0 USD|
|Espacio en PCB|\~4 cm²|0|
|Consumo de CPU|Ninguno|Un temporizador + lógica en cada interrupción|
|Latencia|Fija, \~1.6 ms, determinista|Depende de la carga del sistema|
|Se puede ajustar después|No (hay que cambiar componentes)|Sí, cambiando una constante|
|Funciona antes de que arranque el firmware|**Sí**|No|
|Sirve si la entrada va a un periférico por hardware (captura, contador)|**Sí**|**No**|

**Criterio**: el hardware gana cuando la señal alimenta un periférico que no
pasa por la CPU (una captura de temporizador, un contador de encoder, una
entrada de wake-up), cuando la latencia tiene que ser determinista o cuando el
sistema tiene que comportarse bien antes de que el firmware configure nada. El
firmware gana en cualquier otro caso, y sobre todo cuando querés poder
ajustarlo.

**Para esta placa se eligió hardware** porque es una placa de entrenamiento: el
objetivo explícito es poder **medir la diferencia** entre la señal cruda y la
filtrada con osciloscopio. Por eso el esquema lleva también un punto de
prueba con la señal sin filtrar de cada canal.

\---

# Parte 2 — Los bloques, y qué hay que cambiarles

## 2.1 POWER — cascada de dos reguladores

Es el circuito del ejemplo 03 (7805 con D1, C1–C4, LED) **más** una segunda
etapa:

```
  +5V ──┬──── U3 (AMS1117-3.3) ──┬──── +3V3
        │      IN      OUT        │
       C11    └── GND ──┘        C12 ‖ C13
      10µF        │             22µF  100nF
        │        GND               │
       GND                        GND
```

|Ref|Valor|Nota|
|-|-|-|
|U3|AMS1117-3.3, SOT-223|Dropout \~1.1 V → necesita Vin ≥ 4.5 V ✔ (tiene 5 V)|
|C11|10 µF|Entrada|
|C12|**22 µF**|Salida — el AMS1117 **exige** ≥ 22 µF para ser estable|
|C13|100 nF|Salida, cerámico rápido|

**Qué se agrega respecto del ejemplo 03**:

* **Punto de prueba (test point) en cada riel**: `+VIN`, `+5V`, `+3V3` y `GND`.
En Altium se colocan como pads sin componente o con un símbolo de test
point; en la placa son un anillo de cobre donde enganchar el cocodrilo del
multímetro. **Ponelos siempre** — el bring-up de la Parte 5 los necesita.
* **Jumper de separación entre etapas (JP2)**: un jumper de 2 pines en serie
entre la salida del 7805 y la entrada del AMS1117. Te deja energizar y
verificar el riel de 5 V **sin** alimentar nada del resto de la placa. Vale
10 centavos y salva placas.

## 2.2 INPUT — cuatro canales, y la ventaja del multicanal

El circuito del ejemplo 04, replicado 4 veces con la técnica multicanal del
ejemplo 06:

1. `DEBOUNCE\_CH.SchDoc` contiene **un** canal: SW, R1 (10 k pull-up),
R2 (10 k serie), C1 (100 nF) y **dos** inversores del 74HC14.
Ports: `BTN\_OUT` (salida limpia) y `BTN\_RAW` (punto de prueba).
2. En `INPUT.SchDoc`, un sheet symbol con
`Designator = Repeat(DEB, 1, 4)` y los sheet entries
`Repeat(BTN\_OUT)` y `Repeat(BTN\_RAW)` conectados a los buses
`BTN\[0..3]` y `BTNRAW\[0..3]`.

**Cuentas del 74HC14 a 3.3 V** (a 3.3 V los umbrales son aproximadamente
`VT+ ≈ 1.8 V` y `VT− ≈ 1.0 V`):

```
τ\_subida = (10 k + 10 k) × 100 nF = 2.0 ms
τ\_bajada = 10 k × 100 nF          = 1.0 ms

t\_soltar  = −2.0 ms × ln(1 − 1.8/3.3) = 1.58 ms
t\_apretar = −1.0 ms × ln(1.0/3.3)     = 1.19 ms
```

Son prácticamente los mismos tiempos que a 5 V (1.55 y 1.14 ms). **No es
casualidad**: los umbrales del 74HC escalan con la alimentación, así que el
filtro RC + Schmitt es **ratiométrico** y su tiempo de respuesta es
esencialmente independiente de VCC. Esa es una propiedad que conviene saber
reconocer: los circuitos ratiométricos se portan igual en cualquier riel.

**Un cuidado nuevo**: el 74HC14 es de familia **HC**, con umbrales
proporcionales a VCC, y funciona de 2 a 6 V. Un **74HCT**14 tiene umbrales
fijos de tipo TTL (VT+ ≈ 1.6 V) pensados para VCC = 5 V y **no** es válido a
3.3 V. La letra que no está en el nombre importa.

**Uso de las compuertas**: 4 canales × 2 inversores = 8 inversores, pero el
74HC14 tiene 6. **Necesitás dos integrados** (U4 y U5), y sobran 4
inversores → entradas a GND, como aprendiste en el 04.

> \*\*Alternativa de diseño que vale la pena considerar\*\*: usar \*\*un solo\*\*
> inversor por canal (4 en total, entran en un chip) y aceptar que la señal
> quede invertida — el firmware lee "apretado = 1" en vez de "apretado = 0".
> Ahorra un integrado y 4 cm². Documentá la decisión en el esquema con una
> nota de texto; si no, el que escriba el firmware va a perder una tarde.

## 2.3 ANALOG\_IN — el bloque que hay que re-escalar (la lección central)

El acondicionador del ejemplo 05 estaba diseñado para 5 V. Acá trabaja a
3.3 V. **No es cambiar la alimentación y listo**: cambia la referencia, cambia
el swing disponible y por lo tanto cambia la ganancia máxima.

### Qué cambia y por qué

|Parámetro|Ejemplo 05 (5 V)|Acá (3.3 V)|
|-|-|-|
|Referencia VREF = VCC/2|2.50 V|**1.65 V**|
|Swing útil (rail-to-rail, con margen)|±2.45 V|**±1.60 V**|
|Ganancia máxima con ±200 mV de entrada|12.2|**8.0**|
|Ganancia elegida|×11|**×7.8**|
|Divisor de ganancia|R3 = 1 k, R4 = 10 k|R3 = 1 k, **R4 = 6.8 k**|

```
G = 1 + R4/R3 = 1 + 6.8 k / 1 k = 7.8   →   17.8 dB
Entrada máxima antes del recorte = 1.60 V / 7.8 = 205 mV pico  ✔
```

### Frecuencias de corte (recalculadas)

|Polo|Fórmula|Componentes|Valor|
|-|-|-|-|
|Acoplo de entrada|`1/(2π·R5·C1)`|100 k, 1 µF|**1.6 Hz**|
|Lazo de realimentación|`1/(2π·R3·C4)`|1 k, 47 µF|**3.4 Hz**|
|Anti-aliasing|`1/(2π·R4·C5)`|6.8 k, **3.3 nF**|**7.1 kHz**|

**Por qué C5 pasó de 1 nF a 3.3 nF**: no es que "haya que compensar el cambio
de R4". Es que ahora hay una restricción que antes no existía — **el ADC**. Si
el firmware muestrea a 20 kSa/s, Nyquist está en 10 kHz y todo lo que pase de
ahí se pliega dentro de la banda útil. Con 3.3 nF el corte queda en 7.1 kHz,
cómodamente por debajo de Nyquist. **El filtro anti-aliasing se dimensiona
desde la frecuencia de muestreo, no desde la resistencia que quedó.**

### Verificación del operacional

```
GBW del MCP6004 = 1 MHz ;  G = 7.8   →   BW = 1 MHz / 7.8 = 128 kHz
128 kHz >> 5 × 7.1 kHz = 36 kHz   ✔ sobra
```

El MCP6004 (versión cuádruple del MCP6002 del ejemplo 05) funciona de 1.8 a
6 V: a 3.3 V está dentro de rango.

### Reparto de los cuatro amplificadores

|Sección|Función|
|-|-|
|U2A|Etapa de ganancia ×7.8 (entrada analógica)|
|U2B|Buffer de VREF = 1.65 V|
|U2C|Buffer de la salida del DAC-PWM (bloque 2.4)|
|U2D|**Sobra** → conectar como seguidor con la entrada + a VREF\_BUF|

> Nunca dejes una sección sin usar con las entradas al aire. Configurada como
> seguidor a la referencia, queda estable y no consume ni oscila.

### Protección de la entrada (contenido nuevo)

La entrada `J4` va a un conector expuesto: cualquiera puede enchufarle una
señal de 12 V, o una descarga electrostática. Sin protección, eso destruye el
operacional y, por el camino, el ADC.

```
   J4.1 ──── R9 (1 kΩ) ──┬──────► a C1 (acoplo) ──► U2A
                         │
                    ┌────┴────┐
                   ▼ D3      ▼ D4       (BAT54S: los dos diodos en un SOT-23)
                    │         │
                  +3V3       GND
```

* **R9 (1 kΩ en serie)** limita la corriente que pueden conducir los diodos.
* **D3/D4 (diodos Schottky de fijación)** recortan la señal a
`−0.3 V … 3.6 V`. Un **BAT54S** trae los dos en un solo encapsulado con el
punto medio ya formado.
* Se usan **Schottky** y no diodos comunes porque su caída de 0.3 V recorta
antes de que el pin del operacional llegue a un nivel peligroso.

**El mismo patrón se aplica en el pin del ADC**: `R10 = 100 Ω` en serie y
`C14 = 1 nF` a GND, justo en PA0. Además de proteger, ese capacitor le da al
circuito de muestreo del ADC una fuente de carga local — el STM32F1 pide una
impedancia de fuente baja durante el tiempo de muestreo, y el buffer del
op-amp más ese capacitor se la dan.

## 2.4 ANALOG\_OUT — salida analógica por PWM filtrado (bloque nuevo)

El STM32F103C8T6 **no tiene DAC** (sí lo tienen los F103 de mayor densidad).
La salida analógica se genera con un **PWM filtrado**: un temporizador produce
una onda cuadrada de ciclo de trabajo variable, y un filtro pasa-bajos extrae
su valor medio.

```
 PB0 (TIM3\_CH3) ──R7──┬──R8──┬──────►┌──────┐
      PWM 20 kHz  10k  │  10k │       │ U2C  │──── R11 ──── J5.1 (VOUT)
                      C16    C17      │buffer│     100Ω
                     100nF  100nF     └──────┘
                       │      │
                      GND    GND
```

### Los cálculos

**Frecuencia de corte de cada polo**:

```
fc = 1 / (2π · 10 kΩ · 100 nF) = 159 Hz      (τ = 1 ms)
```

**Atenuación del rizado de PWM** — con dos polos, la atenuación a la
frecuencia de la portadora es:

```
A = (f\_pwm / fc)² = (20 000 / 159)² = 15 800   →   −84 dB
Rizado de salida = 3.3 V / 15 800 = 0.21 mV
```

**Comparación con la resolución del ADC** (que es la escala natural del
sistema): 1 LSB de 12 bits a 3.3 V son `3.3/4096 = 0.81 mV`. El rizado
(0.21 mV) queda **por debajo de 1 LSB** ✔. Ese es el criterio correcto para
decidir si el filtro es suficiente: no "que se vea plano en el osciloscopio",
sino que el rizado sea menor que el escalón mínimo del sistema.

**Tiempo de establecimiento**: dos polos de τ = 1 ms cada uno →
`≈ 5τ × 2 = 10 ms` para llegar al 99 %. Es la contracara del filtrado: cuanta
menos ondulación, más lenta la respuesta. Si necesitás una salida que siga
una señal de audio, este esquema no sirve — necesitás un DAC real.

**Resolución alcanzable del PWM**: con el temporizador a 72 MHz y portadora de
20 kHz, el contador llega a `72 MHz / 20 kHz = 3600` pasos ≈ **11.8 bits**.
Suficiente para acompañar a un ADC de 12 bits.

**Por qué el buffer U2C**: sin él, la impedancia de salida sería la del filtro
(≈ 20 kΩ) y cualquier carga conectada a J5 desplazaría la tensión. Con el
buffer, la salida es de baja impedancia y el valor es el calculado. `R11` de
100 Ω aísla la capacidad del cable, igual que en el ejemplo 05.

## 2.5 DRIVER — salida de potencia con MOSFET (bloque nuevo)

Para manejar una carga real (un relé, una tira de LEDs, un motor DC chico)
desde un pin que da 20 mA.

```
   +VIN (9-12V)
      │
      ├─────────┐
      │         │
    carga      D5 (1N4007, rueda libre)
   (J6)         │
      ├─────────┘
      │
      ├── D (drenador)
      │
  PB1 ──R12(100Ω)──┤ G   Q1 (IRLZ44N, logic-level)
                   │
              R13 (10k)
                   │
      ├── S (surtidor)
      │
     GND
```

|Ref|Valor|Función|
|-|-|-|
|Q1|IRLZ44N (TO-220) o AO3400 (SOT-23, hasta 1 A)|Interruptor low-side|
|R12|100 Ω|Limita el pico de corriente que pide la capacidad de compuerta|
|R13|10 kΩ|**Pull-down de compuerta**: mantiene Q1 apagado mientras el MCU no arrancó|
|D5|1N4007 (o Schottky SS34)|**Rueda libre**: da camino a la corriente de una carga inductiva|

**Los tres puntos que hay que entender**:

1. **"Logic-level" no es un adjetivo publicitario.** Un MOSFET común
(IRF540) especifica su `RDS(on)` a `VGS = 10 V`; con los 3.3 V que da el
pin, conduciría apenas y se destruiría por disipación. El IRLZ44N tiene
`RDS(on) = 0.028 Ω` a `VGS = 4 V` y funciona bien a 3.3 V. **Siempre mirá
la curva `RDS(on)` vs `VGS` al VGS que realmente vas a aplicar**, no el
número grande de la primera página del datasheet.
2. **El pull-down R13 no es opcional.** Entre que se energiza la placa y que
el firmware configura PB1 como salida, el pin está en alta impedancia. Sin
R13, la compuerta flota y la carga puede encenderse sola. Es el mismo
principio de los strapping pins del ejemplo 07.
3. **El diodo D5 va en paralelo con la carga, no con el MOSFET.** Cuando el
MOSFET corta, la inductancia de la carga intenta mantener la corriente y
genera un pico de tensión que destruye el transistor. D5 le ofrece un
camino. Si la carga es puramente resistiva no hace falta — pero como J6 es
un conector y nadie sabe qué le van a enchufar, **el diodo va igual**.

**Verificación térmica** (método del ejemplo 03) con 1 A:

```
Pd = I² × RDS(on) = 1² × 0.028 Ω = 28 mW   →   despreciable, sin disipador
```

Los MOSFET son eficientes justamente por esto: a diferencia del regulador
lineal, no "queman" la diferencia de tensión.

\---

# Parte 3 — El proyecto en Altium

## 3.1 Estructura jerárquica

```
08-placa-entrenamiento-integradora/
├── 08-placa-entrenamiento.PrjPcb
├── TOP.SchDoc            ← diagrama de bloques + conectores externos
├── POWER.SchDoc          ← 7805 + AMS1117 + test points + JP2
├── MCU.SchDoc            ← STM32 + reloj + reset + boot + desacople
├── DEBUG.SchDoc          ← SWD + header FTDI + jumper BOOT0
├── INPUT.SchDoc          ← contenedor multicanal
│   └── DEBOUNCE\_CH.SchDoc   ← Repeat(DEB, 1, 4)
├── ANALOG\_IN.SchDoc      ← protección + amplificador + VREF
├── ANALOG\_OUT.SchDoc     ← filtro PWM + buffer
├── DRIVER.SchDoc         ← MOSFET + flyback
├── 08-placa-entrenamiento.PcbDoc
├── 08-placa-entrenamiento.OutJob      ← salidas de fabricación
└── ENSAMBLAJE.PcbDwf                  ← Draftsman
```

## 3.2 Pasos

### 1\. Crear el proyecto

`File → New → Project` → **Local Projects** → **PCB → `<Empty>`** →
`08-placa-entrenamiento-integradora`. Antes de nada:
`Project → Project Options → Options` → **Net Identifier Scope = `Hierarchical`**.

### 2\. Traer los bloques ya diseñados

Copiá los `.SchDoc` de los ejemplos 03, 04, 05 y 07 a esta carpeta con los
nombres de arriba, y agregalos con `Add Existing to Project...`.

**Después de traerlos, aplicá los cambios de la Parte 2** (re-escalado del
analógico, jumper JP2, protección de entrada, segundo regulador). **No
avances hasta haberlos hecho**: es el error más común de este ejemplo —
integrar los bloques tal cual y descubrir en el bring-up que el acondicionador
satura porque sigue calculado para 5 V.

### 3\. Ports y jerarquía

Ports en cada hoja hija, `Design → Create Sheet Symbol From Sheet` en
`TOP.SchDoc`, conectores externos en la hoja padre. Procedimiento completo en
el [ejemplo 06](../06-esquema-jerarquico/README.md).

**Conectores que van en TOP.SchDoc**:

|Ref|Qué es|
|-|-|
|J1|Alimentación 9–12 V (bornera 5.08 mm)|
|J2|SWD, 1×5, 2.54 mm|
|J3|FTDI / UART, 1×6, 2.54 mm (GND, CTS, VCC, TX, RX, DTR)|
|J4|Entrada analógica, 1×2|
|J5|Salida analógica, 1×2|
|J6|Carga del MOSFET, bornera 5.08 mm 1×2|
|J7|I²C, 1×4 (3V3, GND, SCL, SDA)|
|J8, J9|Expansión de GPIO, 1×10 cada uno|

### 4\. Anotación jerárquica

`Tools → Annotate Schematics Hierarchically`, con un rango de índices por
hoja: POWER = 1xx, MCU = 2xx, INPUT = 3xx, ANALOG\_IN = 4xx, ANALOG\_OUT = 5xx,
DRIVER = 6xx. En una placa de este tamaño, leer `R412` y saber al instante
que está en el bloque analógico de entrada vale oro durante el bring-up.

### 5\. ERC

`Project → Validate PCB Project`. Cero errores. Revisá en particular:

* Que ningún port haya quedado sin su sheet entry después de los cambios.
* Que los 4 canales del `Repeat` estén compilados (miralos en el panel
`Projects`).
* Que las secciones sobrantes del 74HC14 y del MCP6004 estén atendidas.

### 6\. Layer stack y reglas

`Design → Layer Stack Manager`: 2 capas, FR-4, 1.6 mm, cobre 1 oz.
Reglas: importá las del ejemplo 07 (`Import Rules...`) y agregá una clase de
nets nueva:

|Clase|Nets|Regla de ancho|
|-|-|-|
|`POWER`|+VIN, +5V, +3V3, GND|Min 20 / Pref 30 / Max 80 mil|
|`LOAD`|Drenador de Q1 y retorno de J6|Min 40 / Pref 60 mil (¡1 A!)|
|(genérica)|resto|Min 6 / Pref 10 / Max 40 mil|

Para `LOAD`, el ancho sale de la IPC-2221 del ejemplo 03: 1 A en cobre de
1 oz con 10 °C de aumento necesita **20 mil**; usamos 60 mil por margen y para
ayudar a disipar.

## 3.3 Particionado del layout (contenido nuevo)

Esta es la parte donde el capstone se diferencia de todo lo anterior. Con seis
bloques en una placa, **dónde ponés cada cosa importa más que cómo la rutás**.

### Zonificación

```
┌──────────────────────────────────────────────────────────────┐
│  J1   \[ POWER ]           │              \[ MCU ]             │
│  HS1  7805  AMS1117       │      STM32 + cristal + desacople │
│  ─────────────────────────┼──────────────────────────────────┤
│                           │                        J2 (SWD)  │
│  \[ DRIVER ]   J6          │   \[ INPUT ]            J3 (FTDI) │
│   Q1  D5                  │   SW0 SW1 SW2 SW3                │
│  ─────────────────────────┼──────────────────────────────────┤
│  \[ ANALOG\_IN ]  J4        │        J8 / J9 expansión         │
│  \[ ANALOG\_OUT ] J5        │        J7 (I²C)                  │
└──────────────────────────────────────────────────────────────┘
        ZONA ANALÓGICA               ZONA DIGITAL
        (y de potencia, arriba)
```

**Los cuatro criterios, en orden de importancia**:

1. **Separá los dominios ruidosos de los sensibles.** El regulador y el
MOSFET son las fuentes de ruido; el acondicionador analógico y el cristal
son las víctimas. Van en extremos opuestos de la placa. Esto se decide con
el *placement*, y ninguna maniobra de ruteo lo compensa después.
2. **Los conectores mandan sobre la ergonomía.** La alimentación en un borde,
los pulsadores accesibles, el SWD donde entre el cable sin desarmar nada,
la expansión alineada para que entre un shield.
3. **Cada bloque se coloca completo antes de pasar al siguiente.** Usá las
**rooms** del ejemplo 06: movés una room y se mueve el bloque entero.
4. **Dentro de cada bloque, mandan las reglas locales** que ya aprendiste:
desacople a < 3 mm del pin, cristal a < 10 mm sin nada debajo, capacitores
del regulador pegados a sus pines, nodo de realimentación del op-amp corto.

### La pregunta de los planos de tierra

Vas a leer consejos contradictorios sobre "partir el plano de tierra" entre
analógico y digital. La recomendación para esta placa, y para casi todas las
de este tamaño y velocidad:

> \*\*Un solo plano de GND, continuo, sin cortes.\*\*

El motivo: la corriente de retorno de alta frecuencia no viaja por el camino
más corto, sino **por debajo de su propia pista** — es el camino de menor
inductancia. Si partís el plano, esa corriente tiene que rodear el corte,
crea un lazo grande y genera **más** ruido del que el corte pretendía evitar.
Los planos partidos con puente en un punto tienen sentido en diseños con
convertidores conmutados de varios amperios o ADCs de 16+ bits, no acá.

**Lo que sí se hace**: separación **por placement** (zonas), y que la
corriente de retorno de cada bloque no tenga motivo para atravesar la zona de
otro. Si ubicaste bien los bloques, eso se cumple solo.

**Una excepción concreta**: el retorno de la carga del MOSFET (J6, hasta 1 A
conmutando) **no** debe compartir plano con la zona analógica. Llevalo con una
pista ancha y dedicada desde J6 hasta el punto donde entra la alimentación,
por el borde de la placa.

### Costura de vías

`Tools → Via Stitching/Shielding → Add Stitching to Net` → GND, paso 8 mm, y
un anillo de guarda alrededor del cristal como en el ejemplo 07.

\---

# Parte 4 — Salidas, documentación y entrega

## 4.1 Output Job (contenido nuevo)

Hasta ahora generabas cada salida a mano. Con ocho hojas y varias salidas,
eso es una fuente de errores: la vez que te olvides de regenerar los Gerbers
después de un cambio, fabricás la versión vieja.

1. Click derecho en el proyecto → `Add New to Project` → **`Output Job File`**.
2. Agregá las salidas en sus categorías:

   * **Documentation Outputs** → `Schematic Prints` (todas las hojas),
`PCB Prints`.
   * **Assembly Outputs** → `Assembly Drawings`, `Pick and Place Files`,
`Test Point Report`.
   * **Fabrication Outputs** → `Gerber Files`, `NC Drill Files`,
`IPC-2581` (formato moderno que reemplaza a los Gerbers en muchos
fabricantes).
   * **Report Outputs** → `Bill of Materials` (vinculado al ActiveBOM),
`Design Rule Check`.
3. En la columna de la derecha, asigná cada salida a un **contenedor**:
`Folder Structure` (archivos sueltos) o `PDF`.
4. Configurá el contenedor para que escriba en
`Project Outputs for 08-placa-entrenamiento/`.
5. **`Generate content`** — y salen todas de una vez, con la misma
configuración, siempre.

## 4.2 Draftsman de ensamblaje

Como en el ejemplo 07, pero con más contenido porque la placa lo amerita:

* Vista de ensamblaje de la cara superior, con designadores.
* Tabla de BOM.
* Cotas del contorno y de los agujeros M3.
* **Tabla de test points** con qué tensión se espera en cada uno.
* Notas de armado: "HS1 obligatorio si Vin > 9 V", "JP1 abierto = arranque
normal", "JP2 cerrado en operación normal", "Y1: cristal CL = 10 pF".

## 4.3 Project Releaser y control de versiones (contenido nuevo)

`Project → Project Releaser` empaqueta un **release** inmutable: una foto
completa del diseño (esquemas, PCB, salidas, BOM) etiquetada con una versión.

* Cada vez que mandes a fabricar, **generá un release**. Si dentro de seis
meses aparece una placa con un problema, podés reconstruir exactamente qué
archivos la produjeron.
* Con el workspace de Altium 365 (el que ya tenés configurado, ver
`altium-365-sync/`), los releases quedan guardados en la nube con su
historial.
* Sin workspace: guardá la carpeta `Project Outputs` en un ZIP con el nombre
`08-placa-v1.0-YYYYMMDD.zip` y **no la toques más**.

**Comparar versiones**: `Project → Show Differences` compara dos versiones de
un documento o de todo el proyecto y muestra qué cambió, componente por
componente. Es lo que vas a usar cuando tengas la v1.1 y necesites explicar
qué se corrigió respecto de la v1.0.

## 4.4 Variantes de ensamblaje (opcional, contenido nuevo)

Una misma placa puede armarse en configuraciones distintas: una "básica" sin
el bloque analógico, una "completa" con todo.

1. `Project → Variants...` → `Add Variant` → nombrala `BASICA`.
2. En la lista de componentes, marcá como **`Not Fitted`** los del bloque
ANALOG\_IN y ANALOG\_OUT.
3. Al generar el BOM o el Draftsman, elegís la variante y salen solo los
componentes que se montan.

Sirve para no mantener dos proyectos casi idénticos, que es como se pierden
los cambios.

\---

# Parte 5 — Bring-up: encender la placa por primera vez (contenido nuevo)

Tenés la placa fabricada y armada. **No la enchufes todavía.** Este
procedimiento es el que separa una placa que funciona de una placa con un
7805 quemado y tres horas perdidas buscando por qué.

### Etapa 0 — Sin alimentación

1. **Inspección visual** con lupa: puentes de estaño entre pines del LQFP,
componentes al revés (mirá la marca del pin 1 de U1, U2, U4, U5 y la banda
de los diodos), soldaduras frías.
2. **Continuidad con el multímetro**:

   * `+VIN` a `GND`: debe dar resistencia alta (varios kΩ). **Si da corto, no
enchufes nada.**
   * `+5V` a `GND`: alta.
   * `+3V3` a `GND`: alta (unos kΩ por el consumo del MCU en reposo).
3. **Jumpers**: JP2 **abierto** (desconecta el AMS1117), JP1 en posición de
arranque normal.

### Etapa 1 — Solo el riel de 5 V

4. Fuente de banco con **límite de corriente en 100 mA**, salida en 9 V.
(Si no tenés fuente de banco, poné una resistencia de 47 Ω 2 W en serie con
la alimentación: limita la corriente y actúa de fusible visible.)
5. Encendé y **mirá el amperímetro antes que nada**. Consumo esperado: unos
pocos mA (solo el LED de alimentación). **Si la fuente entra en límite de
corriente, apagá y volvé al paso 2.**
6. Medí en los test points: `+VIN ≈ 8.1 V` (los 9 V menos el diodo),
`+5V = 5.0 V ± 0.15 V`.
7. Tocá el 7805 con el dorso del dedo: tibio está bien, quemar no.

### Etapa 2 — Riel de 3.3 V

8. Apagá. Cerrá **JP2**. Encendé.
9. Medí `+3V3 = 3.30 V ± 0.1 V`. Consumo total esperado: 15–40 mA (el MCU en
reposo, sin firmware).
10. Verificá con el multímetro: `NRST ≈ 3.3 V` (alto), `BOOT0 ≈ 0 V` (bajo).
Si NRST está bajo, el MCU está en reset permanente y nada va a funcionar.

### Etapa 3 — El microcontrolador responde

11. Conectá el ST-Link a J2. En **STM32CubeProgrammer** (o
`st-info --probe`), presioná **Connect**.
12. Tiene que leer el **Device ID `0x410`** y 64 KB de Flash. Si lo lee,
**el sistema mínimo funciona**: alimentación, reset, boot y SWD están bien.
Es el hito más importante del bring-up.
13. Si no conecta: probá `Connect under reset`; verificá SWDIO/SWCLK con el
multímetro; probá el bootloader UART (JP1 en posición boot + J3).

### Etapa 4 — Firmware mínimo

14. Cargá un *blink* en **PC13** (recordá: el LED se enciende poniendo el pin
en **bajo**). Si parpadea, la CPU corre.
15. **Verificá el cristal**: sonda del osciloscopio **×10** en `OSC\_OUT`
(pin 6), **nunca en OSC\_IN** — la capacidad de la sonda ahí detiene la
oscilación. Deberías ver una senoide de 8 MHz. Después configurá el PLL a
72 MHz y comprobá la frecuencia midiendo el período del blink.

### Etapa 5 — Bloque por bloque

16. **INPUT**: leé PB12–PB15. Apretá cada pulsador y confirmá que solo cambia
el suyo. Con el osciloscopio, compará `BTNRAW` contra `BTN` y **medí el
rebote** que el filtro está eliminando — es el experimento del ejemplo 04,
ahora en tu propia placa.
17. **ANALOG\_IN**: sin señal aplicada, el ADC debe leer ≈ **2048** (la mitad
de la escala, correspondiente a VREF = 1.65 V). Si lee 0 o 4095, el
operacional está saturado: revisá VREF y la realimentación. Después
inyectá una senoide de 100 mV pico a 1 kHz y verificá que la lectura
oscile **±968 cuentas** alrededor de 2048
(`0.1 V × 7.8 = 0.78 V` → `0.78 / 3.3 × 4096 = 968`).
18. **ANALOG\_OUT**: programá el PWM al 50 % y medí `J5`: debe dar
**1.65 V ± 30 mV**. Barré de 0 % a 100 % y verificá la linealidad con el
multímetro cada 10 %.
19. **DRIVER**: con J6 **sin carga**, poné PB1 en alto y medí el drenador de
Q1 (debe caer a \~0 V). Recién después conectá una carga chica (una
resistencia de 100 Ω) y verificá la corriente. **La carga inductiva se
prueba al final, y con el diodo D5 montado.**

> \*\*Documentá cada medición\*\* en una tabla junto al Draftsman. Cuando armes la
> segunda placa vas a tener con qué comparar, y cuando una falle vas a saber en
> qué etapa se rompe.

\---

# Parte 6 — Design review: la revisión antes de fabricar

Recorré esta lista **antes** de generar el Output Job. Idealmente con otra
persona: la mitad de los errores de diseño son invisibles para quien los
cometió.

## Esquema

* \[ ] **Todos** los pines de alimentación del MCU están conectados y
desacoplados (3 pares VDD/VSS + VDDA + VBAT).
* \[ ] VDDA tiene su filtro propio (ferrita + 100 nF + 1 µF).
* \[ ] Todos los strapping pins tienen estado definido: BOOT0 pull-down,
BOOT1 pull-down.
* \[ ] Ninguna entrada CMOS queda flotando: 74HC14 sobrantes a GND, MCP6004
sobrante como seguidor, compuerta del MOSFET con pull-down.
* \[ ] Cada conector externo que entra al circuito tiene protección (R serie +
diodos de fijación en J4).
* \[ ] La carga inductiva tiene diodo de rueda libre.
* \[ ] Los valores del bloque analógico son los **re-escalados a 3.3 V**, no
los del ejemplo 05.
* \[ ] Todos los conectores tienen su pin 1 marcado y el orden documentado.
* \[ ] Hay test points en +VIN, +5V, +3V3 y GND.
* \[ ] El ERC compila sin errores y los warnings están entendidos uno por uno.

## Cálculos

* \[ ] El presupuesto de corriente está hecho y cada regulador lo soporta.
* \[ ] La disipación de las **dos** etapas de regulación está calculada, y la
necesidad de disipador está documentada con su condición.
* \[ ] Los capacitores de carga del cristal salen del `CL` del cristal que
realmente compraste.
* \[ ] La ganancia del acondicionador no satura con la entrada máxima
especificada.
* \[ ] El filtro anti-aliasing está dimensionado desde la frecuencia de
muestreo elegida.
* \[ ] El rizado del DAC-PWM es menor que 1 LSB del ADC.
* \[ ] El ancho de las pistas de potencia sale de la IPC-2221 para su
corriente.

## PCB

* \[ ] El mapa de pines del esquema coincide con el del documento de diseño.
* \[ ] Los bloques están zonificados: potencia y conmutación lejos del
analógico y del cristal.
* \[ ] El plano de GND es **continuo**: ninguna pista larga en la capa inferior
lo parte en dos.
* \[ ] El retorno de la carga del MOSFET no atraviesa la zona analógica.
* \[ ] Cada capacitor de desacople está a menos de 3 mm de su pin.
* \[ ] El cristal está a menos de 10 mm, con guarda y sin nada ruteado debajo.
* \[ ] Los agujeros de montaje tienen zona despejada para tornillo y arandela.
* \[ ] La vista 3D no muestra colisiones (¡revisá el disipador del 7805!).
* \[ ] El DRC da **cero** violaciones con las reglas derivadas del fabricante.
* \[ ] Revisaste los Gerbers generados en un visor **externo**, capa por capa.

## Documentación

* \[ ] El Draftsman está completo, con las notas de armado.
* \[ ] El BOM tiene MPN real y stock verificado para cada componente
(ActiveBOM).
* \[ ] Hay un release etiquetado con la versión que mandás a fabricar.

\---

## Errores clásicos de este ejemplo

|Síntoma|Causa|Arreglo|
|-|-|-|
|El ADC lee siempre 0 o 4095|Bloque analógico sin re-escalar: VREF de 2.5 V con riel de 3.3 V|Recalculá VREF y la ganancia (§2.3)|
|El MCU no arranca pero los rieles están bien|BOOT0 o BOOT1 flotando, o VBAT al aire|Revisá los strapping pins|
|Todo funciona hasta que activás el MOSFET, y ahí se resetea el MCU|El retorno de la carga pasa por el plano de la zona sensible, o falta capacidad de reserva|Ruteo dedicado del retorno; más bulk en +VIN|
|El ADC tiene ruido sincronizado con el PWM|ANALOG\_IN y ANALOG\_OUT muy cerca, o retorno compartido|Separación por placement|
|El 7805 quema|No se consideró que alimenta también al AMS1117|Rehacé el presupuesto (§1.5); disipador o Vin menor|
|Dos botones responden a la vez en el firmware|Conflicto de líneas EXTI (mismo número de pin en puertos distintos)|Reasigná pines (§1.4)|
|El MOSFET se calienta muchísimo con poca corriente|No es logic-level: `RDS(on)` alto a 3.3 V de compuerta|Cambialo por un IRLZ44N / AO3400|
|La carga se enciende sola al energizar|Falta el pull-down de compuerta|R13 = 10 kΩ|
|La salida analógica tiene rizado visible|Un solo polo de filtro, o fc muy alta|Segundo polo (§2.4)|
|El 74HC14 no conmuta bien a 3.3 V|Es un 74**HCT**14 (umbrales TTL)|Reemplazalo por 74HC14|
|Fabricaste una versión vieja|Salidas generadas a mano en momentos distintos|Output Job + release (§4.1, §4.3)|

\---

## Qué deberías haber aprendido

Que **integrar no es sumar**. Cinco bloques correctos producen un sistema
incorrecto si nadie se ocupó de las interfaces entre ellos: la tensión de
referencia que cambió, el regulador que ahora carga con dos consumos, el pin
que servía para dos periféricos, el retorno de corriente que atraviesa la zona
equivocada. Ninguno de esos problemas existe *dentro* de un bloque — todos
viven *entre* bloques, y solo se ven si el diseño se piensa completo, en papel,
antes de dibujar la primera línea.

Y que el entregable de un diseño no es la placa: es la placa **más** la
especificación, el mapa de pines, el presupuesto de potencia, el plano de
ensamblaje, el procedimiento de bring-up, el registro de mediciones y el
release versionado. Eso es lo que permite que alguien más —o vos mismo dentro
de un año— pueda fabricar otra, entenderla y modificarla.

\---

## Extensiones sugeridas

Si querés llevar la placa más lejos, en orden de dificultad creciente:

1. **USB nativo** — el STM32F103C8T6 tiene USB device en PA11/PA12. Necesita
un pull-up de 1.5 kΩ en D+ y un cristal de 8 MHz exacto (no 12). Es el
agregado más útil: elimina el adaptador FTDI y te da una consola virtual.
2. **Sensor real en la entrada analógica** — reemplazá J4 por un micrófono
electret con su polarización, o una termocupla con su amplificador.
Obliga a repensar la ganancia y el acoplo.
3. **DAC real por SPI** (MCP4921) en lugar del PWM filtrado, y comparar los
dos con el osciloscopio: rizado, tiempo de establecimiento y ancho de banda.
4. **Pasar a 4 capas** con planos dedicados de GND y de alimentación, y
comparar el ruido medido en el ADC contra la versión de 2 capas. Es el
experimento que más enseña sobre integridad de señal.
5. **Aislamiento galvánico** de la salida de potencia con un optoacoplador,
si la carga viene de otra fuente.

**Anterior**: [07 — Sistema mínimo de microcontrolador](../07-sistema-minimo-mcu-generico/README.md)
· **Índice**: [Ejemplos de aplicación](../README.md)

