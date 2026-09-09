# MuvAutomation Secure Product Challenge — Lab 3

**Autores:** David Alejandro Patacón Henao, Marlio Jose Charry Espitia
**Curso:** FDSI 2026-2

## Arquitectura

- Entorno de práctica local: CachyOS (Arch Linux), usado como sustituto temporal
  de la VM Ubuntu Server asignada por el docente.
- Servidor web: Nginx.
- Fase actual de referencia local: `127.0.0.1` (localhost). Cuando el docente
  asigne la IP/CIDR reales, se repiten los mismos pasos allí.

## Variables de entorno

```bash
export TARGET_IP=127.0.0.1        # temporal, local — se reemplaza por la IP asignada
export TARGET_URL=http://$TARGET_IP
export LAB_CIDR=127.0.0.1/32      # temporal, local — se reemplaza por el CIDR asignado
```

## Procedimiento de reproducción

### Fase A — Construcción y publicación

**Paso 1 — Verificación de línea base del host**

Se confirmó identidad y estado del host antes de instalar cualquier servicio:

```bash
hostnamectl
ip -br address
uname -a
date -u +%Y-%m-%dT%H:%M:%SZ
```

Resultado relevante:
- Host: `cachyos-x8664` (CachyOS, kernel `7.2.2-1-cachyos`)
- Interfaz de referencia: `lo` → `127.0.0.1` (localhost, usada para pruebas locales)
- Timestamp de inicio del laboratorio: `2026-09-09T22:53:09Z`

Evidencia guardada en `evidence/baseline/`.

**Paso 2 — Instalación de Nginx**


## Estado

En progreso — Fase A, Paso 2 (instalación de Nginx).