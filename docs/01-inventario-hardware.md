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
- Condiciones o comprobaciones pendiente:
  - **Modalidad (fisico o VirtualBox):** si se instala dentro de VirtualBox, hay
    que
  - **activar la virtualizacion anidada**; Proxmox solo se instala como
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

Instalacion **bare-metal**: Proxmox se instala directo sobre el equipo, sin
sistema anfitrion que reserve RAM ni CPU. Por tanto el reparto se hace sobre
los recursos reales del nodo (8 GB RAM, 4 hilos, SSD de 250 GB). No se usa el
Proxmox del centro. El reparto asume srv-aso y cli-linux como VM KVM (supuesto
prudente, el que mas RAM consume); si alguna se despliega como contenedor LXC,
su consumo real de RAM y disco sera menor y quedara mas margen.

### Reparto de recursos

| Elemento | CPU/vCPU | RAM | Disco | Justificacion |
|---|---|---|---|---|
| Proxmox (host) | 4 hilos fisicos compartidos | 2-2,5 GB | ~20 GB (sistema PVE sobre LVM-ext4) | El host no se "quita" hilos: los 4 estan disponibles para planificar. Reserva de RAM para kernel, servicios PVE y panel web |
| srv-aso | 2 vCPU | 2 GB | 20-25 GB | Servicio ASO (ficheros/permisos) no exige mucha CPU; 2 vCPU y 2 GB bastan para la carga del proyecto |
| cli-linux | 1-2 vCPU | 1,5-2 GB | 15-20 GB | Cliente para probar acceso permitido y denegado; carga ligera, puede ir con 1 vCPU si hay presion de RAM |
| Plantilla, ISOs y copias | No aplica | No aplica | 40-60 GB | ISO de instalacion, plantilla reutilizable y backups de las VM. Es lo que mas crece con el tiempo |
| Margen de operacion | Sobresuscripcion de vCPU permitida | ~1,5-2 GB libres | ~120 GB libres | Colchon para picos, snapshots y una restauracion. No dejar la RAM al limite |

**Calculo de RAM (suma de VM encendidas a la vez):**
Host 2,5 GB + srv-aso 2 GB + cli-linux 2 GB = 6,5 GB de 8 GB → ~1,5 GB libres.
Es viable tener las **dos VM encendidas con el host**, pero sin apenas colchon.
Por eso la RAM es el limite real del nodo: una tercera VM, o subir memoria a las
existentes, obliga a apagar algo o a ampliar (hay 2 slots libres, hasta 64 GB).

**Calculo de disco (sobre 250 GB, ~229 utiles):**
Host ~20 GB + srv-aso 25 GB + cli-linux 20 GB + ISOs/plantilla/copias 60 GB
= ~125 GB, dejando ~100 GB libres. Holgado para el laboratorio. El SSD aporta
el IOPS que hace fluida la operacion de varias VM a la vez.

**Reparto de vCPU:** 4 hilos reales. Se permite asignar mas vCPU que hilos
fisicos (sobresuscripcion), porque las VM no usan la CPU al 100% a la vez. El
reparto 2+2+1 funciona porque las cargas del proyecto son intermitentes; el
planificador de Proxmox reparte el tiempo de CPU entre ellas.

**Cargas simultaneas:** host + srv-aso + cli-linux pueden funcionar a la vez
para la prueba de acceso permitido/denegado (cli-linux contra srv-aso). Lo que
NO cabe con holgura es sumar una tercera VM pesada o hacer una restauracion
grande con las dos VM encendidas; conviene apagar una para esas tareas.

| Limitacion | Evidencia o estimacion | Consecuencia | Medida y limite que permanece |
|---|---|---|---|
| RAM de 8 GB (medido) | free: 7,6 GiB totales; suma estimada 6,5 GB con host + 2 VM | Sin margen para una 3.ª VM ni para ampliar la memoria de las actuales | Apagar una VM cuando no se use; ampliar RAM (2 slots libres, hasta 64 GB). Limite que permanece: solo 2 VM activas a la vez con comodidad |
| CPU de 2 nucleos / 4 hilos sin turbo (medido) | lscpu: Pentium G4560, 3.5 GHz fijo | Cuello de botella si varias VM exigen CPU a la vez (compilar, cifrar, restaurar) | Sobresuscribir vCPU y escalonar tareas pesadas. Limite: no apto para cargas intensivas simultaneas |
| Un solo disco, sin redundancia (medido) | lsblk: un unico SSD `sda` | Si falla el disco se pierden host y VM a la vez (sin tolerancia a fallo) | Backups regulares a destino externo (USB Kingston o red). Limite: integridad depende de las copias, no del hardware |
| Red: eth0 estaba DOWN (medido) | ip: `eth0 DOWN`, `link=no` | Sin cable no hay bridge real ni acceso al panel/servicio por red | Conectar el cable Gigabit antes de operar. Limite: imprescindible enlace fisico estable |
| SSD de consumo, 100 TBW (ficha) | Crucial MX500 250 GB, resistencia 100 TBW | Las copias y snapshots frecuentes desgastan el SSD a largo plazo | Vigilar SMART; mover copias antiguas a disco externo. Limite: suficiente para el curso, no para escritura intensiva continua |

## 3. Que componentes son mas criticos en mi servidor y por que?

Para este nodo y su servicio (ASO de ficheros/permisos probado desde un
cliente), ordeno los tres componentes mas criticos distinguiendo cuello de
botella (lo que frena el rendimiento), disponibilidad (que el servicio siga en
pie) e integridad (que los datos no se pierdan ni corrompan).

| Prioridad y componente | Funcion | Efecto si es insuficiente | Efecto si falla | Evidencia y justificacion |
|---|---|---|---|---|
| 1. RAM | Sostener el host y las VM encendidas a la vez | Con poca RAM no caben las VM: el host usa swap y todo se ralentiza, o no arranca una VM | Un fallo de modulo deja el nodo inestable o sin arrancar | Es el recurso mas ajustado: 6,5/8 GB usados con 2 VM (free). Es el primer limite que se toca en el reparto |
| 2. Almacenamiento (SSD) | Alojar host, VM, ISOs y copias; dar IOPS | Disco lento (HDD) haria lenta toda operacion con varias VM | Al ser disco unico, su fallo pierde host y VM a la vez: afecta a disponibilidad **e** integridad | lsblk: un solo SSD. Critico por doble motivo: rendimiento (IOPS) y ausencia de redundancia |
| 3. CPU | Ejecutar las instrucciones del host y las VM | 2 nucleos/4 hilos se saturan si varias VM exigen CPU juntas | Un fallo de CPU detiene el nodo completo | lscpu: Pentium G4560 sin turbo. Es cuello de botella en picos, pero el servicio ASO no es intensivo en CPU |

**Componente que mejoraria primero y por que:** la **RAM**. Es el limite que se
toca antes en el reparto (1,5 GB de colchon con dos VM) y el que mas restringe
lo que puedo hacer a la vez. Ampliar de 8 a 16 GB (un modulo mas en un slot
libre) desahoga de inmediato y permite una tercera VM o mas memoria por VM.
Lo priorizo frente al SSD porque el disco actual ya es SSD y tiene espacio de
sobra (~100 GB libres): no es el freno. Y frente a la CPU porque el servicio ASO
no es intensivo en calculo; la RAM, en cambio, limita incluso con cargas ligeras.

## Fuentes tecnicas

| Fuente y URL | Version/modelo y fecha de consulta | Afirmacion respaldada | Aplicacion al nodo |
|---|---|---|---|
| Proxmox VE - System Requirements · https://www.proxmox.com/en/products/proxmox-virtual-environment/requirements | PVE 9.2 · 20/10/2026 | CPU 64 bits con VT-x/AMD-V obligatorio para KVM; min. 2 GB RAM para el host mas la memoria de cada VM; SSD recomendado | Fija el minimo que cumple el nodo y sustenta el reparto de RAM del apartado 2 |
| Intel ARK - Pentium G4560 · https://ark.intel.com/content/www/us/en/ark/products/97143 | G4560, Kaby Lake · 20/10/2026 | 2 nucleos / 4 hilos, VT-x + VT-d + EPT, max. 64 GB DDR4-2400, 2 canales | Confirma virtualizacion por hardware (apartado 1) y el tope de ampliacion de RAM (apartado 2) |
| Crucial MX500 - Ficha de producto · https://www.crucial.com/ssd/mx500/ct250mx500ssd1 | CT250MX500SSD1 · 20/10/2026 | SATA III, lectura 560 / escritura 510 MB/s, 100 TBW | Justifica el IOPS para varias VM y el limite de desgaste por copias (apartado 2 y 3) |
| Proxmox ASIR - Redes virtuales y recorridos · https://jmarlu.github.io/PI/proxmox/redes-teoria/ | Curso 2026-2027 · 20/10/2026 | Bridge de nivel 2, montaje con vmbr0 (exterior) y vmbr1 (192.168.56.0/24) para srv-aso .20 y cli-linux .30 | Define la red donde operan las VM y por que el enlace fisico (eth0) es imprescindible |

## Dictamen de viabilidad

**Apto con condiciones** para la propuesta actual.

El nodo cumple los requisitos obligatorios de Proxmox VE 9.2: CPU de 64 bits con
VT-x y EPT (apartado 1), RAM y disco por encima del minimo, y una NIC Gigabit.
Permite instalar y arrancar Proxmox y ejecutar srv-aso y cli-linux a la vez para
las pruebas del servicio ASO. Las condiciones que permanecen son: la **RAM de
8 GB** deja solo ~1,5 GB de colchon con dos VM, por lo que es el primer recurso
a ampliar y marca el limite de dos VM activas; el **disco unico** obliga a
depender de **copias de seguridad** para la integridad; y hay que **conectar el
cable de red** (eth0 estaba DOWN) antes de operar. Ninguna de estas condiciones
impide realizar el proyecto; definen como dimensionar y como protegerlo.

Comprobaciones pendientes: confirmar VT-x habilitado en BIOS tras reinicios,
verificar modo de arranque (UEFI/Legacy) para preparar el USB, y registrar la
primera copia de seguridad restaurada como evidencia de continuidad.
