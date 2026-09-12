# 01 — LED indicador básico

## Objetivo de aprendizaje

Recorrer el flujo completo de Altium Designer por primera vez, de punta a
punta, con el circuito más simple posible: un LED limitado por resistencia,
alimentado por una fuente externa vía conector. Al terminar vas a saber:

- Crear un proyecto de Altium (`.PrjPcb`) con sus documentos de esquema y PCB.
- Buscar y colocar componentes desde una librería.
- Cablear un esquema y asignarle un footprint a cada símbolo.
- Correr el ERC (Electrical Rules Check) y entender sus mensajes.
- Generar el netlist e importarlo al PCB.
- Ubicar componentes, rutar pistas manualmente en una placa de 2 capas.
- Correr el DRC (Design Rules Check) y corregir errores típicos.
- Generar los archivos de fabricación (Gerbers + drill) de un proyecto real.

## Prerrequisitos

Ninguno — es el punto de partida. Solo necesitás Altium Designer instalado
(con licencia activa o de estudiante) y las librerías genéricas que vienen
por defecto (`Miscellaneous Devices.IntLib`, `Miscellaneous Connectors.IntLib`).

## Lista de materiales (BOM)

| Ref | Componente | Valor / Parte | Footprint sugerido | Librería |
|---|---|---|---|---|
| R1 | Resistencia | 330 Ω (1/4 W) | AXIAL-0.4 (THT) o R0805 (SMD) | Miscellaneous Devices.IntLib |
| D1 | LED | LED rojo 5mm o 0805 | LED-5MM (THT) o LED0805 (SMD) | Miscellaneous Devices.IntLib |
| J1 | Conector de alimentación | Header 2 pines, 2.54mm | HDR1X2 | Miscellaneous Connectors.IntLib |

> Elegí THT (through-hole) si es tu primera placa — es más fácil de soldar y
> de rutar a mano. Podés repetir el ejercicio en SMD después.

## Esquema de referencia

```
J1-1 (VCC, ej. 5V) ──── R1 (330Ω) ──── D1 (ánodo →│← cátodo) ──── J1-2 (GND)
```

Cálculo de R1 (para validar el valor, no hace falta que lo repitas si usás
5V/LED rojo estándar): `R = (Vcc - Vf_led) / I_led = (5V - 2V) / 0.01A = 300Ω`
→ 330Ω es el valor comercial más cercano por arriba (más seguro, menor corriente).

## Pasos en Altium Designer

### 1. Crear el proyecto
1. `File → New → Project` → elegí **PCB Project** → nombralo `01-led-indicador`.
2. Guardalo dentro de esta carpeta (`01-led-indicador/`).
3. `File → New → Schematic` dentro del proyecto → guardalo como `led-indicador.SchDoc`.
4. `File → New → PCB` dentro del proyecto → guardalo como `led-indicador.PcbDoc`.

### 2. Capturar el esquema
1. Abrí el panel de librerías (`View → Panels → Libraries` o `Place → Part`).
2. Buscá `RES2` (resistencia) en `Miscellaneous Devices.IntLib`, colocalo como R1.
3. Buscá `LED` en la misma librería, colocalo como D1.
4. Buscá `Header 2` en `Miscellaneous Connectors.IntLib`, colocalo como J1.
5. Editá los valores: doble click en R1 → `Comment/Value = 330`. Doble click
   en D1 → confirmá que sea LED rojo genérico.
6. Cableá con la herramienta `Place → Wire` (atajo `P, W`) siguiendo el
   esquema de referencia de arriba.
7. Etiquetá las redes de alimentación con `Place → Net Label`: `VCC` en
   J1 pin 1, `GND` en J1 pin 2.

### 3. Verificar el esquema (ERC)
1. `Project → Validate PCB Project`.
2. Revisá el panel `Messages`. En este circuito no debería haber errores;
   si aparece un warning de "unconnected pin", revisá el cableado.

### 4. Asignar footprints
1. Doble click en cada componente → pestaña `Footprint` → confirmá que ya
   tenga asignado el footprint sugerido en el BOM (las librerías genéricas
   ya traen uno por defecto; si no, agregalo manualmente con `Add Footprint`).

### 5. Pasar al PCB
1. Con el esquema abierto: `Design → Update PCB Document led-indicador.PcbDoc`.
2. Revisá el Engineering Change Order (ECO) → `Validate Changes` → `Execute Changes`.
3. Los tres componentes aparecen en el PCB, fuera del contorno de la placa.

### 6. Definir el contorno de la placa
1. En el PcbDoc, seleccioná la capa `Keep-Out Layer` o `Mechanical 1`.
2. `Place → Line` (o `Design → Board Shape → Redefine Board Shape`) y dibujá
   un rectángulo simple, por ejemplo 20mm x 15mm.

### 7. Ubicar componentes (placement)
1. Arrastrá R1, D1 y J1 dentro del contorno de la placa.
2. Ordenalos siguiendo el flujo de la señal (J1 → R1 → D1) para que el
   rutado sea corto y directo.

### 8. Rutar
1. Configurá las reglas de diseño primero (paso siguiente) o usá el ancho
   de pista por defecto (10 mil) para este ejemplo simple.
2. `Route → Interactive Routing` (atajo `Ctrl+M` o el ícono correspondiente)
   y conectá las dos pistas: VCC→R1→D1 y D1→GND.
3. Usá dos capas si tu footprint es SMD; con THT alcanza con una sola capa
   de cobre (Bottom Layer) para este circuito tan simple.

### 9. Reglas de diseño (Design Rules)
1. `Design → Rules` → revisá `Clearance` (dejalo en el default, 10 mil) y
   `Width` (10-15 mil está bien para esta corriente baja).
2. Esto es más relevante en los ejemplos siguientes con más componentes;
   acá el objetivo es que aprendas dónde se configura.

### 10. Verificar el PCB (DRC)
1. `Tools → Design Rule Check`.
2. `Run Design Rule Check` → revisá el reporte. No debería haber violaciones.

### 11. Generar archivos de fabricación
1. `File → Fabrication Outputs → Gerber Files` → dejá la configuración por
   defecto → `OK`.
2. `File → Fabrication Outputs → NC Drill Files` para los taladros.
3. Los archivos se guardan en una subcarpeta `Project Outputs for
   01-led-indicador/` dentro de tu proyecto.

## Checklist de verificación

- [ ] El ERC no reporta errores (warnings menores son aceptables si entendés
      por qué aparecen).
- [ ] Los tres componentes tienen footprint asignado antes de pasar al PCB.
- [ ] El DRC no reporta violaciones de clearance ni de ancho de pista.
- [ ] Podés abrir los Gerbers generados en un visor (ej. el visor integrado
      de Altium, `View Fabrication Outputs`, o gerbv/KiCad Gerber Viewer)
      y se ve el layout esperado.
- [ ] Sabés explicar, sin mirar la guía, para qué sirve cada paso (proyecto
      → esquema → ERC → footprints → PCB → placement → rutado → DRC → Gerbers).

## Qué deberías haber aprendido

El flujo completo de Altium Designer en su forma más simple. Todos los
ejemplos siguientes repiten esta misma secuencia de 11 pasos, agregando una
sola idea nueva por vez (más nets, más componentes, planos de cobre,
jerarquía, etc.) — no hace falta memorizar nada nuevo del flujo en sí, solo
vas a ir sumando piezas.

**Siguiente**: [02 — Filtro RC pasa-bajos](../02-filtro-rc-pasabajos/README.md)
