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
| GitHub (Settings → Advanced Security) | Controles nativos | 2026-11-08 | Dependabot alerts, secret scanning y push protection activos | `evidence/lab5/dependabot.png`, `codeql.png` |
| CodeQL Default setup | SAST | 2026-11-08 | Configurado, pero sin lenguajes detectados: HTML y la configuración de Nginx no son lenguajes soportados. Ver limitación abajo. | `evidence/lab5/codeql.png` |
| Semgrep (`p/owasp-top-ten`, `p/secrets`) | SAST | 2026-11-08 | 6 resultados, 1 regla: `github-actions-mutable-action-tag` | [PR #3](https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry/pull/3), `evidence/lab5/semgrep-antes.json`, `actions-1.png` |
| Gitleaks (historial completo) | Secretos | 2026-11-08 | 0 fugas | `evidence/lab5/gitleaks-antes.sarif`, `actions-2.png` |
| Dependabot (alerts + `.github/dependabot.yml`) | SCA | 2026-11-08 | 0 alertas. El grafo de dependencias está vacío porque `main` todavía no tiene workflows. Las 4 acciones usadas están desactualizadas, ninguna con un advisory conocido. | `evidence/lab5/dependabot.png`, `.github/dependabot.yml` |
| OWASP ZAP Baseline | DAST pasivo | | | |

**Limitación CodeQL:** el proyecto no tiene código en un lenguaje que CodeQL soporte. Lo único analizable son los workflows de GitHub Actions, y estos todavía no están en `main`. Se volverá a revisar después del merge. El SAST del proyecto queda cubierto por Semgrep.

**Triage de Semgrep:**
- **R1, verdadero positivo:** `gitleaks/gitleaks-action@v3` es una acción de un tercero referenciada por una etiqueta que se puede mover. Si esa acción se compromete, el pipeline ejecutaría código ajeno con acceso a `GITHUB_TOKEN` (cadena de suministro, CWE-829).
- **R2, riesgo bajo / falsa alarma parcial:** `actions/checkout`, `actions/setup-python` y `actions/upload-artifact` son acciones publicadas por GitHub, que ya es un proveedor de confianza del pipeline. La regla es técnicamente correcta, pero el impacto real es bajo.
- **`p/secrets`:** 0 resultados, coherente con Gitleaks. La evidencia del Lab 3 contiene IPs del laboratorio, no credenciales.

**Análisis SCA:**

El proyecto no tiene archivo de dependencias de aplicación (`package.json`, `requirements.txt`, etc.). Sus componentes de terceros son:
- las GitHub Actions de los workflows, cubiertas por Dependabot con `package-ecosystem: github-actions`;
- Nginx y la imagen `ghcr.io/zaproxy/zaproxy:stable`, que Dependabot no ve. Nginx se instala con `apt` en el servidor y la imagen de ZAP se invoca dentro de un `run:`.

| Acción | Versión usada | Última (2026-11-08) | Advisory (GHSA) | ¿Aplica? |
|---|---|---|---|---|
| `actions/checkout` | v4 | v7.0.1 | Ninguno | — |
| `actions/setup-python` | v5 | v7.1.0 | Ninguno | — |
| `actions/upload-artifact` | v4 | v7.0.2 | Ninguno | — |
| `gitleaks/gitleaks-action` | v3 | v3.0.0 | Ninguno | — |

Dependencia analizada: **`actions/upload-artifact@v4`** (3 versiones mayores atrás).
- **Alcance:** solo se ejecuta en el CI, nunca en el sitio desplegado, y sube `semgrep.json` y el informe de ZAP como artefactos.
- **Vulnerabilidad:** no hay advisory publicado, así que el riesgo es de mantenimiento, no una vulnerabilidad explotable.
- **Compatibilidad:** los cambios incompatibles de v5 y v6 son Node.js 24 y runner ≥ 2.327.1. Usamos runners `ubuntu-latest` hospedados por GitHub, que ya cumplen. En v7 el parámetro nuevo `archive` es opcional y su valor por defecto mantiene el comportamiento actual.
- **Medida correctiva:** actualizar a v7, fijada por SHA, junto con F-01. A partir de ahí, Dependabot propone las siguientes actualizaciones por PR semanal.

## 3. Hallazgos y gestión
| ID | Categoría | Descripción sin secretos | Riesgo | Archivo/ruta | Cambio propuesto | Estado |
|---|---|---|---|---|---|---|
| F-01 | CWE-829 / OWASP A08 (integridad de software) | Acciones de GitHub referenciadas por etiqueta mutable (`@v3`, `@v4`) en lugar de un SHA de commit | Medio (integridad del pipeline) | `.github/workflows/*.yml` | Fijar cada `uses:` a un SHA completo y dejar que Dependabot lo actualice | Abierto |
| F-02 | CWE-1104 (componentes sin mantenimiento) / OWASP A06 | Acciones de CI con 2–3 versiones mayores de atraso, sin un CVE conocido | Bajo | `.github/workflows/*.yml` | Actualizar a la última versión mayor compatible y activar Dependabot version updates | Abierto |

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
