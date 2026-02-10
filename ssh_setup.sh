#!/bin/bash
set -euo pipefail

echo "Настройка Dropbear на Узле"

sudo apt update
sudo apt install -y dropbear ansible

SSH_DIR="/home/jovyan/.ssh"
mkdir -p "$SSH_DIR" "$SSH_DIR/run"
chmod 700 "$SSH_DIR" "$SSH_DIR/run"
touch "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"


chmod -s ~
chmod 755 ~

chmod -s ~/.ssh
chmod 700 ~/.ssh

chmod 600 ~/.ssh/authorized_keys

rm -rf ~/.ssh
mkdir -p ~/.ssh ~/.ssh/run
chmod 700 ~/.ssh ~/.ssh/run

if [ ! -f "$SSH_DIR/id_ed25519" ]; then
  ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N "" -C "jovyan@jupyter-zhenya" >/dev/null 2>&1 || true
fi

if [ -f "$SSH_DIR/id_ed25519.pub" ]; then
  PUB_KEY_CONTENT="$(cat "$SSH_DIR/id_ed25519.pub")"
  if ! grep -qF "$PUB_KEY_CONTENT" "$SSH_DIR/authorized_keys"; then
    printf "%s\n" "$PUB_KEY_CONTENT" >> "$SSH_DIR/authorized_keys"
  fi
fi

if [ ! -f "$SSH_DIR/dropbear_ed25519_host_key" ]; then
  dropbearkey -t ed25519 -f "$SSH_DIR/dropbear_ed25519_host_key" >/dev/null 2>&1 || true
fi
chmod 600 "$SSH_DIR/dropbear_ed25519_host_key"

pkill -9 -f "dropbear -F -p 2222" >/dev/null 2>&1 || true
sleep 1

touch /tmp/dropbear.log
dropbear -E -F -p 2222 -r "$SSH_DIR/dropbear_ed25519_host_key" > /tmp/dropbear.log 2>&1 &
DROPBEAR_PID=$!
sleep 2

is_listening=1
if command -v pgrep >/dev/null 2>&1; then
  if pgrep -f "dropbear .* -p 2222" >/dev/null 2>&1; then
    is_listening=0
  fi
fi
if [ "$is_listening" -ne 0 ] && command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '$4 ~ /:2222$/ {found=1} END {exit found?0:1}'; then
    is_listening=0
  fi
fi
if [ "$is_listening" -ne 0 ] && command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:2222 -sTCP:LISTEN >/dev/null 2>&1; then
    is_listening=0
  fi
fi
if [ "$is_listening" -ne 0 ]; then
  if kill -0 "$DROPBEAR_PID" >/dev/null 2>&1; then
    is_listening=0
  fi
fi

if [ "$is_listening" -eq 0 ]; then
  echo "Dropbear запущен на порту 2222 (PID: $DROPBEAR_PID)"
  echo ""
  echo "ПУБЛИЧНЫЙ КЛЮЧ УЗЛА:"
  cat "$SSH_DIR/id_ed25519.pub"
else
  echo "Dropbear НЕ запущен. Логи:"
  cat /tmp/dropbear.log 2>/dev/null || echo "Логи отсутствуют"
  if command -v ps >/dev/null 2>&1; then
    echo ""
    echo "Процессы dropbear:"
    ps -ef | awk '/[d]ropbear/ {print}'
  fi
  exit 1
fi

