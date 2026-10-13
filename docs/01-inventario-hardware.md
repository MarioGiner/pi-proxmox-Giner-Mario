# Inventario investigado y viabilidad

## Contexto de la observacion

- Fecha y sistema utilizado: 13/10/2026, Ubuntu 22.04.
- Modalidad, equipo anfitrion y VM VirtualBox si procede: .
- Version de Proxmox prevista: PENDIENTE.

## Inventario inicial

| Area | Dato observado y evidencia | Especificacion y fuente | Limite o diferencia | Justificacion |
|---|---|---|---|---|
| CPU | Intel Pentium G4560 @ 3.50GHz, 2 nucleos / 4 hilos, 1 socket; flag `vmx` y `Virtualizacion: VT-x` presentes (lscpu -> evidencias/cpu.txt) | Kaby Lake, 2C/4T, 3.50 GHz, cache 3 MB, TDP 54 W, VT-x + VT-d + EPT, 2 canales de memoria (Intel ARK, ficha G4560) | CPU sin turbo y de gama baja; 4 hilos es el tope para repartir vCPU. Soporta VT-d, no imprescindible aqui | Cumple el requisito de virtualizacion por hardware de Proxmox (VT-x + EPT). Con 4 hilos se puede repartir vCPU entre Proxmox, srv-aso y cli-linux, aunque sin margen para cargas pesadas |
| RAM | 8 GB totales (7,6 GiB), 2x4 GB DDR4 Crucial a 2400 MT/s en ChannelA-DIMM1 y ChannelB-DIMM1 (doble canal); 2 slots libres; ~5,7 GiB disponibles (dmidecode + free -> evidencias/ram.txt) | Modulos Crucial CT4G4DFS824A.C8FBD2, DDR4-2400 UDIMM 1,2 V. Placa: max. 64 GB en 4 slots. CPU: max. 64 GB, DDR4-2133/2400 (dmidecode type 16; Intel ARK G4560) | Solo 8 GB instalados frente a 64 GB admitidos; quedan 2 slots libres, ampliable | Es el recurso mas ajustado. 8 GB limita cuantas maquinas pueden estar encendidas a la vez; hay margen de ampliacion fisica sin cambiar placa |
| Almacenamiento | SSD SATA Crucial MX500 250 GB (`sda`, ROTA=0), particion unica en `/`: 229 GB, 41 GB usados, 177 GB libres (19%); ademas USB Kingston 231 GB y lector optico `sr0` (lsblk + df -> evidencias/disco.txt) | Crucial MX500 CT250MX500SSD1: SATA III 6 Gb/s, TLC 3D NAND, lectura 560 MB/s, escritura 510 MB/s, resistencia 100 TBW (ficha Crucial MX500) | 177 GB libres para Proxmox + VM + ISOs + backups; un unico disco, sin redundancia | SSD aporta buen IOPS para varias VM. El espacio libre es suficiente pero justo si acumulas ISOs y copias; al ser un solo disco, no hay tolerancia a fallo fisico |
| Red | Realtek RTL8111/8168/8411 PCIe Gigabit, `eth0`, driver `r8169`, firmware rtl8168h-2, capacidad 1 Gbit/s; `link=no` / eth0 DOWN (sin cable) (lshw + ip -> evidencias/red.txt) | Controladora Realtek Gigabit Ethernet: 10/100/1000 Mb/s, autonegociacion, par trenzado (lshw; Realtek RTL8111H) | Tarjeta de 1 Gb por cable, pero en la captura el enlace estaba caido; interfaces virtuales de Docker/libvirt activas (docker0, virbr0, br-...) | Ethernet por cable a 1 Gb es lo idoneo para el bridge de Proxmox. Hay que conectar el cable: con `link=no` no hay conectividad real. Conviene vigilar el direccionamiento de las redes virtuales existentes para no solaparlo |
| Plataforma | Equipo PC613; BIOS American Megatrends (AMI) version 0810, revision 5.12, fecha 09/08/2017 (dmidecode -t bios -> evidencias/plataforma.txt) | BIOS AMI; placa con chipset compatible Kaby Lake (socket LGA1151), soporte VT-x activable en firmware | BIOS de 2017 sin actualizar; conviene verificar en el firmware que VT-x esta habilitado y el modo de arranque (UEFI/Legacy) | VT-x aparece activo en `lscpu`, luego la virtualizacion esta habilitada en BIOS. La antiguedad del firmware no impide instalar Proxmox, pero es un dato a registrar para la defensa |

## 1. Puedo instalar Proxmox en este equipo?

Contrastar el inventario con requisitos oficiales de la version prevista.
Responder por separado y justificar con datos y fuentes:

- Puedo instalar y arrancar Proxmox: SI.**
  El equipo cumple los requisitos de instalacion. CPU de 64 bits (x86_64) con
  VT-x activo y EPT, que es justo el requisito obligatorio para la
  virtualizacion completa KVM (lscpu: flag `vmx`, `Virtualizacion: VT-x`). RAM
  de 8 GB, muy por encima del minimo de 2 GB para el sistema y los servicios de
  Proxmox. Disco SSD de 250 GB con 177 GB libres, suficiente para el sistema.
  Una NIC Ethernet Gigabit (Realtek RTL8111), que cubre el requisito de "una
  NIC". Fuente: Proxmox VE System Requirements (minimo: CPU 64 bits con Intel
  VT/AMD-V, 1 GB RAM, un disco, una NIC).
- Puedo ejecutar el servidor ASO y el cliente del proyecto: SI, con limites.**
  Con VT-x el host puede levantar VM KVM; sobre 8 GB entran a la vez srv-aso y
  cli-linux dejando margen para el propio Proxmox, siempre que las VM se
  dimensionen con contencion (p. ej. ~2 GB cada una y ~2-3 GB para el host).
  Los 4 hilos permiten repartir vCPU entre host y las dos VM. El SSD aporta el
  IOPS que Proxmox recomienda ("mejores resultados con discos SSD"). No es
  hardware de produccion, pero cumple de sobra el perfil de evaluacion que
  describe Proxmox, que es el caso de este proyecto.
- Condiciones o comprobaciones pendiente: - **Modalidad (fisico o VirtualBox):** si se instala dentro de VirtualBox, hay
    que **activar la virtualizacion anidada**; Proxmox solo se instala como
    invitado si el virtualizador la soporta. Si es fisico, la instalacion borra
    este Linux, lo que exige copia previa de datos y evidencias.
  - **VT-x en BIOS:** ya aparece activo en `lscpu`, pero conviene verificar en el
    firmware (AMI 0810) que sigue habilitado.
  - **Modo de arranque y Secure Boot:** comprobar si el equipo arranca en UEFI o
    Legacy para preparar el USB acorde (`[ -d /sys/firmware/efi ]`). Secure Boot
    no es un problema: PVE lo soporta de forma nativa desde la version 8.1.
  - **Red fisica:** `eth0` estaba DOWN (`link=no`) en la captura; hay que conectar
    el cable, porque el bridge de Proxmox necesita enlace real.
  - **RAM como factor limitante:** 8 GB es el minimo realista para tres cargas; si
    se pretende mas de dos VM activas o servicios adicionales, habra que ampliar
    (hay 2 slots libres, hasta 64 GB)..

## 2. Que limitaciones tendre con este hardware?

Analizar RAM, CPU, disco y red para las cargas previstas. Identificar lo
medido y lo estimado. En VirtualBox, investigar host real y VM: version,
RAM reservada al anfitrion, vCPU, VDI, espacio fisico y red local.
No se utiliza el Proxmox del centro como recurso.

### Reparto de recursos

| Elemento | CPU/vCPU | RAM | Disco | Justificacion |
|---|---|---|---|---|
| Proxmox | | | | |
| srv-aso | | | | |
| cli-linux | | | | |
| Plantilla, ISOs y copias | No aplica | No aplica | | |
| Margen de operacion | | | | |

Mostrar calculos de RAM y disco, reparto de vCPU, unidades y supuestos.
Explicar las cargas que pueden funcionar simultaneamente.

| Limitacion | Evidencia o estimacion | Consecuencia | Medida y limite que permanece |
|---|---|---|---|
| | | | |

## 3. Que componentes son mas criticos en mi servidor y por que?

Ordenar al menos tres componentes para este equipo y su servicio.
Distinguir cuello de botella, disponibilidad e integridad de los datos.

| Prioridad y componente | Funcion | Efecto si es insuficiente | Efecto si falla | Evidencia y justificacion |
|---|---|---|---|---|
| 1. | | | | |
| 2. | | | | |
| 3. | | | | |

Componente que mejoraria primero y motivo para priorizarlo frente a otro:
PENDIENTE.

## Fuentes tecnicas

Consultar al menos tres fuentes primarias, incluyendo Proxmox y
fabricante o plataforma virtual. Relacionarlas con las tres respuestas.

| Fuente y URL | Version/modelo y fecha de consulta | Afirmacion respaldada | Aplicacion al nodo |
|---|---|---|---|
| | | | |

## Dictamen de viabilidad

Apto, apto con condiciones o no apto para la propuesta actual: PENDIENTE.

Sintetizar las tres respuestas y las condiciones pendientes de comprobar.

## Evidencias y revision docente

Enlazar salidas revisadas desde ../evidencias/. Un listado automatico no
sustituye la investigacion. Registrar la pregunta de defensa y respuesta.

[Volver al indice](../README.md)
