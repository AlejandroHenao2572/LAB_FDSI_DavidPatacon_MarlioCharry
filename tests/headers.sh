#!/usr/bin/env bash
# Prueba de regresion: levanta nginx con nuestra config y exige los headers de seguridad.
# Uso: tests/headers.sh   (requiere docker; sale != 0 si falta alguno)
set -u
cd "$(dirname "$0")/.."
docker rm -f headers-test >/dev/null 2>&1
docker run -d --name headers-test -p 18080:80 \
  -v "$PWD/nginx/muvautomation.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$PWD/app:/var/www/muvautomation:ro" nginx:stable >/dev/null
trap 'docker rm -f headers-test >/dev/null' EXIT
for _ in $(seq 20); do curl -s -o /dev/null localhost:18080 && break; sleep 0.5; done

fail=0
check() { # check <ruta> <header-regex>
  if curl -sI "localhost:18080$1" | grep -qiE "^$2"; then echo "OK   $1  $2"; else echo "FAIL $1  $2"; fail=1; fi
}
for path in / /public-inventory.txt /no-existe /.git/config; do
  check "$path" "Content-Security-Policy: .*default-src 'none'.*frame-ancestors 'none'"
  check "$path" "Permissions-Policy: "
  check "$path" "Cross-Origin-Embedder-Policy: require-corp"
  check "$path" "X-Content-Type-Options: nosniff"
done
check / "Server: nginx\s*$"                        # sin version
curl -s -o /dev/null -w '%{http_code}' localhost:18080/.git/config | grep -q 403 \
  && echo "OK   /.git/config 403" || { echo "FAIL /.git/config no es 403"; fail=1; }
exit $fail
