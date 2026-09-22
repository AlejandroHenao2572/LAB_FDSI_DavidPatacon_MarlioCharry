# Registro de riesgos — Laboratorio 3

| ID | Riesgo (STRIDE) | Estado | Detalle |
|----|------------------|--------|---------|
| H1 | Information Disclosure — contenido en tránsito sin cifrar | **Pendiente para Lab 4** | HTTP seguirá siendo inseguro en confidencialidad/integridad hasta implementar HTTPS/TLS en el Laboratorio 4. |
| H2 | Information Disclosure — versión de servidor expuesta | **Mitigado** | `server_tokens off` oculta versión de Nginx y SO en el header `Server`. |
| H3 | Repudiation — sin correlación de solicitudes | **Mitigado (parcial)** | Se correlacionaron IP, timestamp, método y ruta contra `access.log`; el escaneo Nmap sí quedó registrado. Falta autenticación/identidad (Lab 4) para atribución completa. |
| H4 | Tampering — ausencia de integridad en tránsito | **Pendiente para Lab 4** | Sin TLS no hay protección contra alteración de tráfico; se corrige con certificados en el Laboratorio 4. |
| — | Ruta oculta `.git/config` accesible | **Corregido** | Bloqueada con `location ~ /\. { deny all; }` → verificado con retest (`403 Forbidden`). |
| — | Inventario público expone más activos de los necesarios | **Corregido** | Reducido de 3 a 1 activo ficticio en `public-inventory.txt`. |
| — | Regla de detección (5+ 404 en 5 min) no detecta escaneo real | **Aceptado / limitación documentada** | El escaneo Nmap generó 4 respuestas 404 en el mismo segundo, por debajo del umbral. Se documenta como falso negativo conocido; ajustar umbral queda fuera de alcance de este laboratorio. |
