# 03-instalacion-proxmox

## Objetivo

Instalar Proxmox VE dentro de una maquina virtual de VirtualBox en mi portatil (modalidad virtualizada) y dejar el nodo preparado para poder gestionarlo desde el navegador del anfitrion. Tambien dejar configuradas las dos redes que se definieron en el diagrama de red: una para salir a Internet (NAT) y otra para la gestion y el laboratorio (solo-anfitrion).

## Procedimiento

1. **Preparar VirtualBox.** Antes de crear la maquina comprobe la version de VirtualBox, la RAM y el disco libre del portatil. Despues cree la red solo-anfitrion `vboxnet0` desde el gestor de red de VirtualBox, con la IP `192.168.56.1/24` y sin DHCP, porque voy a usar IPs fijas.

2. **Crear la VM `pve-giner`.** La cree con estos datos:

   | Opcion | Valor |
   |---|---|
   | Nombre | `pve-giner` |
   | Tipo | Linux, Debian 64 bits |
   | Memoria | [X] GB |
   | CPU | [X] vCPU |
   | Disco | VDI dinamico de 50 GB |
   | Adaptador 1 | NAT |
   | Adaptador 2 | Solo-anfitrion (`vboxnet0`), modo promiscuo "Permitir todo" |
   | Virtualizacion anidada | Activada (VT-x/AMD-V anidado) |

   Elegi 50 GB de disco porque es suficiente para el sistema, las dos maquinas del proyecto y alguna copia de seguridad, siempre que las maquinas sean pequenas. Al ser un disco dinamico solo ocupa en el portatil lo que se va usando.

3. **Instalar Proxmox VE 9.2.** Arranque la VM con la ISO y segui el instalador. En la parte de red elegi la interfaz NAT, como indica la guia:
   - IP: `10.0.2.15/24`
   - Gateway: `10.0.2.2`
   - DNS: `10.0.2.3`

   Al terminar quite la ISO y reinicie.

4. **Configurar la segunda red.** Desde la consola de la VM anadi un segundo bridge, `vmbr1`, sobre la interfaz solo-anfitrion con la IP `192.168.56.10/24` y sin gateway. Asi el nodo queda con dos redes:
   - `vmbr0` (NAT): `10.0.2.15`, es la que da salida a Internet.
   - `vmbr1` (solo-anfitrion): `192.168.56.10`, es la de gestion y la que usaran `srv-aso` y `cli-linux`.

5. **Corregir el nombre del nodo.** Cambie el hostname a `pve-giner` y actualice `/etc/hosts` para que el nombre `pve-giner.lab.test` apunte a la IP de gestion `192.168.56.10`.

6. **Comprobar el acceso.** Desde el portatil hice ping a `192.168.56.10` y entre al panel web en `https://192.168.56.10:8006` con el usuario `root` y el realm *Linux PAM*.

## Comandos usados

```bash
# En el portatil (anfitrion)
VBoxManage --version
free -h
nproc
df -h
VBoxManage modifyvm "pve-giner" --nested-hw-virt on
VBoxManage showvminfo "pve-giner" | grep -i nested

# En el nodo Proxmox: comprobar interfaces
ip -br link
ip -br addr
ip route

# Copia de la configuracion de red antes de tocarla
cp /etc/network/interfaces /root/interfaces.bak
nano /etc/network/interfaces
ifreload -a

# Cambio de nombre del nodo
hostnamectl set-hostname pve-giner
nano /etc/hosts
reboot
hostname -f
getent hosts pve-giner.lab.test

# Desde el portatil
ping -c 3 192.168.56.10
```

Configuracion de red final del nodo (`/etc/network/interfaces`):

```
auto lo
iface lo inet loopback

iface nic0 inet manual
iface nic1 inet manual

auto vmbr0
iface vmbr0 inet static
    address 10.0.2.15/24
    gateway 10.0.2.2
    bridge-ports nic0
    bridge-stp off
    bridge-fd 0

auto vmbr1
iface vmbr1 inet static
    address 192.168.56.10/24
    bridge-ports nic1
    bridge-stp off
    bridge-fd 0

source /etc/network/interfaces.d/*
```

## Evidencias

- Captura de la configuracion de la VM en VirtualBox (sistema, procesador y los dos adaptadores de red).
- Captura de la red solo-anfitrion `vboxnet0`.
- Captura de la pantalla de red del instalador.
- Salida de `ip -br addr` y `ip route` en el nodo.
- Salida de `hostname -f`.
- Captura del panel web de Proxmox con el nodo `pve-giner`.

Las capturas estan en la carpeta [`../evidencias/`](../evidencias/).

## Incidencias

**1. No podia guardar el adaptador 2 en VirtualBox.**
Al poner el adaptador 2 como solo-anfitrion no me dejaba aceptar la configuracion. El problema era que no habia ninguna red solo-anfitrion creada. Lo solucione creando `vboxnet0` desde el gestor de red de VirtualBox y seleccionandola en el adaptador.

**2. La maquina virtual se reiniciaba sola.**
Al poco de instalar, la VM se reiniciaba de repente. Revise el log de VirtualBox (`VBox.log`) y vi que el reinicio lo pedia el propio sistema (`Reset initiated by ACPI`) y que la VM habia tenido un retraso grande de reloj. En el log de Proxmox no aparecia ningun error. La causa mas probable es que la VM se quedaba congelada unos segundos y el watchdog de Proxmox la reiniciaba. Descarte que fuera falta de recursos, porque el portatil tiene RAM y CPU de sobra. [Explicar aqui que cambiaste para que dejara de pasar.] Despues de eso ya no se ha vuelto a reiniciar.

**3. El nombre del nodo no era el correcto.**
En el instalador escribi `pve.giner.lab.test` en lugar de `pve-giner.lab.test`, y el nodo se quedo con el nombre `pve`. Ademas, en `/etc/hosts` el nombre apuntaba a la IP de la NAT (`10.0.2.15`) en vez de a la de gestion. Lo corregi cambiando el hostname y el archivo `/etc/hosts` antes de crear ninguna maquina, porque despues es mas complicado.

## Conclusion

Proxmox VE ha quedado instalado dentro de VirtualBox en mi portatil con el nombre `pve-giner`. El nodo tiene dos redes: la NAT para salir a Internet y la solo-anfitrion para gestionarlo desde el navegador y para conectar las maquinas del proyecto. He aprendido que es importante revisar bien los datos del instalador (sobre todo el nombre y la red), porque corregirlos despues da mas trabajo. Tambien que los logs de VirtualBox y de Proxmox ayudan mucho a encontrar el origen de un problema. El siguiente paso es crear la plantilla Linux y desplegar `srv-aso` y `cli-linux`.

[Volver al indice](../README.md)
