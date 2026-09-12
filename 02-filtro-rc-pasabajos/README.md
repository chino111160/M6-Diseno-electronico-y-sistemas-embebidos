# 02 — Filtro RC pasa-bajos

## Objetivo de aprendizaje

Sumar sobre el flujo del ejemplo 01: ahora el circuito tiene **más de 2
nets**, incluida una **net de 3 pines** (GND compartido entre entrada,
capacitor y salida) — la primera vez que vas a ver que una net no es
necesariamente un cable "de a dos". También calculás una frecuencia de
corte real, no solo copiás un valor.

## Prerrequisito

[01 — LED indicador básico](../01-led-indicador/README.md)

## Circuito y cálculo

```
J1.1 (IN) ──── R1 (1kΩ) ──┬──── J2.1 (OUT)
                           │
                          C1 (100nF)
                           │
J1.2 (GND) ───────────────┴──── J2.2 (GND)
```

Frecuencia de corte: `fc = 1 / (2π·R·C) = 1 / (2π · 1000Ω · 100nF) ≈ 1.6 kHz`

Por encima de esa frecuencia, la señal en la salida se atenúa — es el
filtro pasa-bajos más simple que existe.

## Lista de materiales (BOM)

| Ref | Componente | Valor | Notas |
|---|---|---|---|
| R1 | Resistencia | 1 kΩ | del catálogo del workspace, categoría "Resistors" |
| C1 | Capacitor cerámico | 100 nF | categoría "Capacitors" |
| J1 | Header 2 pines | — | entrada (señal + GND) |
| J2 | Header 2 pines | — | salida (señal + GND) |

## Pasos en Altium Designer

### 1. Crear el proyecto (local, no cloud)
1. `File → New → Project`.
2. En "Locations" elegí **"Local Projects"** (importante — si no, se crea
   vinculado al workspace de Altium 365).
3. Project Type: **PCB → `<Empty>`**.
4. Nombre: `02-filtro-rc-pasabajos`. Folder: esta misma carpeta
   (`02-filtro-rc-pasabajos/`).
5. **Create**.

### 2. Agregar el esquema
Click derecho en el proyecto → `Add New to Project` → `Schematic`.

### 3. Colocar los componentes (panel Components, catálogo del workspace)
Para cada uno: cambiar el filtro de categoría en el dropdown de arriba del
panel → buscar el valor → **doble click** para activar la colocación →
**un solo click** en la hoja para colocarlo → **Escape** inmediatamente
(no mover el mouse antes de soltar la herramienta, para evitar colocar
copias de más).

1. Categoría **Resistors**, buscar `1k` → colocar como R1.
2. Categoría **Capacitors**, buscar `100nF` → colocar como C1.
3. Categoría **Connectors**, buscar `header` → elegir uno de 2 pines
   (nombre tipo `S2B-PH-K-S...`) → colocar dos veces, uno como J1 (entrada,
   a la izquierda) y otro como J2 (salida, a la derecha).

### 4. Cablear
1. `Place → Wire`.
2. J1.1 → R1.1 (entrada a la resistencia).
3. R1.2 → C1.1 **y** → J2.1 (el nodo de salida se conecta a los dos: al
   capacitor y a la salida). Podés cablear R1.2→C1.1 y después R1.2→J2.1
   por separado, o desde el mismo punto.
4. J1.2 → C1.2 (GND de entrada al capacitor).
5. C1.2 → J2.2 (GND del capacitor a GND de salida) — esto completa la net
   de 3 pines (J1.2, C1.2, J2.2 todos en la misma net de GND).

### 5. Etiquetar las nets (opcional pero recomendado esta vez)
A diferencia del ejemplo 01 (donde dejamos que Altium nombrara las nets
automáticamente), acá conviene usar `Place → Net Label` para poner
nombres explícitos: `IN` en J1.1, `OUT` en J2.1, `GND` en la net
compartida. Hace que el PCB después sea mucho más legible.

### 6. Verificar (ERC)
`Project → Validate PCB Project` → revisar Messages → debería compilar
sin errores, con **3 nets** (IN-a-R1, la net de salida R1.2/C1.1/J2.1, y
GND).

### 7. Pasar al PCB
1. Agregar el PCB: click derecho en el proyecto → `Add New to Project` →
   `PCB`.
2. Guardarlo (`Ctrl+S`) en esta misma carpeta antes de continuar (si no,
   el siguiente paso falla con "Cannot Locate Document").
3. Desde el esquema: `Design → Update PCB Document` (o desde el PCB:
   `Design → Import Changes From ...`).
4. `Validate Changes` → `Execute Changes`.

### 8. Definir el contorno de la placa
1. Capa **Mechanical 1**.
2. `Place → Line`, dibujar un rectángulo cerrado alrededor de los 4
   componentes, **Escape**.
3. `Ctrl+A` para seleccionar todo, `Design → Board Shape → Define from
   selected objects`. Si falla por "no closed shape", elegí "Yes" para
   intentar con bordes externos.

### 9. Placement
Alejá J1 a la izquierda y J2 a la derecha (entrada/salida en los bordes
opuestos de la placa, como en un filtro real), con R1 y C1 en el medio.

### 10. Rutar
`Route → Interactive Routing`, conectar las 4 pistas (3 nets, una de
ellas con 3 puntos — vas a necesitar 2 segmentos de pista para esa,
uno por cada tramo del GND).

### 11. DRC y Gerbers
Igual que en el ejemplo 01: `Tools → Design Rule Check`, después
`File → Fabrication Outputs → Gerber Files` y `NC Drill Files`.

## Checklist de verificación

- [ ] El ERC compila sin errores.
- [ ] Hay exactamente 3 nets (o las que resulten de tu etiquetado).
- [ ] La net de GND tiene 3 pines conectados (J1.2, C1.2, J2.2) — podés
      confirmarlo en el panel PCB → Nets, o revisando `PCB1.NetXXX` en el
      árbol de Nets del proyecto.
- [ ] DRC sin violaciones de Clearance ni Short-Circuit (el warning de
      silkscreen, si aparece, no es bloqueante).
- [ ] Sabés explicar qué significa la frecuencia de corte y por qué el
      circuito atenúa frecuencias altas.

**Siguiente**: [03 — Fuente lineal regulada](../03-fuente-lineal-regulada/README.md)
