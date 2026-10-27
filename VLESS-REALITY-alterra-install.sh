
#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

if [[ $EUID -ne 0 ]]; then
  echo "Запусти от root: sudo bash install.sh"
  exit 1
fi

PORT=443
SNI="alterra.host"
CONFIG="/usr/local/etc/xray/config.json"
XRAY="/usr/local/bin/xray"
LINK_FILE="/root/vless-link.txt"

export DEBIAN_FRONTEND=noninteractive

echo "[1/7] Установка зависимостей..."
apt-get update
apt-get install -y curl ca-certificates unzip qrencode openssl python3

echo "[2/7] Установка Xray-core..."
if [[ ! -x "$XRAY" ]]; then
  bash -c "$(curl -fsSL \
    https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
fi

echo "[3/7] Проверка существующей конфигурации..."
if [[ -s "$CONFIG" ]] && python3 -c '
import json,sys
try:
    c=json.load(open(sys.argv[1]))
    i=next(x for x in c["inbounds"] if x.get("protocol")=="vless")
    r=i["streamSettings"]["realitySettings"]
    assert i["port"] == 443
    assert i["settings"]["clients"][0]["id"]
    assert r["privateKey"] and r["shortIds"]
except Exception:
    sys.exit(1)
' "$CONFIG"; then
  echo "Сохраняю существующие UUID и ключи."
  UUID="$(python3 -c 'import json;print(next(x for x in json.load(open("'"$CONFIG"'"))["inbounds"] if x.get("protocol")=="vless")["settings"]["clients"][0]["id"])')"
  PRIVATE_KEY="$(python3 -c 'import json;print(next(x for x in json.load(open("'"$CONFIG"'"))["inbounds"] if x.get("protocol")=="vless")["streamSettings"]["realitySettings"]["privateKey"])')"
  SHORT_ID="$(python3 -c 'import json;print(next(x for x in json.load(open("'"$CONFIG"'"))["inbounds"] if x.get("protocol")=="vless")["streamSettings"]["realitySettings"]["shortIds"][0])')"
  # Публичный ключ вычисляется из приватного ключа
  PUBLIC_KEY="$("$XRAY" x25519 -i "$PRIVATE_KEY" | awk '/^Password/ {print $NF}')"
else
  if ss -H -lnt "sport = :${PORT}" | grep -q .; then
    echo "Порт 443 занят. Останови конфликтующую службу и повтори."
    ss -lntp | grep ':443' || true
    exit 1
  fi

  UUID="$(cat /proc/sys/kernel/random/uuid)"
  KEYS="$("$XRAY" x25519)"
  PRIVATE_KEY="$(awk '/^PrivateKey:/ {print $2}' <<< "$KEYS")"
  PUBLIC_KEY="$(awk '/^Password/ {print $NF}' <<< "$KEYS")"
  SHORT_ID="$(openssl rand -hex 8)"

  if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    echo "Не удалось создать ключи REALITY."
    echo "$KEYS"
    exit 1
  fi

  install -d -m 755 /usr/local/etc/xray

  python3 - "$CONFIG" "$UUID" "$PRIVATE_KEY" "$SHORT_ID" "$SNI" <<'PY'
import json,sys,os
path,uid,priv,sid,sni=sys.argv[1:]
config={
 "log":{"loglevel":"warning"},
 "inbounds":[{
  "listen":"0.0.0.0","port":443,"protocol":"vless",
  "settings":{"clients":[{"id":uid,"flow":"xtls-rprx-vision"}],"decryption":"none"},
  "streamSettings":{
   "network":"raw","security":"reality",
   "realitySettings":{
    "show":False,"target":sni+":443","xver":0,
    "serverNames":[sni],"privateKey":priv,"shortIds":[sid]
   }
  }
 }],
 "outbounds":[{"protocol":"freedom","tag":"direct"},{"protocol":"blackhole","tag":"block"}]
}
with open(path,"w") as f:
    json.dump(config,f,indent=2)
    f.write("\n")
os.chmod(path,0o640)
PY

  chown root:xray "$CONFIG"
fi

if [[ -z "${PUBLIC_KEY:-}" ]]; then
  echo "Не удалось получить публичный ключ."
  exit 1
fi

echo "[4/7] Проверка конфигурации..."
"$XRAY" run -test -config "$CONFIG"

echo "[5/7] Запуск службы..."
systemctl enable xray
systemctl restart xray

if ! systemctl is-active --quiet xray; then
  journalctl -u xray -n 50 --no-pager
  exit 1
fi

if command -v ufw >/dev/null 2>&1 &&
   ufw status | grep -q "Status: active"; then
  ufw allow 443/tcp
fi

echo "[6/7] Определение IP..."
SERVER_IP="$(curl -4 -fsS --max-time 10 https://api.ipify.org || true)"
if [[ -z "$SERVER_IP" ]]; then
  read -rp "Введи публичный IPv4 VPS: " SERVER_IP
fi

echo "[7/7] Формирование ссылки..."
LINK="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&security=reality&sni=${SNI}&fp=firefox&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&flow=xtls-rprx-vision#VLESS-REALITY-Firefox"

printf '%s\n' "$LINK" > "$LINK_FILE"
chmod 600 "$LINK_FILE"

echo
echo "========================================"
echo " VLESS + REALITY | Firefox fingerprint"
echo "========================================"
echo "Server:     ${SERVER_IP}"
echo "Port:       ${PORT}"
echo "SNI:        ${SNI}"
echo "UUID:       ${UUID}"
echo "Public key: ${PUBLIC_KEY}"
echo "Short ID:   ${SHORT_ID}"
echo
echo "VLESS LINK:"
echo "$LINK"
echo
echo "QR CODE:"
qrencode -t ANSIUTF8 "$LINK"
echo
echo "Ссылка сохранена: $LINK_FILE"
echo "Статус: systemctl status xray"
echo "Логи:   journalctl -u xray -f"
echo "========================================"
