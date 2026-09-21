# Ejemplos de aplicación — Altium Designer

### M6 Diseño electrónico y sistemas embebidos

Serie de ejemplos progresivos para aprender el flujo completo de Altium Designer
(esquemático → PCB → fabricación), de lo más simple a lo más complejo. No están
atados a una familia de microcontrolador específica: cada ejemplo enseña un
bloque de diseño que después vas a reutilizar en proyectos reales, sea con
STM32, PIC, AVR o lo que uses más adelante.

## Cómo usar esta carpeta

Cada subcarpeta `NN-nombre/` es un ejemplo independiente con su propio `README.md`
que incluye:

* **Objetivo de aprendizaje** — qué concepto/habilidad te lleva puesta al terminar.
* **Prerrequisitos** — qué ejemplo(s) previo(s) conviene haber hecho antes.
* **Cálculos** — la aritmética que justifica cada valor de componente.
* **Lista de materiales (BOM)** — componentes y sus referencias típicas.
* **Esquema de referencia** — descripción/ASCII del circuito a capturar.
* **Pasos en Altium Designer** — instrucciones concretas (menús, comandos).
* **Reglas de diseño de PCB** — qué configurar en Design Rules antes de rutar.
* **Checklist de verificación** — ERC/DRC y qué revisar antes de dar por
terminado el ejemplo.
* **Errores clásicos** — tabla de síntoma → causa → arreglo.

Los archivos de proyecto de Altium (`.PrjPcb`, `.SchDoc`, `.PcbDoc`) son binarios
propietarios — Claude no puede crearlos ni editarlos directamente. Vos los
armás en Altium Designer siguiendo la guía; yo te ayudo con las instrucciones,
las decisiones de diseño, el BOM, las notas técnicas y cualquier archivo de
texto plano del proyecto (netlists exportados, reportes, scripts).

## Roadmap

|#|Ejemplo|Habilidad principal|Estado|
|-|-|-|-|
|01|[LED indicador básico](01-led-indicador/README.md)|Captura de esquema y PCB desde cero, librerías, ERC/DRC básico|✔️ Completado|
|02|[Filtro RC pasa-bajos](02-filtro-rc-pasabajos/README.md)|Múltiples nets, conectores de entrada/salida, footprints pasivos SMD|✔️ Completado|
|03|[Fuente lineal regulada (7805/LM317)](03-fuente-lineal-regulada/README.md)|Diseño de potencia, análisis térmico, plano de cobre, clases de nets|✅ Guía completa|
|04|[Antirrebote de pulsador](04-antirrebote-pulsador/README.md)|Lógica digital, pull-up, debounce RC + Schmitt, componentes multi-parte|✅ Guía completa|
|05|[Acondicionador de señal (op-amp)](05-acondicionador-opamp/README.md)|Diseño analógico single-supply, simulación SPICE, SMD, ActiveBOM|✅ Guía completa|
|06|[Esquema jerárquico multi-hoja](06-esquema-jerarquico/README.md)|Sheet symbols, puertos, buses, multicanal, rooms en el PCB|✅ Guía completa|
|07|[Sistema mínimo de MCU (STM32F103)](07-sistema-minimo-mcu-generico/README.md)|Desacople, reset, boot, cristales, SWD, layer stack, 3D, Draftsman|✅ Guía completa|
|08|[Placa de entrenamiento integradora](08-placa-entrenamiento-integradora/README.md)|Capstone: especificación, mapa de pines, presupuesto, particionado, bring-up, design review|✅ Guía completa|

**Convención de estados**: ✅ guía completa lista · 🔜 objetivo definido, guía
detallada pendiente de desarrollar · 🚧 en progreso · ✔️ completado por vos en Altium.

## Progreso

Los ejemplos 01 y 02 ya los armaste en Altium. Las guías de los ejemplos **03
a 08 están escritas y listas para seguir**, en orden: cada una supone que
hiciste las anteriores y va sumando exactamente un concepto nuevo de diseño y
una o dos herramientas nuevas de Altium.

El **08 es el capstone**: integra los bloques de los ejemplos 03 a 07 en una
sola placa con STM32F103 y agrega lo que no se aprende haciendo bloques
sueltos — especificación previa, mapa de asignación de pines, presupuesto de
potencia, re-escalado de un bloque a otra tensión de alimentación,
particionado del layout, procedimiento de bring-up y revisión de diseño.

### Lo nuevo que aporta cada ejemplo

|#|Concepto de diseño nuevo|Herramienta de Altium nueva|
|-|-|-|
|03|Análisis térmico, ancho de pista IPC-2221, protección de polaridad|Clases de nets, prioridad de reglas, polygon pour|
|04|Rebote de contactos, histéresis, pull-up vs. pull-down|Componentes multi-parte, pines ocultos, import/export de reglas (`.RUL`)|
|05|Alimentación simple, referencia virtual, polos de acoplo, GBW|Simulación SPICE (AC sweep y transitorio), SOIC/SMD, ActiveBOM|
|06|Descomposición funcional de un diseño grande|Jerarquía, ports/sheet entries, buses, multicanal, rooms|
|07|Los cinco bloques del sistema mínimo, cálculo de cristales|Layer Stack Manager, reglas según el fabricante, fanout, 3D, Draftsman|
|08|Integración: interfaces entre bloques, mapa de pines, presupuesto, particionado, bring-up|Output Job, Project Releaser, variantes de ensamblaje, Show Differences|

## Automatización — Altium 365 Workspace

Aparte de los ejemplos de diseño, hay una pieza de automatización en
[`altium-365-sync/`](altium-365-sync/README.md): un script Python (para
correr desde la extensión **Altium Developer** de VS Code) que sincroniza
metadata de tu workspace de Altium 365 hacia esta carpeta local. Es la base
sobre la que después vamos a montar el flujo en Docker que quedó pendiente.

