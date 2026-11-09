# Informe técnico de hallazgos

**Proyecto:** MuvAutomation Secure Challenge (sitio estático + Nginx)
**Integrantes:** David Patacón, Marlio Charry
**Repositorio / commit:** https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry. Línea base `53f8d29`, integración [PR #3](https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry/pull/3), remediación [PR #7](https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry/pull/7)
**Entorno autorizado:** repositorio propio y Nginx local en Docker (`127.0.0.1:8080`) con la configuración del repositorio. Datos ficticios.
**Fecha:** 2026-11-09

## Resumen ejecutivo
Se integraron al ciclo de desarrollo 6 controles: SAST (Semgrep y CodeQL), detección de secretos (Gitleaks y secret scanning de GitHub), SCA (Dependabot), DAST pasivo (ZAP Baseline) y una prueba de regresión que corre en cada PR. No se encontraron secretos. Los tres riesgos principales fueron:

1. **F-01: pipeline de CI dependiente de etiquetas mutables (Medio, integridad).** Una acción de un tercero comprometida podía ejecutar código con el `GITHUB_TOKEN`. **Corregido:** las acciones están fijadas por SHA.
2. **F-03: ausencia de Content-Security-Policy (Medio, integridad/confidencialidad del navegador).** No había una segunda barrera contra la inyección de scripts. **Corregido y validado:** el navegador ahora bloquea scripts inline.
3. **Riesgo residual heredado del Lab 3: HTTP sin TLS (H1 y H4).** Ningún control de este laboratorio lo mitiga. **Pendiente.**

En total se registraron 5 hallazgos (F-01 a F-05) y los 5 fueron corregidos en el PR #7. El detalle de todos está en [`SECURITY.md`](SECURITY.md#3-hallazgos-y-gestión).

## Metodología
Identificación del alcance → SAST → detección de secretos → SCA → DAST pasivo → validación manual no destructiva → corrección → reescaneo.

| Fase | Herramienta | Resultado inicial | Después de la corrección |
|---|---|---|---|
| SAST | Semgrep (`p/owasp-top-ten`, `p/secrets`) | 6 | 0 |
| SAST | CodeQL Default setup (`actions`) | 0 | 0 |
| Secretos | Gitleaks (historial completo) y secret scanning | 0 | 0 |
| SCA | Dependabot | 0 alertas; 3 PRs de actualización (#4–#6) | Acciones en la última versión, fijadas por SHA |
| DAST | ZAP Baseline local (`scripts/dast-local.sh`) | 4 WARN (1 Medio) | 1 WARN (Informativo, aceptado) |
| Regresión | `scripts/test-headers.sh` (job de CI) | Falla | Pasa |

## Hallazgo F-01
- **Título:** Acciones de GitHub referenciadas por etiqueta mutable.
- **Categoría OWASP/CWE:** A08:2021 Fallas de integridad de software y datos / CWE-829.
- **Severidad y justificación:** **Media.** La explotación requiere que se comprometa el repositorio de la acción, lo cual ha ocurrido en casos reales (`tj-actions/changed-files`, 2025). El impacto alcanza al pipeline y a su token. Las acciones de `actions/*` las publica GitHub y tienen un riesgo menor (falsa alarma parcial). `gitleaks/gitleaks-action` es de un tercero.
- **Evidencia minimizada:** Semgrep `github-actions-mutable-action-tag` en 6 líneas, por ejemplo `uses: gitleaks/gitleaks-action@v3`. Archivo: `evidence/lab5/semgrep-antes.json`.
- **Impacto:** integridad (código ajeno ejecutado en el CI) y confidencialidad (acceso al `GITHUB_TOKEN`).
- **Pasos de validación segura:** se verificó con la API de GitHub que `v3` y `v4` son etiquetas y no commits, y se resolvió cada etiqueta a su SHA (`gh api repos/<acción>/commits/<tag>`). No se intentó modificar ninguna acción de un tercero.
- **Corrección:** PR #7. Cada `uses:` se fijó a un SHA completo con la versión como comentario. Junto con esto se corrigió F-02: actualización a v7.x tras revisar que el único cambio incompatible, Node 24, es compatible con los runners hospedados. Se agregó `dependabot.yml` con cooldown de 7 días (F-05).
- **Resultado del reescaneo:** Semgrep pasó de 6 a 0 (`evidence/lab5/semgrep-despues.json`).

## Hallazgo F-03
- **Título:** Ausencia del header Content-Security-Policy.
- **Categoría OWASP/CWE:** A05:2021 Configuración de seguridad incorrecta / CWE-693.
- **Severidad y justificación:** **Media** (ZAP: Medium, confianza High). No es un XSS explotable hoy, porque el sitio es estático y no refleja entradas del usuario. Es la ausencia de una capa de defensa en profundidad que limitaría el impacto de una inyección futura.
- **Evidencia minimizada:** ZAP regla 10038 en `/`, `/robots.txt` y `/sitemap.xml` (`evidence/lab5/zap-antes.html`). `curl`: ninguna de 4 rutas devuelve CSP (`pentest-antes.txt`).
- **Impacto:** integridad y confidencialidad en el navegador del visitante si se llegara a inyectar un script.
- **Pasos de validación segura:** 4 peticiones `GET` de solo lectura al Nginx local. En DevTools se inyectó un `<script>` inofensivo con `console.log`, que se ejecutó (`pentest-csp-antes.png`). Sin usuarios, cookies ni sistemas de terceros.
- **Corrección:** PR #7, `nginx/muvautomation.conf`. Se agregó `Content-Security-Policy: default-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'` con `always`, para que también aplique en las respuestas 403 y 404. En el mismo cambio se agregaron los headers de F-04 (Permissions-Policy, COOP, COEP y CORP).
- **Resultado del reescaneo:**
  - ZAP pasó de 4 a 1 alerta; solo queda la informativa de caché, riesgo aceptado (`zap-despues.html`).
  - `curl` muestra la CSP en las 4 rutas (`pentest-despues.txt`).
  - El navegador bloquea el script: *"violates the following directive: default-src 'self'"* (`pentest-csp-despues.png`).
  - `scripts/test-headers.sh` falla con la configuración anterior y pasa con la nueva. Corre en cada PR (`regresion-antes.txt` / `regresion-despues.txt`).

## Reflexión final
**Qué identificaron las herramientas:**
- Semgrep encontró un riesgo de cadena de suministro en nuestro propio pipeline, que no habíamos considerado parte de la "aplicación".
- ZAP encontró los headers de seguridad que faltaban y confirmó que el hardening del Lab 3 (`server_tokens off`, `nosniff`, `X-Frame-Options`) sigue vigente.
- El reescaneo encontró un problema nuevo (F-05) en un archivo creado durante el mismo laboratorio, y 16 falsos positivos en la evidencia generada.

**Qué omitieron:**
- CodeQL no soporta HTML ni la configuración de Nginx, y su suite por defecto no detecta acciones sin fijar. Necesitó reconfiguración manual porque no detectó el lenguaje por sí solo.
- Dependabot no ve Nginx (se instala con `apt`) ni la imagen de ZAP (se invoca dentro de un `run:`).
- Ninguna herramienta pudo evaluar TLS, porque el entorno es HTTP. El riesgo más grave del proyecto, el tráfico en claro, quedó fuera del alcance de la automatización.

**Cómo integrar la seguridad al ciclo de desarrollo:**
- Ninguna herramienta cubre todo. Hay que combinarlas: dos SAST con reglas distintas, SCA y DAST.
- Cada hallazgo debe revisarse a mano (triage) antes de corregirlo.
- Una corrección debe quedar protegida por una prueba automatizada que corra en cada PR, para que no vuelva a aparecer.
