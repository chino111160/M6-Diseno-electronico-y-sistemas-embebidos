# 06 — Esquema jerárquico multi-hoja

## Objetivo de aprendizaje

Hasta ahora todos los circuitos entraron en **una sola hoja**. Los diseños
reales (como el "Sample - Kame_FMU" que vimos por API, que tenía 8 hojas)
no. Acá aprendés a **descomponer** un diseño grande en bloques
manejables:

- **Sheet symbols** — representar un sub-circuito completo como una caja
  en una hoja de nivel superior.
- **Ports y sheet entries** — cómo se conectan eléctricamente las hojas
  entre sí.
- **Buses** — agrupar varias señales relacionadas (ej. 4 líneas de datos)
  en una sola línea visual.
- **Diseño multicanal** — repetir el mismo bloque N veces (por ejemplo,
  4 canales idénticos de LED) sin duplicar el trabajo de diseño.
- **Rooms en el PCB** — agrupar físicamente los componentes de cada hoja
  en una zona del PCB, en vez de que Altium los mezcle.

## Prerrequisito

Ejemplos 01 a 05 (este combina ideas de varios: la fuente del 03, el
antirrebote del 04)

## El diseño: una placa con fuente + 2 canales de entrada

Vamos a estructurar así:

```
Top.SchDoc
├── Sheet Symbol: Power    → Power.SchDoc  (la fuente del ejemplo 03)
├── Sheet Symbol: Channel1 → Channel.SchDoc (antirrebote del ejemplo 04)
└── Sheet Symbol: Channel2 → Channel.SchDoc (¡el mismo documento, repetido!)
```

`Channel1` y `Channel2` van a usar el **mismo archivo** `Channel.SchDoc`
— eso es diseño multicanal: un solo esquema de sub-circuito, instanciado
2 veces, cada instancia con sus propios designadores (Channel1 tendrá
R1/C1/U1, Channel2 tendrá R2/C2/U2, asignados automáticamente).

## Lista de materiales (BOM)

Reutilizamos los BOM de los ejemplos 03 y 04 (fuente + 2× antirrebote).
No hace falta volver a elegir componentes del catálogo si ya sabés cuáles
usaste ahí — este ejemplo es sobre **organización**, no sobre componentes
nuevos.

## Pasos en Altium Designer

### 1. Crear el proyecto y las hojas hijas primero
1. `File → New → Project` (local, como siempre).
2. Agregá **3 documentos de esquema**: `Power.SchDoc`, `Channel.SchDoc`,
   y `Top.SchDoc` (este último va a ser la hoja de nivel superior).
3. En `Power.SchDoc`, recreá (o copiá/pegá) el circuito del ejemplo 03.
4. En `Channel.SchDoc`, recreá el circuito del ejemplo 04.

### 2. Agregar Ports a las hojas hijas
Los **Ports** son los "conectores" de una hoja hacia el mundo exterior
(hacia quien la instancie).
1. En `Power.SchDoc`: `Place → Port`, colocá uno llamado **"VCC"** cerca
   de la salida de tu regulador, y otro **"GND"**.
2. En `Channel.SchDoc`: agregá un Port **"VCC"**, uno **"GND"**, y uno
   **"OUT"** (la salida ya "limpia" del antirrebote).
3. El **nombre** del port es lo que importa — dos ports con el mismo
   nombre en hojas distintas, conectadas a través de una jerarquía, se
   consideran la misma señal.

### 3. Crear el Sheet Symbol de Power en Top.SchDoc
1. Abrí `Top.SchDoc`.
2. `Design → Create Sheet Symbol From Sheet` → elegí `Power.SchDoc`.
3. Altium genera automáticamente un rectángulo (el sheet symbol) con
   **Sheet Entries** en los bordes, una por cada Port que definiste en
   `Power.SchDoc` (VCC, GND).

### 4. Crear el Sheet Symbol de Channel — dos veces
1. Repetí `Design → Create Sheet Symbol From Sheet` con `Channel.SchDoc`,
   dos veces, para tener dos sheet symbols en `Top.SchDoc`.
2. Renombralos (doble click en cada uno) como **"Channel1"** y
   **"Channel2"** — el nombre del sheet symbol es lo que le da la
   identidad a cada instancia (así Altium sabe que son 2 canales
   distintos aunque apunten al mismo archivo `Channel.SchDoc`).

### 5. Cablear entre sheet symbols en Top.SchDoc
1. Conectá la Sheet Entry "VCC" del symbol Power con la Sheet Entry "VCC"
   de Channel1 y de Channel2 (todas a la misma net — podés usar un
   **Net Label "VCC"** en vez de cables directos si se cruzan mucho).
2. Repetí para GND.
3. Agregá 2 Ports de salida en `Top.SchDoc` (o dos headers directos) para
   sacar las señales OUT de Channel1 y Channel2 hacia afuera de la placa.

### 6. Verificar la jerarquía
1. `Project → Validate PCB Project`.
2. En el panel Messages no debería haber errores de "port not matched" ni
   duplicados.
3. Abrí el panel **Navigator** (o el árbol de Projects) y confirmá que
   ves la estructura: Top → Power, Top → Channel1, Top → Channel2.
4. Revisá los designadores: los componentes de Channel1 deberían quedar
   como R1/C1/U1 (o similar) y los de Channel2 como R2/C2/U2 —
   automáticamente diferenciados por instancia.

### 7. (Opcional) Usar un Bus
Si en tu diseño tuvieras varias señales relacionadas viajando juntas
entre hojas (por ejemplo, si cada canal sacara 2 señales en vez de 1),
podés agruparlas:
1. `Place → Bus`, dibujá una línea gruesa entre las hojas.
2. Cada señal individual se conecta al bus con `Place → Bus Entry`, y se
   nombra con un patrón como `DATA[0..1]`.
3. Para este ejemplo con una sola señal OUT por canal no es
   estrictamente necesario, pero vale la pena practicarlo si tu circuito
   real (ejemplo 07 o tu proyecto de maestría) lo necesita.

### 8. Pasar al PCB y usar Rooms
1. Agregá el documento PCB al proyecto, actualizalo desde `Top.SchDoc`
   (el ECO va a traer TODOS los componentes de las 3 hojas).
2. Definí el contorno de la placa.
3. `Design → Rooms → Place Room` (o seleccioná los componentes de
   Channel1 y usá "Room from selection"): creá una región rectangular y
   asignale la clase de componentes "Channel1".
4. Repetí para Channel2 y para Power.
5. Ahora, cuando muevas el Room completo, todos sus componentes se mueven
   juntos — mucho más ordenado que mover componente por componente en un
   diseño de 3+ bloques.

### 9-11. Rutar, DRC, Gerbers
Igual que siempre, ahora con 3 bloques físicamente organizados.

## Checklist de verificación

- [ ] `Power.SchDoc` y `Channel.SchDoc` tienen sus Ports correctamente
      nombrados.
- [ ] Hay 2 instancias del sheet symbol de Channel en `Top.SchDoc`,
      nombradas distinto (Channel1/Channel2).
- [ ] Los componentes de cada canal tienen designadores diferenciados
      automáticamente (no hay 2 "R1" en el proyecto).
- [ ] `Project → Validate PCB Project` sin errores de jerarquía.
- [ ] En el PCB, los 3 Rooms agrupan visualmente cada bloque.
- [ ] DRC final sin errores.

## Errores clásicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| "Port VCC not matched" al validar | El nombre del Port no coincide exactamente entre hojas (mayúsculas, espacios) | Revisar y unificar el nombre exacto en cada Port |
| Los 2 canales comparten designadores (ambos "R1") | Los sheet symbols no se crearon como instancias separadas correctamente | Verificar que sean 2 sheet symbols distintos apuntando al mismo .SchDoc, no el mismo symbol duplicado |
| Al mover un Room, algunos componentes se quedan afuera | El Room no incluye la clase de componentes completa | Revisar la definición de la clase de componentes asociada al Room |
| El ECO no trae los componentes de una de las hojas hijas | La hoja no está realmente vinculada por un sheet symbol válido | Confirmar que el sheet symbol apunte al archivo correcto (propiedades del symbol) |

**Siguiente**: [07 — Sistema mínimo de MCU](../07-sistema-minimo-mcu-generico/README.md)
