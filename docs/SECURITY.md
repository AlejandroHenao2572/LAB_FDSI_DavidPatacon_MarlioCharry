# Seguridad del proyecto — evidencia del laboratorio

## 1. Alcance autorizado
- Repositorio: https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry (público, cuenta personal)
- Rama de línea base y commit: `main` / `53f8d29e2f6aacf4e0e330d35d088d85553e3160`
- Rama del laboratorio: `security/lab-fsi`
- Tecnología: sitio estático HTML (`app/`) servido por Nginx (`nginx/muvautomation.conf`); workflows de GitHub Actions (`.github/workflows/`).
- Autenticación / APIs: no tiene. Sitio público de solo lectura, sin formularios, cookies ni backend.
- Activos: `app/index.html`, `app/public-inventory.txt` (datos ficticios), configuración Nginx (headers de seguridad, bloqueo de rutas ocultas) y pipeline CI.
- Riesgo principal: divulgación de información por configuración del servidor (headers faltantes, rutas ocultas expuestas, HTTP sin TLS).
- URL de staging propio: Nginx local en Docker (`http://localhost:8080`) con la misma configuración del repositorio. La instancia EC2 del Lab 3 no está disponible.
- Responsables / autorización: David Patacón, Marlio Charry. Equipo propietario del repositorio y del entorno, 2026-11-08.
- Fuera de alcance: producción, sistemas de terceros, datos reales y pruebas destructivas.

## 2. Línea base y herramientas
| Herramienta | Tipo | Fecha | Resultado | Enlace a evidencia |
|---|---|---|---|---|
| CodeQL o Semgrep | SAST | | | |
| Gitleaks / GitHub secret scanning | Secretos | | | |
| Dependabot | SCA | | | |
| OWASP ZAP Baseline | DAST pasivo | | | |

## 3. Hallazgos y gestión
| ID | Categoría | Descripción sin secretos | Riesgo | Archivo/ruta | Cambio propuesto | Estado |
|---|---|---|---|---|---|---|
| F-01 | | | | | | Abierto |

## 4. Validación antes y después
- Evidencia inicial (captura o artefacto):
- Pull request con corrección:
- Evidencia de reescaneo:
- Riesgo residual y decisión:

## 5. Pentest autorizado
- Hipótesis:
- Entorno de pruebas aislado:
- Solicitudes inocuas y respuestas observadas (sin datos personales):
- Resultado: validado / no reproducible / requiere revisión
- Recomendación y prueba de regresión:
