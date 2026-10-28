# Seguridad del proyecto — evidencia del laboratorio

## 1. Alcance autorizado
- Repositorio: https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry (público)
- Tecnología: sitio estático HTML servido por Nginx (`nginx/muvautomation.conf`). Sin autenticación, sin APIs, sin backend ni base de datos.
- Rama evaluada y commit: línea base `lab-5` @ `53f8d29` (estado final Lab 3); pipeline en `security/lab-fsi` @ `dbf58b4`; corrección en `fix/headers-actions` @ `b88ae9b`.
- Activos: `app/index.html`, `app/public-inventory.txt` (datos ficticios), configuración Nginx, workflows de GitHub Actions.
- Riesgo principal: configuración insegura del servidor web (headers, transporte HTTP sin TLS) y cadena de suministro del pipeline CI.
- URL de staging propio: no se dispone de staging HTTPS. **Alternativa documentada:** contenedor `nginx:stable` local con la misma configuración (`http://localhost:8080`, red Docker aislada `lab5`).
- Responsable / autorización: equipo David Patacón / Marlio Charry, propietarios del repositorio — 2026-10-28.
- Fuera de alcance: producción (EC2 del Lab 3), sistemas de terceros, datos reales y pruebas destructivas.

## 2. Línea base y herramientas
| Herramienta | Tipo | Fecha | Resultado | Enlace a evidencia |
|---|---|---|---|---|
| Semgrep (`p/default` + `r/generic.nginx`) | SAST | 2026-10-28 | 6 hallazgos → 0 tras corrección | `evidence/lab5/antes/semgrep.txt`, `evidence/lab5/despues/semgrep.txt`, artefacto `resultado-semgrep` |
| CodeQL Default setup | SAST | — | Pendiente de habilitar en Settings (ver §6) | captura |
| Gitleaks (historial completo) | Secretos | 2026-10-28 | 0 secretos en 13/14 commits | `evidence/lab5/antes/gitleaks.txt`, `evidence/lab5/despues/gitleaks.txt`, job `gitleaks` |
| Dependabot (`github-actions`) | SCA | 2026-10-28 | Sin manifiestos de paquetes; se monitorean las Actions | `.github/dependabot.yml` |
| OWASP ZAP Baseline (local) | DAST pasivo | 2026-10-28 | 4 WARN → 1 WARN | `evidence/lab5/antes/zap-report.html`, `evidence/lab5/despues/zap-report.html` |

### Interpretación SAST (dos resultados)
1. `github-actions-mutable-action-tag` (5 ocurrencias) — **verdadero positivo**. `uses: actions/checkout@v4` apunta a un tag que el dueño puede mover; un tag comprometido ejecutaría código arbitrario en nuestro CI (casos reales: tj-actions, trivy-action). Corregido fijando SHA.
2. `dependabot-missing-cooldown` — **verdadero positivo, severidad baja**. Sin espera, Dependabot propondría versiones recién publicadas (posible paquete malicioso). Corregido con `cooldown.default-days: 7`.

**Falsa alarma / riesgo aceptado:** ZAP `10049 Storable and Cacheable Content` — el contenido es público y ficticio; que proxies lo almacenen no expone nada. Se acepta.

### SCA
El proyecto no tiene `package.json`, `requirements.txt` ni similares: no hay librerías de aplicación. Componentes de terceros reales:
| Componente | Versión | Alcance | Medida |
|---|---|---|---|
| `actions/checkout`, `actions/upload-artifact`, `gitleaks/gitleaks-action` | v4 / v4 / v2 (tag mutable) | CI, con acceso al código y `GITHUB_TOKEN` | Fijadas por SHA; Dependabot propone actualizaciones con cooldown 7 días |
| Nginx (servidor EC2) | `1.28.3 (Ubuntu)` según Lab 3 | Producción | Paquete del SO: lo cubre `apt`/`unattended-upgrades`, no Dependabot. Verificar con `apt list --upgradable` en el servidor; no se actualiza a ciegas |
| Imagen `nginx:stable` | tag `stable` | Solo pruebas locales | Aceptado (no se despliega) |

## 3. Hallazgos y gestión
| ID | Categoría | Descripción sin secretos | Riesgo | Archivo/ruta | Cambio propuesto | Estado |
|---|---|---|---|---|---|---|
| F-01 | OWASP A05:2021 / CWE-693 | Faltan `Content-Security-Policy`, `Permissions-Policy`, `Cross-Origin-Embedder-Policy` | Medio | `nginx/muvautomation.conf` | Agregar headers con `always` | **Corregido** (PR #2) |
| F-02 | OWASP A08:2021 / CWE-829 | Actions referenciadas por tag mutable | Medio | `.github/workflows/*.yml` | Pin por SHA + cooldown Dependabot | **Corregido** (PR #2) |
| F-03 | Informativo | Contenido almacenable en caché (ZAP 10049) | Bajo | `/`, `/public-inventory.txt` | Ninguno | Aceptado |
| F-04 | OWASP A02:2021 / CWE-319 | Sitio servido por HTTP sin TLS (H1/H4 del Lab 3) | Alto | `nginx/muvautomation.conf` | TLS + HSTS | Abierto (requiere dominio/certificado) |

## 4. Validación antes y después
- Evidencia inicial: `evidence/lab5/antes/` (headers, ZAP, Semgrep, `regresion.txt` con 12 FAIL).
- Pull request con corrección: https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry/pull/2
- Evidencia de reescaneo: `evidence/lab5/despues/` (ZAP 1 WARN, Semgrep 0, regresión 18 OK).
- Riesgo residual y decisión: F-03 aceptado; F-04 sigue abierto hasta tener HTTPS. La CSP debe actualizarse si se agregan scripts o estilos.

## 5. Pentest autorizado
- Hipótesis: el servidor no envía `Content-Security-Policy`, por lo que un contenido inyectado o un framing no estaría restringido por el navegador.
- Entorno de pruebas aislado: contenedor `nginx:stable` local con `nginx/muvautomation.conf`, red Docker `lab5`, datos ficticios.
- Solicitudes inocuas y respuestas observadas: `curl -sI http://localhost:8080/` → `200 OK` con `X-Frame-Options`, `nosniff`, `Referrer-Policy`, **sin** `Content-Security-Policy` ni `Permissions-Policy` (`evidence/lab5/antes/headers.txt`). Tras la corrección aparecen ambos (`evidence/lab5/despues/headers.txt`).
- Resultado: **validado**.
- Recomendación y prueba de regresión: `tests/headers.sh` levanta Nginx con la config del repo y exige los headers en `/`, `/public-inventory.txt`, una 404 y la 403 de `/.git/config`. Corre en CI (job `regresion-headers`).

## 6. Pendientes manuales (Settings de GitHub)
- Settings → Advanced Security: habilitar **Dependabot alerts**, **Secret scanning** y **CodeQL → Default setup** (lenguaje detectable: GitHub Actions). Guardar capturas.
- Opcional: si se obtiene un staging HTTPS propio, definir la variable `STAGING_URL` y ejecutar **Actions → DAST pasivo - staging autorizado**.
