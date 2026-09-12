# Registro de riesgos - CrowdStrike Falcon Incident Automation (Lab 3)

## Activos
- index.html, alerts-inventory.json
- Configuración de Nginx
- Logs (access.log / error.log)
- Disponibilidad del servicio HTTP

## Actores
- Analista de seguridad (legítimo)
- Atacante / Red Team (adversario)
- Blue Team (observador/defensor)

## Límites de confianza
1. Red del laboratorio (192.168.56.0/24) <-> Servidor Ubuntu
2. Proceso Nginx <-> Sistema de archivos/logs del host

## Superficie de ataque
- TCP/80 abierto en 192.168.56.102
- Endpoints / y /alerts-inventory.json
- Headers HTTP (banner de versión)
- SSH (22) en el mismo segmento

## Tabla STRIDE

| STRIDE | Riesgo | Evidencia | Mitigación propuesta | Estado |
|---|---|---|---|---|
| Spoofing | Sin autenticación, cualquier host del segmento consulta el servicio | curl sin credenciales responde 200 OK | API key / mTLS / JWT | Pendiente Lab 4 |
| Tampering | Sin TLS, tráfico alterable en tránsito | curl -v muestra contenido en texto plano | HTTPS TLS 1.3, checksum de integridad | Pendiente Lab 4 |
| Repudiation | No se atribuye una consulta a un analista específico | access.log solo registra IP y método | Autenticación + logging con identidad | Pendiente Lab 4 |
| Information Disclosure | alerts-inventory.json expone datos sin control de acceso; version de Nginx visible | curl -I revela header Server; curl expone el JSON completo | server_tokens off, autenticación del endpoint | Mitigado parcialmente |
| Denial of Service | Sin limit_req, agotamiento de recursos posible | grep limit_req sin resultados en la config | limit_req_zone, WAF (Lab 6) | Aceptado por ahora |
| Elevation of Privilege | Sin roles, riesgo futuro al integrar API real de Falcon | curl -X POST devuelve 405 Method Not Allowed | RBAC y separación de roles | Pendiente Lab 4 |

