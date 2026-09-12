# CrowdStrike Falcon - Incident Automation Lab

## Propósito
Prototipo académico (FDSI, Laboratorio 3 - Secure Product Challenge) que simula
la recepción y consulta de alertas de seguridad de CrowdStrike Falcon (Alerts API),
usando datos ficticios. No se integra con CrowdStrike real ni usa credenciales reales.

## Requisitos
- Ubuntu Server 26.04 LTS
- Nginx
- Python 3 (para pruebas locales)
- Git

## Ejecución local
cd app
python3 -m http.server 8080
# abrir http://localhost:8080

## Procedimiento de despliegue
1. sudo apt install -y nginx
2. Copiar app/ a /var/www/crowdstrike-lab
3. Copiar nginx/crowdstrike-lab.conf a /etc/nginx/sites-available/ y habilitarlo
4. sudo nginx -t && sudo systemctl reload nginx
5. Firewall: permitir solo el segmento 192.168.56.0/24 en el puerto 80 (ufw)

## URL publicada
http://192.168.56.102/ — red host-only de VirtualBox (entorno de laboratorio local,
sin exposición a internet por falta de créditos cloud).

## Integrantes
David Alejandro Patacón Henao, Marlio Charry

## Limitaciones de seguridad conocidas
- Servicio HTTP sin cifrado (sin TLS) — se corrige en Laboratorio 4.
- Sin autenticación ni autorización — se corrige en Laboratorio 4.
- (se completa tras el modelo de amenazas, sección 8)

