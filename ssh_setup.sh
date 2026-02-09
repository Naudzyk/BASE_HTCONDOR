#!/bin/bash
set -e

echo " Настройка Dropbear на Узл "

sudo apt update

sudo apt install dropbear


chmod -s ~
chmod 755 ~

chmod -s ~/.ssh
chmod 700 ~/.ssh

chmod 600 ~/.ssh/authorized_keys

rm -rf ~/.ssh
mkdir -p ~/.ssh ~/.ssh/run
chmod 700 ~/.ssh ~/.ssh/run

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "jovyan@jupyter-name" 2>/dev/null || true

dropbearkey -t ed25519 -f ~/.ssh/dropbear_ed25519_host_key 2>/dev/null || true

touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/id_ed25519.pub ~/.ssh/dropbear_ed25519_host_key

pkill -9 -f dropbear 2>/dev/null || true
sleep 1
dropbear -F -p 2222 -r ~/.ssh/dropbear_ed25519_host_key > /tmp/dropbear.log 2>&1 &
DROPBEAR_PID=$!
sleep 3

if nc -z localhost 2222 2>/dev/null; then
  echo "Dropbear запущен на порту 2222 (PID: $DROPBEAR_PID)"
  echo ""
  echo "ПУБЛИЧНЫЙ КЛЮЧ УЗЛА:"
  cat ~/.ssh/id_ed25519.pub
else
  echo "Dropbear НЕ запущен. Логи:"
  cat /tmp/dropbear.log 2>/dev/null || echo "Логи отсутствуют"
  exit 1
fi
