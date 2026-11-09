#!/usr/bin/env bash
# DAST pasivo local (alternativa a staging HTTPS): Nginx con la config del repo + ZAP Baseline.
# Uso: scripts/dast-local.sh <sufijo>   ->  evidence/lab5/zap-<sufijo>.{html,json}
set -euo pipefail
cd "$(dirname "$0")/.."
SUFIJO=${1:?Uso: $0 <antes|despues>}

docker network create zap-lab >/dev/null 2>&1 || true
docker rm -f muv-staging >/dev/null 2>&1 || true
docker run -d --name muv-staging --network zap-lab -p 127.0.0.1:8080:80 \
  -v "$PWD/nginx/muvautomation.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$PWD/app:/var/www/muvautomation:ro" nginx:stable >/dev/null
trap 'docker rm -f muv-staging >/dev/null' EXIT
sleep 2

docker run --rm --network zap-lab -v "$PWD/evidence/lab5:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://muv-staging -m 1 -r "zap-$SUFIJO.html" -J "zap-$SUFIJO.json" -I
