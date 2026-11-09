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
| CodeQL Default setup (lenguaje `actions`) | SAST | 2026-11-09 | 0 alertas. Analiza solo los workflows; HTML y Nginx no son lenguajes soportados. | `evidence/lab5/codeql.png`, Security → Code scanning |
| Semgrep (`p/owasp-top-ten`, `p/secrets`) | SAST | 2026-11-08 | 6 resultados, 1 regla: `github-actions-mutable-action-tag` | [PR #3](https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry/pull/3), `evidence/lab5/semgrep-antes.json`, `actions-1.png` |
| Gitleaks (historial completo) | Secretos | 2026-11-08 | 0 fugas | `evidence/lab5/gitleaks-antes.sarif`, `actions-2.png` |
| Dependabot (alerts + `.github/dependabot.yml`) | SCA | 2026-11-09 | 0 alertas de seguridad. El grafo detecta las 4 acciones. Dependabot abrió 3 PRs de actualización (#4 `upload-artifact` 4→7, #5 `checkout` 4→7, #6 `setup-python` 5→7). | `evidence/lab5/dependabot.png`, `dependabot-pr.png`, `.github/dependabot.yml` |
| OWASP ZAP Baseline (local, Docker) | DAST pasivo | 2026-11-09 | 0 FAIL, 4 reglas WARN: CSP ausente (Medio); Permissions-Policy, COEP, COOP y CORP ausentes (Bajo); contenido cacheable (Informativo). 64 reglas pasan. | `evidence/lab5/zap-antes.html`, `zap-antes.json`, `scripts/dast-local.sh` |

**Limitación CodeQL:** el Default setup se activó cuando el repositorio no tenía ningún lenguaje soportado (`languages: []`), y después del merge no detectó los workflows por sí solo. Se reconfiguró con el lenguaje `actions` y el análisis terminó con 0 alertas. CodeQL no reporta F-01 porque la consulta de acciones sin fijar no está en la suite por defecto; Semgrep sí la incluye. Por eso se usan dos herramientas SAST con cobertura complementaria. HTML y Nginx no tienen soporte en CodeQL.

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

**Alternativa DAST documentada:** no hay staging HTTPS. La instancia EC2 del Lab 3 no está disponible y el workflow `dast-staging.yml` exige HTTPS. Se aplicó la alternativa que permite la guía: `scripts/dast-local.sh` levanta `nginx:stable` en Docker con `nginx/muvautomation.conf` y `app/` del repositorio, publicado solo en `127.0.0.1:8080`, y ejecuta `zap-baseline.py` (solo spider + reglas pasivas, sin ataques activos) desde otro contenedor en una red Docker aislada. Limitación: al ser HTTP, ZAP no puede evaluar TLS ni HSTS. Esos riesgos (H1 y H4 del Lab 3) siguen pendientes.

**Triage de ZAP:**
- **CSP ausente (10038, Medio), verdadero positivo:** sin `Content-Security-Policy`, el navegador no restringe de dónde se cargan scripts ni recursos, así que no hay una segunda barrera si alguna vez se inyecta contenido (XSS).
- **Permissions-Policy y COEP/COOP/CORP (Bajo), verdaderos positivos de bajo impacto:** el sitio no usa cámara, geolocalización ni ventanas cruzadas. Son defensa en profundidad.
- **Storable and Cacheable Content (Informativo), falsa alarma en este contexto:** el contenido es público y ficticio, así que su almacenamiento en caché no expone nada. Riesgo aceptado.

## 3. Hallazgos y gestión
| ID | Categoría | Descripción sin secretos | Riesgo | Archivo/ruta | Cambio propuesto | Estado |
|---|---|---|---|---|---|---|
| F-01 | CWE-829 / OWASP A08 (integridad de software) | Acciones de GitHub referenciadas por etiqueta mutable (`@v3`, `@v4`) en lugar de un SHA de commit | Medio (integridad del pipeline) | `.github/workflows/*.yml` | Fijar cada `uses:` a un SHA completo y dejar que Dependabot lo actualice | Corregido (PR de remediación) |
| F-02 | CWE-1104 (componentes sin mantenimiento) / OWASP A06 | Acciones de CI con 2–3 versiones mayores de atraso, sin un CVE conocido | Bajo | `.github/workflows/*.yml` | Actualizar a la última versión mayor compatible y activar Dependabot version updates | Corregido (PR de remediación) |
| F-03 | CWE-693 / OWASP A05 (configuración) | Falta el header `Content-Security-Policy` en todas las respuestas, incluidos los errores 404 | Medio | `nginx/muvautomation.conf` | Agregar una CSP restrictiva (`default-src 'self'`) con `always` | Corregido (PR de remediación) |
| F-04 | CWE-693 / OWASP A05 | Faltan `Permissions-Policy`, `Cross-Origin-Opener-Policy`, `Cross-Origin-Embedder-Policy` y `Cross-Origin-Resource-Policy` | Bajo | `nginx/muvautomation.conf` | Agregar los headers con valores restrictivos | Corregido (PR de remediación) |
| F-05 | CWE-1357 (dependencia de componente no confiable) | `dependabot.yml` sin `cooldown`: una versión nueva (posiblemente comprometida) se propondría el mismo día de su publicación. Lo detectó Semgrep en el reescaneo. | Bajo | `.github/dependabot.yml` | `cooldown.default-days: 7` | Corregido (PR de remediación) |

## 4. Validación antes y después
| Control | Antes | Después | Evidencia |
|---|---|---|---|
| Semgrep | 6 resultados (`mutable-action-tag`) | 0 resultados | `semgrep-antes.json` → `semgrep-despues.json` |
| ZAP Baseline | 4 reglas WARN (CSP Medio + 3 Bajo + 1 Info) | 1 regla WARN (solo la informativa, riesgo aceptado); 67 reglas pasan | `zap-antes.html` → `zap-despues.html` |
| Pentest `curl` | CSP ausente en las 4 rutas | CSP presente en las 4 rutas (incluidos 404 y 403) | `pentest-antes.txt` → `pentest-despues.txt` |
| Prueba en el navegador | Script inline se ejecuta | El navegador lo bloquea (violación de CSP) | `pentest-csp-antes.png` → `pentest-csp-despues.png` |
| Prueba de regresión | `exit=1` con varios FALLA | `OK: todos los controles presentes` | `regresion-antes.txt` → `regresion-despues.txt` |
| Acciones de CI | Etiquetas `@v3`/`@v4`/`@v5` | SHA fijo de v7.x / v3.0.0 | `.github/workflows/*.yml` |

- **Corrección:**
  - `nginx/muvautomation.conf`: CSP, Permissions-Policy, COOP, COEP y CORP, todos con `always`.
  - Workflows: acciones fijadas por SHA, con la versión en un comentario para que Dependabot pueda actualizarlas.
  - `dependabot.yml` con cooldown.
  - `.semgrepignore` excluye `evidence/`, porque los reportes HTML de ZAP generaban 16 falsos positivos `plaintext-http-link`.
- **Prueba de regresión:** `scripts/test-headers.sh` levanta Nginx con la configuración del repositorio. Falla si falta algún header de seguridad, si `Server` expone la versión o si `/.git/config` deja de devolver 403. Se ejecuta en cada PR como el job `Regresión de headers (Nginx)` del workflow `seguridad-estatica.yml`.
- **Pull request con corrección:** rama `security/remediacion` → `main` (enlace al agregarlo).
- **Riesgo residual y decisión:**
  - **H1 y H4 del Lab 3 (sin TLS):** siguen abiertos. La CSP no protege contenido que viaja en claro. Pendiente: HTTPS y HSTS.
  - **Caché de contenido público:** riesgo aceptado.
  - **Despliegue al servidor:** la CSP debe aplicarse en el servidor real con `nginx -t && systemctl reload nginx`.

## 5. Pentest autorizado
- **Hipótesis (F-03):** el servidor no envía `Content-Security-Policy` en ninguna respuesta. Por eso el navegador ejecutaría cualquier script inline o externo que llegara a la página, y no hay una segunda barrera contra XSS.
- **Entorno de pruebas aislado:** contenedor `nginx:stable` con `nginx/muvautomation.conf` y `app/` del repositorio, publicado solo en `127.0.0.1:8080`. No hay usuarios, cookies ni datos reales.
- **Solicitudes inocuas y respuestas observadas:**
  - Se hicieron 4 peticiones `GET` de solo lectura con `curl`, en estos casos: página principal (200), archivo estático (200), ruta inexistente (404) y ruta oculta `/.git/config` (403).
  - **Ninguna** respuesta incluye `Content-Security-Policy`. Los headers del Lab 3 (`nosniff`, `X-Frame-Options`, `Referrer-Policy`) sí están presentes, y `/.git/config` sigue bloqueado.
  - Evidencia: `evidence/lab5/pentest-antes.txt`.
- **Prueba en el navegador:** en la consola de DevTools, con la página abierta, se agregó un `<script>` inline inofensivo (`console.log`). Se ejecuta porque no hay política que lo bloquee. Evidencia: `evidence/lab5/pentest-csp-antes.png`.
- **Resultado:** **validado**. Es una debilidad de configuración (falta un control de defensa en profundidad). No es un XSS explotable hoy: el sitio es estático y no refleja datos del usuario. Por eso el riesgo es Medio y no Alto.
- **Recomendación y prueba de regresión:** agregar en Nginx una CSP restrictiva con `always`, para que también se envíe en las respuestas 4xx, y verificarla con un script automático que falle si el header desaparece (Parte 7).
