# 04 — Antirrebote de pulsador (debounce)

## Objetivo de aprendizaje

Tu primer circuito **digital**, y la primera vez que vas a usar un
componente con **múltiples partes** (un chip con varias compuertas
idénticas adentro, donde elegís cuál usar). También vas a:

- Entender qué es el **rebote de contactos** (bounce) y por qué un
  microcontrolador vería varios pulsos donde vos apretaste una sola vez.
- Diseñar un **debounce por hardware** (RC + Schmitt trigger), la
  alternativa a hacerlo por software.
- Trabajar con **pines ocultos** (power pins que Altium no siempre
  muestra en el esquema).
- Exportar/importar **reglas de diseño** como archivo `.RUL` reutilizable.

## Prerrequisito

[01 — LED indicador básico](../01-led-indicador/README.md)

## El problema del rebote

Un pulsador mecánico no hace un contacto limpio: al presionarlo, la
lámina metálica rebota físicamente varias veces en microsegundos antes de
asentarse. Sin corregirlo, un microcontrolador leyendo ese pin puede
contar "5 clicks" cuando vos apretaste una sola vez.

## Cálculo del RC de debounce

```
τ = R × C
```
Con R=10kΩ y C=100nF:
```
τ = 10,000Ω × 100×10⁻⁹F = 1ms
```
Un rebote mecánico típico dura entre 1-20ms. Elegimos una constante de
tiempo de ~1ms para el RC, y el **Schmitt trigger** (con su histéresis)
hace el resto: solo conmuta su salida cuando la señal cruza claramente un
umbral alto o bajo, ignorando el ruido/rebote de la carga/descarga del
capacitor.

## Lista de materiales (BOM)

| Ref | Componente | Valor | Notas |
|---|---|---|---|
| SW1 | Pulsador táctil | — | Normalmente abierto (NO) |
| R1 | Resistencia | 10kΩ | Pull-up |
| C1 | Capacitor cerámico | 100nF | Debounce |
| U1 | Hex Schmitt Inverter | 74HC14 | Usamos **una sola compuerta** de las 6 que trae |
| C2 | Capacitor cerámico | 100nF | Desacople de U1 (entre VCC y GND, pegado al chip) |
| J1 | Header 2 pines | — | Salida de la señal ya "limpia" |
| J2 | Header 2 pines | — | Alimentación (VCC, GND) |

## Esquema de referencia

```
VCC ──┬── R1(10k) ──┬── U1A(74HC14, 1 de 6 compuertas) ── J1.1 (salida limpia)
      │             │
      C2           SW1 ── GND
      │             │
     GND           C1(100nF)
                     │
                    GND
```

Pull-up: cuando el botón NO está presionado, el pin de entrada de U1A
queda en VCC (alto) a través de R1. Al presionar SW1, el nodo va a GND —
la lógica se invierte a la salida por ser un inversor.

## Pasos en Altium Designer

### 1-2. Proyecto y esquema
Igual que en ejemplos anteriores.

### 3. Colocar el 74HC14 — componente multi-parte
1. Buscá **"74HC14"** en el catálogo (categoría Integrated Circuits).
2. Al colocarlo, Altium te va a preguntar (o mostrar automáticamente)
   **qué parte** del chip estás colocando — el 74HC14 trae 6 compuertas
   Schmitt inverter idénticas (A, B, C, D, E, F) en un solo encapsulado.
3. Elegí la **Parte A** (usamos una sola compuerta; las otras 5 quedan
   sin usar en este diseño — es normal, no hace falta cablearlas).

### 4. Ver los pines de alimentación (pines ocultos)
Muchos símbolos de chips lógicos **no muestran** los pines de VCC/GND en
el símbolo de cada compuerta — están marcados como "hidden" y Altium los
conecta automáticamente a nets llamadas VCC/GND si existen en el diseño.
1. `View → Toggle Special Strings` o abrí las propiedades del componente
   (doble click sobre U1) y buscá la pestaña con la lista de pines.
2. Confirmá que existan pines VCC (pin 14) y GND (pin 7) del 74HC14,
   aunque no se vean dibujados en el símbolo de la compuerta.
3. **Importante**: como estos pines son "hidden" y se auto-conectan por
   nombre de net, asegurate de que tu net de alimentación se llame
   exactamente **VCC** y **GND** (con `Place → Net Label`) para que
   coincida.

### 5. Colocar el resto y cablear
R1, C1, SW1, C2, J1, J2 según el esquema de referencia. Etiquetá las nets
VCC y GND explícitamente con Net Labels (paso previo necesario para que
los pines ocultos de U1 se conecten bien).

### 6. ERC
`Project → Validate PCB Project`. Si ves un warning sobre pines de U1 sin
usar (las otras 5 compuertas), es esperable — podés dejarlo o silenciarlo
en las reglas de ERC si te molesta visualmente.

### 7. Exportar las reglas de diseño (.RUL)
Antes de pasar al PCB, practiquemos algo reutilizable:
1. `Design → Rules` → configurá tus reglas de clearance/ancho como en el
   ejemplo 03 (o dejá las por defecto si preferís simplicidad acá).
2. Abajo del diálogo de reglas, botón **"Report"** o menú contextual →
   **"Export Rules"** → guardalo como `reglas-basicas.RUL` en esta misma
   carpeta.
3. Esto te sirve para **importar** el mismo set de reglas en futuros
   proyectos (`Design → Rules → Import Rules`) sin reconfigurar todo de
   cero cada vez.

### 8-11. PCB, placement, rutado, DRC, Gerbers
Igual que en los ejemplos anteriores. El 74HC14 en DIP-14 o SOIC-14 es tu
primer footprint con más de 4 pines — prestá atención al pin 1 (marca
circular/muesca) al orientarlo.

## Checklist de verificación

- [ ] Elegiste la Parte A del 74HC14 (u otra, pero solo una).
- [ ] Los pines de alimentación del chip (ocultos) están correctamente
      auto-conectados a VCC/GND (confirmalo en el panel Nets — el chip
      debería aparecer en esas nets aunque no dibujaste esos pines a mano).
- [ ] Exportaste el archivo `.RUL` a esta carpeta.
- [ ] ERC sin errores (warnings de compuertas no usadas son aceptables).
- [ ] DRC sin errores eléctricos.
- [ ] Sabés explicar con tus palabras qué hace el capacitor C1 y por qué
      el Schmitt trigger es mejor que un inversor común acá.

## Errores clásicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| El chip no aparece conectado a VCC/GND en el PCB | La net no se llama exactamente "VCC"/"GND" | Renombrá el Net Label para que coincida exacto (case-sensitive) |
| ERC marca "unused gates" en U1 | Normal, dejaste 5 de 6 compuertas sin usar | No es un error real, podés ignorarlo o filtrarlo en las reglas de ERC |
| El botón no debounce bien en la práctica | Constante RC muy chica para tu pulsador específico | Aumentar C1 (ej. a 220nF o 470nF) y recalcular τ |
| Al importar el .RUL en otro proyecto no aplica nada | Las reglas exportadas eran solo las que tenías definidas explícitamente (no las por defecto) | Revisar qué reglas quedaron realmente en el archivo antes de asumir que está todo cubierto |

**Siguiente**: [05 — Acondicionador de señal con op-amp](../05-acondicionador-opamp/README.md)
