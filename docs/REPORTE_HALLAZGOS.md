# Informe técnico de hallazgos

**Proyecto:** MuvAutomation Secure Challenge (sitio estático + Nginx)  
**Integrantes:** David Patacón, Marlio Charry  
**Repositorio / commit:** https://github.com/AlejandroHenao2572/LAB_FDSI_DavidPatacon_MarlioCharry — base `53f8d29`, corrección `b88ae9b`  
**Entorno autorizado:** contenedor Docker local `nginx:stable` con la configuración del repositorio (sin staging HTTPS disponible)  
**Fecha:** 2026-10-28  

## Resumen ejecutivo
1. **Headers de seguridad incompletos (F-01):** sin CSP ni Permissions-Policy el navegador no limita qué puede cargar o ejecutar la página. Corregido.
2. **Pipeline con dependencias mutables (F-02):** las Actions se referenciaban por tag; un tag comprometido ejecutaría código en nuestro CI con acceso al repositorio. Corregido fijando SHA.
3. **Transporte HTTP sin TLS (F-04):** confidencialidad e integridad en tránsito siguen sin protección. Abierto: requiere dominio y certificado.

## Metodología
Identificación del alcance → SAST (Semgrep) → detección de secretos (Gitleaks, historial completo) → SCA (inventario manual + Dependabot para Actions) → DAST pasivo (ZAP Baseline local) → validación manual no destructiva (`curl -I`) → corrección (PR #2) → reescaneo con las mismas herramientas.

## Hallazgo F-01
- **Título:** Ausencia de Content-Security-Policy, Permissions-Policy y Cross-Origin-Embedder-Policy
- **Categoría OWASP/CWE:** A05:2021 Security Misconfiguration / CWE-693 Protection Mechanism Failure
- **Severidad y justificación:** Media. El sitio no tiene entradas de usuario hoy, así que no hay XSS explotable; pero sin CSP cualquier inyección futura no tendría defensa en profundidad.
- **Evidencia minimizada:** ZAP alertas 10038, 10063, 90004 (`evidence/lab5/antes/zap-summary.txt`); `curl -sI` sin los headers (`evidence/lab5/antes/headers.txt`).
- **Impacto:** Integridad (ejecución de contenido no previsto), Confidencialidad (exfiltración vía recursos externos).
- **Pasos de validación segura:** `docker run nginx:stable` con `nginx/muvautomation.conf` → `curl -sI http://localhost:8080/` → confirmar ausencia de headers. Solo peticiones HEAD/GET.
- **Corrección:** PR #2, commit `b88ae9b`: `add_header ... always` para CSP (`default-src 'none'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`), Permissions-Policy y COEP/COOP/CORP.
- **Resultado del reescaneo:** ZAP 4 WARN → 1 WARN (solo 10049, aceptado). `tests/headers.sh` 12 FAIL → 0.

## Hallazgo F-02
- **Título:** GitHub Actions referenciadas por tag mutable
- **Categoría OWASP/CWE:** A08:2021 Software and Data Integrity Failures / CWE-829
- **Severidad y justificación:** Media. Ataque de cadena de suministro real y documentado (tj-actions/changed-files, 2025); el job tiene `GITHUB_TOKEN`.
- **Evidencia minimizada:** Semgrep `github-actions-mutable-action-tag` ×5 y `dependabot-missing-cooldown` ×1 (`evidence/lab5/antes/semgrep.txt`).
- **Impacto:** Integridad del código y del pipeline; Confidencialidad del token.
- **Pasos de validación segura:** revisión estática de `.github/workflows/*.yml`; no se requiere explotación.
- **Corrección:** PR #2: SHA de 40 caracteres resuelto con `gh api repos/<owner>/<repo>/commits/<tag>`, comentario con la versión, y `cooldown` en `dependabot.yml`.
- **Resultado del reescaneo:** Semgrep en CI 21 → 0 (7 verdaderos positivos corregidos; 14 falsos positivos en archivos de evidencia excluidos con `.semgrepignore`).

## Hallazgo F-03 (falsa alarma / aceptado)
- ZAP 10049 *Storable and Cacheable Content*: el contenido es público y ficticio; el cacheo no expone información. Se acepta sin cambios.

## Reflexión final
Las herramientas detectaron bien la configuración observable (headers) y patrones en YAML. No detectaron: la ausencia de TLS como problema de diseño (ZAP en local con HTTP no lo reporta como riesgo alto), la versión real de Nginx en el servidor EC2 (Dependabot no cubre paquetes del SO) ni el contexto de negocio (qué datos son realmente sensibles). Un estado verde del pipeline no significa aplicación segura: `|| true` en Semgrep y `-I` en ZAP no bloquean. Para integrarlo al ciclo de desarrollo: hacer obligatorios los jobs `gitleaks` y `regresion-headers` en la protección de rama, quitar `|| true` tras el triage, y añadir TLS + HSTS con su propia prueba de regresión.
