# 03 — Fuente lineal regulada (7805)

## Objetivo de aprendizaje

Tu primer circuito de **potencia real**. Hasta ahora las corrientes eran
mínimas (un LED, una señal). Acá vas a aprender a:

- Calcular el **ancho de pista** según la corriente que va a circular (no
  todo ancho de pista sirve para todo).
- Hacer un **análisis térmico** simple: cuánta potencia disipa el
  regulador y si necesita disipador.
- Usar **clases de nets** (Net Classes) para aplicarle una regla distinta
  a las pistas de potencia vs. las de señal.
- Agregar **protección de polaridad inversa** con un diodo.
- Poner un **plano de cobre** (polygon pour) de GND.

## Prerrequisito

[02 — Filtro RC pasa-bajos](../02-filtro-rc-pasabajos/README.md)

## Cálculos

### Disipación de potencia del regulador
Un 7805 regula linealmente: toda la diferencia de tensión que no sale por
la carga se disipa como calor.

```
Pd = (Vin - Vout) × Iout
```

Ejemplo con Vin=9V, Vout=5V, Iout=500mA:
```
Pd = (9V - 5V) × 0.5A = 2W
```

### Temperatura de juntura
```
Tj = Ta + Pd × Rth(j-a)
```
Con un 7805 en TO-220 sin disipador (`Rth(j-a) ≈ 65°C/W`) y `Ta = 25°C`:
```
Tj = 25°C + 2W × 65°C/W = 155°C
```
Eso está **peligrosamente cerca** del límite típico de 150°C — con esta
combinación de tensiones necesitarías un disipador, o bajar la corriente,
o usar un regulador switching. Para el ejercicio vamos a diseñar para
**Iout=200mA** (Pd=0.8W, Tj≈77°C — seguro sin disipador) y vas a dejar
documentado en el esquema por qué.

### Ancho de pista (IPC-2221, aproximado)
Para pistas externas (capa Top/Bottom), 1oz de cobre, ΔT=10°C:
- 200mA → ~8 mil es de sobra; usamos **25 mil** para las pistas de
  potencia (más margen, más fácil de rutar a mano) y **10 mil** para señal.
- Esta es la razón de crear una **Net Class "Power"** con su propia regla
  de ancho, en vez de dejar todo con el ancho por defecto.

## Lista de materiales (BOM)

| Ref | Componente | Valor | Notas |
|---|---|---|---|
| J1 | Header 2 pines | — | Entrada de alimentación (Vin, GND) |
| D1 | Diodo rectificador | 1N4001 | Protección de polaridad inversa, en serie con Vin |
| C1 | Capacitor electrolítico | 10µF/25V | Entrada, cerca de U1 |
| C2 | Capacitor cerámico | 100nF | Entrada, en paralelo con C1 (alta frecuencia) |
| U1 | Regulador lineal | 7805 (TO-220) | Salida fija 5V |
| C3 | Capacitor cerámico | 100nF | Salida, cerca de U1 |
| C4 | Capacitor electrolítico | 10µF/16V | Salida |
| D2 | LED | rojo | Indicador de "encendido" |
| R1 | Resistencia | 1kΩ | Limitadora para D2 |
| J2 | Header 2 pines | — | Salida (5V, GND) |

## Esquema de referencia

```
J1.1(Vin) ──►D1──┬───────────────┬── U1.IN   U1.OUT ──┬───────────────┬── J2.1(5V)
                  C1             C2                    C3              C4
                  │              │                     │               │
J1.2(GND) ────────┴──────────────┴── U1.GND ───────────┴───────────────┴── J2.2(GND)
                                                          │
                                                         R1
                                                          │
                                                         D2 ── GND
```

`D1` en serie con Vin: si conectás la alimentación al revés, el diodo
bloquea la corriente en vez de dejar pasar corriente inversa que podría
dañar el regulador.

## Pasos en Altium Designer

Mismo flujo de los ejemplos 01-02 (proyecto local → esquema → catálogo de
componentes → cablear → ERC → PCB → placement → rutar → DRC → Gerbers),
con estos agregados:

### 1-4. Igual que antes
Crear proyecto local, agregar esquema, colocar los 10 componentes desde
el catálogo (categorías: Diodes, Capacitors, Integrated Circuits o buscar
"7805" directo, LED, Resistors, Connectors), cablear según el esquema de
referencia.

### 5. Crear la Net Class "Power"
1. `Design → Classes`.
2. Click derecho en **"Net Classes"** → **"Add Class"**.
3. Nombrala **"Power"**.
4. Arrastrá las nets de Vin, Vout y GND (las de mayor corriente) a esta
   clase — dejá las demás (la del LED, por ejemplo) en la clase por
   defecto.

### 6. Definir reglas de ancho por clase
1. `Design → Rules → Electrical → Width`.
2. Regla por defecto: **10 mil** (aplica a "All").
3. Nueva regla (click derecho → New Rule) que aplique solo a la clase
   **"Power"**: **25 mil** mínimo/preferido.
4. **Prioridad**: la regla de "Power" tiene que quedar **por encima** de
   la regla general en la lista de prioridades (`Design → Rules →
   Priorities`) — si no, Altium usa la primera que matchee y podría
   ignorar tu regla específica.

### 7. Placement y plano de cobre
1. Ubicá los componentes: J1 a la izquierda, D1-C1-C2-U1-C3-C4 en el
   medio (siguiendo el flujo de la señal), J2 a la derecha, D2/R1 aparte.
2. Dejá espacio alrededor de U1 (el TO-220) — sus pines son más grandes.
3. Definí el contorno de la placa como en los ejemplos anteriores.
4. `Place → Polygon Pour`, dibujá un polígono que cubra toda la placa en
   la capa **Bottom Layer**, asignalo a la net **GND**. Esto reemplaza
   todo el cobre libre de esa capa por un plano de tierra — reduce
   impedancia y ayuda a disipar calor del regulador.

### 8. Rutar
Las pistas de Vin/Vout deberían salir automáticamente con 25 mil (por la
regla de la clase Power) — confirmá el ancho real mientras ruteás. Las de
GND del lado top pueden ser más finas ya que el plano de abajo hace el
trabajo pesado.

### 9-11. DRC y Gerbers
Igual que antes. Además de los chequeos habituales, revisá que el
polígono se haya "vertido" bien (`Tools → Polygon Pours → Re-pour All` si
hace falta refrescarlo).

## Checklist de verificación

- [ ] D1 está orientado correctamente (banda catódica hacia U1, no hacia J1).
- [ ] La Net Class "Power" existe y tiene las 3 nets correctas.
- [ ] La regla de 25 mil tiene prioridad sobre la de 10 mil (revisar en
      `Design → Rules → Priorities`).
- [ ] Las pistas de Vin/Vout midieron realmente ~25 mil al rutar (no el
      default).
- [ ] El plano de GND está vertido y conectado (sin "islands" flotantes).
- [ ] DRC sin Clearance ni Short-Circuit.
- [ ] Podés explicar por qué diseñamos para 200mA y no para 500mA+.

## Errores clásicos

| Síntoma | Causa probable | Arreglo |
|---|---|---|
| La regla de 25mil no se aplicó, las pistas de potencia quedaron en 10mil | Prioridad de reglas al revés | `Design → Rules → Priorities`, subir la regla de la clase Power |
| DRC marca "Polygon needs repour" | El polígono no se actualizó tras mover componentes | `Tools → Polygon Pours → Re-pour All` |
| El regulador se calienta mucho en la práctica | Corriente real mayor a la calculada, o falta disipador | Recalcular Tj con la corriente real, agregar disipador o bajar Iout |
| ERC marca error en D1 | Diodo colocado al revés en el esquema | Verificar que el ánodo mire hacia J1 y el cátodo hacia U1 |

**Siguiente**: [04 — Antirrebote de pulsador](../04-antirrebote-pulsador/README.md)
