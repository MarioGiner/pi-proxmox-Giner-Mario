# Bitacora de sesiones

La bitacora es el registro cronologico del trabajo. Anade una entrada al final
de cada sesion y conserva las anteriores. Escribe datos comprobables y enlaza
las evidencias utiles; evita frases generales como "he trabajado en Proxmox".

## Sesion 01 - FECHA

- Objetivo: iniciar GitHub y la documentacion Markdown.
- Acciones realizadas: PENDIENTE: configuraciones, cambios o investigacion.
- Decisiones y motivos: PENDIENTE: eleccion realizada y alternativas valoradas.
- Pruebas y resultados: PENDIENTE: resultado esperado, comando o metodo y resultado obtenido.
- Documentos o evidencias: [Ficha inicial](00-ficha-inicial.md).
- Incidencias y solucion o estado pendiente: PENDIENTE.
- Siguiente paso: PENDIENTE: accion concreta para la proxima sesion.
## Sesion 02 - 2026-10-13

- Objetivo: investigar el hardware del equipo y resolver la Fase 1 (inventario y viabilidad).
- Acciones realizadas: ejecucion de comandos de inventario (`lscpu`, `free -h`, `lsblk`, `df -h`, `dmidecode`, `lshw`, `ip`) sobre el equipo PC613; recogida de CPU, RAM, almacenamiento, red y plataforma; contraste con fichas oficiales de fabricante (Intel ARK, Crucial) y con los requisitos de Proxmox VE 9.2; redaccion del inventario inicial y de las tres preguntas en `docs/01-inventario-hardware.md`.
- Decisiones y motivos: se fija Proxmox VE 9.2 como version de referencia; se asume el supuesto prudente de VM KVM para el reparto de recursos, anotando que LXC reduciria el consumo. Dictamen: apto con condiciones.
- Pruebas y resultados: verificacion de virtualizacion por hardware: se esperaba soporte VT-x y se confirmo (flag `vmx` y `Virtualizacion: VT-x` en `lscpu`). RAM total 8 GB (7,6 GiB en `free`), SSD de 250 GB con ~177 GB libres, NIC Realtek Gigabit con `eth0` en estado DOWN.
- Documentos o evidencias: [Inventario de hardware](01-inventario-hardware.md); salidas en `../evidencias/` (cpu, ram, disco, red, plataforma).
- Incidencias y solucion o estado pendiente: `eth0` aparecia DOWN (`link=no`) por estar sin cable en el momento de la captura; pendiente conectar el enlace fisico. Falta confirmar el modo de arranque (UEFI/Legacy) y que VT-x siga habilitado en BIOS.
- Siguiente paso: disenar la red del laboratorio (Fase 2).

## Sesion 03 - 2026-10-20

- Objetivo: resolver la Fase 2 (diseno de red) y documentar el diagrama.
- Acciones realizadas: definicion del direccionamiento del laboratorio en `192.168.56.0/24`, bridges, gateway, DNS, puertos y medidas de aislamiento; creacion del diagrama en Mermaid; redaccion de `docs/02-diagrama-red.md`.
- Decisiones y motivos: se adopta finalmente la modalidad virtualizada (Proxmox en VirtualBox sobre el equipo personal), con el esquema de dos adaptadores de la guia (NAT en `vmbr0` para salida, solo-anfitrion en `vmbr1` para el laboratorio). Nodo nombrado `pve-giner`; cargas `srv-aso` (.20) y `cli-linux` (.30), nodo-gateway en .10. Sin VLAN, segun indica el curso.
- Pruebas y resultados: PENDIENTE (el nodo aun no esta instalado; la verificacion con `ip -br addr` e `ip route` queda para la fase de instalacion).
- Documentos o evidencias: [Diagrama de red](02-diagrama-red.md).
- Incidencias y solucion o estado pendiente: conflicto en Git al hacer `pull` por tener `docs/02-diagrama-red.md` modificado en la web de GitHub y borrado en local; resuelto restaurando el archivo, fusionando ramas divergentes (`git pull --no-rebase`) y quedandose con la version remota (`git checkout --theirs`). Pendiente: recursos de cada maquina segun el equipo personal y DNS definitivo.
- Siguiente paso: instalar Proxmox en VirtualBox (Fase 3).



Anadir una entrada con esta estructura en cada sesion. El historial de
GitHub registra los commits; no hace falta incluir el hash del propio
commit dentro de su entrada de bitacora.

[Volver al indice](../README.md)
