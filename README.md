# MuvAutomation Secure Product Challenge — Lab 3

## Arquitectura
- Kali Linux (Red Team)
- Ubuntu Server LTS + Nginx (aplicación)
- Blue Team monitorea tráfico y logs

## Variables de entorno
```bash
export TARGET_IP=<IP_ASIGNADA>
export TARGET_URL=http://$TARGET_IP
export LAB_CIDR=<CIDR_AUTORIZADO>
```

## Procedimiento de reproducción
1. Fase A: construcción y publicación (ver evidence/baseline)
2. Fase B: DFD + STRIDE (ver diagrams/, evidence/)
3. Fase C: Red Team (ver evidence/red/)
4. Fase D: Blue Team (ver evidence/blue/)
5. Fase E: hardening (ver nginx/)
6. Fase F: retest (ver evidence/retest/)

## Estado
En progreso.
