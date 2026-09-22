# MuvAutomation Secure Challenge — Laboratorio 3

Aplicación web pública mínima por HTTP, sin autenticación, desplegada en una
instancia autorizada para practicar el ciclo Diseñar → Construir → Atacar →
Detectar → Corregir → Verificar.

## Arquitectura

- **Kali Linux (VirtualBox)** — Red Team: reconocimiento y validación (Nmap, curl, OWASP ZAP).
- **AWS EC2 Ubuntu Server** — host de la aplicación (Nginx + sitio estático), Blue Team (logs, tcpdump).
- **PC local (CachyOS)** — orquestación, consolidación de evidencia, Git.

Ver diagrama de flujo de datos (DFD) con los trust boundaries en `diagrams/dfd-lab3.png`.

## Variables de entorno usadas

```bash
export TARGET_IP=44.206.197.137
export TARGET_URL=http://$TARGET_IP
export LAB_CIDR=186.31.164.11/32
```

## Componentes desplegados

- Nginx sirviendo `app/index.html` y `app/public-inventory.txt` desde `/var/www/muvautomation`.
- Virtual host: `nginx/muvautomation.conf`.
- Firewall UFW restringido a `LAB_CIDR` en el puerto 80, más OpenSSH.

## Procedimiento de reproducción (resumen)

1. Desplegar EC2 Ubuntu, asociar Elastic IP, configurar Security Group (SSH restringido a "My IP", HTTP/HTTPS abiertos).
2. Instalar y configurar Nginx con el virtual host de `nginx/muvautomation.conf`.
3. Restringir UFW al `LAB_CIDR`.
4. Modelar amenazas: DFD (`diagrams/dfd-lab3.png`) + tabla STRIDE (ver abajo).
5. Desde Kali: reconocimiento con Nmap/curl (`evidence/red/`) e inspección pasiva con ZAP (`evidence/red/zap-report.html`).
6. Captura de tráfico HTTP en claro con tcpdump + Wireshark (`evidence/blue/lab3-http.pcap`).
7. Revisión de `access.log`/`error.log` y regla de detección de 404 (`evidence/blue/access.log`).
8. Hardening: `server_tokens off`, headers de seguridad, bloqueo de rutas ocultas (`.git`), reducción del inventario público.
9. Retest: repetición de las pruebas del paso 5 (`evidence/retest/`).

## Tabla STRIDE

| ID | STRIDE | Hipótesis técnica | Validación |
|----|--------|-------------------|------------|
| H1 | Information Disclosure | HTTP permite observar contenido y rutas en tránsito. | Captura PCAP filtrada (`evidence/blue/lab3-http.pcap`). |
| H2 | Information Disclosure | Headers y respuestas revelan tecnología o recursos. | `curl -I` y ZAP pasivo (`evidence/red/curl_headers.txt`, `zap-report.html`). |
| H3 | Repudiation | Sin correlación temporal, el equipo no atribuye solicitudes. | Comparación de comandos con `access.log`. |
| H4 | Tampering | Sin TLS, un intermediario podría alterar tráfico; no se ejecutó MITM. | Ausencia de cifrado demostrada, sin interceptar terceros. |

## Comparación antes / después del hardening

| Header/Control | Antes | Después |
|---|---|---|
| `Server` | `nginx/1.28.3 (Ubuntu)` | `nginx` (versión y SO ocultos) |
| `X-Content-Type-Options` | Ausente | `nosniff` |
| `X-Frame-Options` | Ausente | `DENY` |
| `Referrer-Policy` | Ausente | `no-referrer` |
| `/.git/config` | No probado | `403 Forbidden` |
| `public-inventory.txt` | 3 activos ficticios | 1 activo ficticio |

## Reflexión individual 

Este laboratorio nos permitió ver de primera mano por qué HTTP sin cifrado y sin autenticación es una superficie de ataque real, no solo una advertencia teórica. Construir el sitio fue la parte más simple; lo revelador fue el reconocimiento: con un curl cualquiera puede leer la versión exacta del servidor y sistema operativo, y con Wireshark pudimos ver nuestro propio HTML viajando en texto plano, sin ningún esfuerzo especial de un atacante.

El hardening aplicado (ocultar versión de servidor, headers de seguridad, bloquear rutas ocultas) redujo información expuesta de forma medible y verificable con un retest, pero no resolvió el problema de fondo: la falta de cifrado. Eso deja claro que la seguridad se construye en capas y de forma incremental, en vez de intentar resolver todo de una vez.

Trabajar con roles separados (Red/Blue), nos ayudó a pensar diferente en cada fase: atacar buscando información vs. defender correlacionando evidencia.