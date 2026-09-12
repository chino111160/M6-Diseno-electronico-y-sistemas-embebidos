# 05 — Acondicionador de señal con amplificador operacional

## Objetivo de aprendizaje

Tu primer circuito **analógico de verdad**, alimentado con una sola
tensión (no ±V como en los libros de texto clásicos). Vas a aprender:

- Cómo diseñar con **alimentación simple** (single-supply) creando una
  **referencia virtual** (VCC/2) en vez de necesitar una fuente negativa.
- Qué son los **capacitores de acople** (AC coupling) y por qué definen
  la frecuencia mínima que pasa el circuito.
- Qué es el **producto ganancia-ancho de banda** (GBW) de un op-amp y por
  qué limita cuánta ganancia podés pedirle a una frecuencia dada.
- Correr tu primera **simulación SPICE** en Altium (barrido en AC y
  respuesta transitoria) antes de construir nada físico.
- Usar el panel **ActiveBOM** para revisar tu lista de materiales.

## Prerrequisito

[03 — Fuente lineal regulada](../03-fuente-lineal-regulada/README.md)
(vamos a alimentar este circuito con los 5V de esa fuente, conceptualmente)

## Cálculos

### Referencia virtual (VCC/2)
Con alimentación simple de 5V, "cero" para la señal AC no puede ser 0V
real (el op-amp no puede sacar tensión negativa). Se crea un punto medio:
```
Vref = VCC / 2 = 2.5V
```
con un divisor resistivo R1=R2=10kΩ, y se usa como referencia para
polarizar la entrada no inversora.

### Ganancia del amplificador no inversor
```
Av = 1 + (Rf / Rg)
```
Con Rf=10kΩ y Rg=1kΩ:
```
Av = 1 + (10k/1k) = 11  (≈ 20.8 dB)
```

### Frecuencia de corte del acople de entrada (pasa-altos)
```
fc = 1 / (2π × Rg × Cin)
```
Con Rg=1kΩ y Cin=1µF:
```
fc = 1 / (2π × 1000 × 1×10⁻⁶) ≈ 159 Hz
```
Por debajo de esa frecuencia, la señal se atenúa — filtra continua (DC) y
ruido de muy baja frecuencia antes de amplificar.

### Límite de ancho de banda por GBW
Un op-amp común (ej. TL072) tiene GBW ≈ 3MHz. Con ganancia 11:
```
f_max_util = GBW / Av = 3,000,000 / 11 ≈ 273 kHz
```
Por encima de esa frecuencia, la ganancia real cae por debajo de la
teórica — el op-amp "no llega".

## Lista de materiales (BOM)

| Ref | Componente | Valor | Notas |
|---|---|---|---|
| J1 | Header 2 pines | — | Entrada de señal (IN, GND) |
| C1 | Capacitor cerámico | 1µF | Acople de entrada (bloquea DC) |
| R1 | Resistencia | 10kΩ | Divisor de referencia (mitad superior) |
| R2 | Resistencia | 10kΩ | Divisor de referencia (mitad inferior) |
| C2 | Capacitor cerámico | 10µF | Filtro de la referencia virtual |
| Rg | Resistencia | 1kΩ | Ganancia (a GND vía este resistor) |
| Rf | Resistencia | 10kΩ | Realimentación |
| U1 | Amplificador operacional | TL072 (SOIC-8) | Un solo canal usado de los 2 que trae |
| C3 | Capacitor cerámico | 100nF | Desacople de U1 |
| C4 | Capacitor cerámico | 1µF | Acople de salida |
| J2 | Header 2 pines | — | Salida de señal (OUT, GND) |

## Esquema de referencia

```
VCC ──┬── R1(10k) ──┬──────────────────(+)U1A
      │             │                    │
      C2           (Vref=2.5V)          salida ── C4(1µF) ── J2.1(OUT)
      │             │                    │
GND ──┴── R2(10k) ──┘              (-)───┴─── Rf(10k) ──┐
                                     │                    │
J1.1(IN)──C1(1µF)──Rg(1k)───────────┘◄───────────────────┘
                     │
                    GND
```

Es un **no inversor**: la señal de entrada llega a la pata (+) a través
del acople y queda montada sobre Vref; Rg y Rf fijan la ganancia.

## Pasos en Altium Designer

### 1-2. Proyecto y esquema
Igual que siempre.

### 3. Colocar los componentes
Buscá en el catálogo: Resistors (10k×3, 1k), Capacitors (1µF×2, 10µF,
100nF), y **"TL072"** en Integrated Circuits (o busca "operational
amplifier" si no aparece por nombre exacto). Como en el ejemplo 04, el
TL072 es multi-parte (2 op-amps) — usá la Parte A.

### 4. Cablear
Seguí el esquema de referencia. Etiquetá el nodo Vref con `Place → Net
Label` para que sea fácil de identificar.

### 5. Simulación SPICE — antes de ir al PCB
Esta es la parte nueva más importante del ejemplo:
1. Confirmá que U1 tenga un modelo SPICE asociado (los componentes del
   catálogo de Altium 365 suelen traerlo; si no, el simulador te avisa).
2. Reemplazá momentáneamente J1 por una fuente de señal: `Place → Part`,
   buscá una fuente **"Voltage Source Sine"** o similar en la librería de
   simulación, con amplitud pequeña (ej. 100mV) y offset en 0V.
3. `Design → Simulate → Mixed Sim` (o el menú de simulación equivalente).
4. Configurá un análisis **Transient** (ver la señal amplificada en el
   tiempo) y un análisis **AC Sweep** (ver la respuesta en frecuencia,
   deberías ver la ganancia caer por debajo de fc≈159Hz y también caer a
   frecuencias altas por el límite de GBW).
5. Compará lo que ves en la simulación con los cálculos de arriba.
6. Sacá la fuente de simulación y volvé a conectar J1 antes de continuar.

### 6. ERC
Igual que siempre — confirmá 0 errores.

### 7. Revisar el ActiveBOM
1. Abrí el documento **ActiveBOM** del proyecto (aparece en el árbol,
   "+ Create" si todavía no existe).
2. Ahí ves la lista de materiales real, con cantidades, part numbers de
   fabricante (si el componente del catálogo los trae) y estado de stock.
3. Es la vista que usarías antes de mandar a fabricar/comprar — más
   completa que solo mirar el esquema.

### 8-11. PCB, placement, rutado, DRC, Gerbers
Igual que en ejemplos anteriores. U1 en SOIC-8 es más chico que el DIP
del ejemplo 04 — vas a necesitar bastante zoom para rutar sus pines, como
aprendimos (con dolor) en el ejemplo 02 con R?.

## Checklist de verificación

- [ ] La simulación transient muestra la señal de salida amplificada
      ~11 veces respecto a la entrada, montada sobre 2.5V.
- [ ] La simulación AC muestra la caída de ganancia por debajo de ~159Hz.
- [ ] Podés calcular a mano la frecuencia donde la ganancia real empieza
      a caer por límite de GBW, y verla (aproximadamente) en la simulación.
- [ ] ActiveBOM muestra los 11 componentes con cantidades correctas.
- [ ] ERC y DRC sin errores.

## Errores clásicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| La simulación no corre / "no SPICE model" | El componente del catálogo no trae modelo de simulación | Buscar una variante del mismo op-amp que sí lo tenga, o agregar el modelo manualmente |
| La señal de salida está "pegada" a 0V o a VCC | Falta la referencia Vref, o mal conectada | Verificar que el divisor R1/R2 esté bien alimentado y filtrado por C2 |
| Ganancia medida muy distinta a la calculada | Rf/Rg con valores reales distintos a los del esquema (tolerancia de catálogo) | Revisar los valores exactos elegidos del catálogo, no asumir el valor "nominal" |
| No hay respuesta a alta frecuencia | Confundiste el límite de GBW con un error de diseño | Es esperado — es la limitación física del op-amp, no un bug |

**Siguiente**: [06 — Esquema jerárquico multi-hoja](../06-esquema-jerarquico/README.md)
