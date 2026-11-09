#!/usr/bin/env bash
# Prueba de regresión: levanta Nginx con la config del repo y falla si falta un control de seguridad.
set -uo pipefail
cd "$(dirname "$0")/.."
URL=http://127.0.0.1:8080

docker rm -f muv-test >/dev/null 2>&1 || true
docker run -d --name muv-test -p 127.0.0.1:8080:80 \
  -v "$PWD/nginx/muvautomation.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$PWD/app:/var/www/muvautomation:ro" nginx:stable >/dev/null
trap 'docker rm -f muv-test >/dev/null' EXIT
sleep 2

fallos=0
revisar() { # $1 ruta, $2 código esperado
  local h; h=$(curl -s -o /dev/null -D - "$URL$1")
  echo "$h" | grep -q "^HTTP/1.1 $2" || { echo "FALLA $1: se esperaba $2"; fallos=1; }
  for header in Content-Security-Policy Permissions-Policy Cross-Origin-Opener-Policy \
                Cross-Origin-Embedder-Policy Cross-Origin-Resource-Policy \
                X-Content-Type-Options X-Frame-Options Referrer-Policy; do
    echo "$h" | grep -qi "^$header:" || { echo "FALLA $1: falta $header"; fallos=1; }
  done
  echo "$h" | grep -qi '^Server: nginx/' && { echo "FALLA $1: Server expone versión"; fallos=1; }
}
revisar / 200
revisar /public-inventory.txt 200
revisar /no-existe 404
revisar /.git/config 403

[ $fallos -eq 0 ] && echo "OK: todos los controles presentes" || exit 1
