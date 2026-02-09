# BASE_HTCONDOR
# Подготовка развертывания 

1. Разместите скрипт ssh_setup.sh на узлах

2. Сделайте скрипт исполняемым
```
 chmod +x ssh_setup.ssh
```

3. Запустите скрипт настройки SSH
```
./ssh_setup.ssh
```

4. Обмен публичными SSH-ключами между узлами 
```
    echo "ssh-rsa AAAAB3NzaC1yc2E... alice@node1" >> ~/.ssh/authorized_keys
```
    ( На узеле откуда будем запускать скрипты плюсом скопировать его публичный ключ на этот узел )

5. Подставить данные в inventory.ini а именно ip и user

6. Запустить через Ansible скрипт
```
    ansible-playbook htcondor-cluster.yml -i inventory.ini
```
