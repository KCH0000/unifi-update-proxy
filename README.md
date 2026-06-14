# unifi-update-proxy

NGINX stream-прокси (SNI passthrough) для доступа UniFi-устройств к серверам обновлений Ubiquiti.

**Зачем:** в РФ серверы обновлений UniFi (`*.ui.com`, `*.ubnt.com`) заблокированы — устройства и Network Application не могут скачать прошивки и пакеты. Прокси ставится на хост с доступом к Ubiquiti, DNS в вашей сети указывает домены обновлений на него. Трафик не расшифровывается, MITM нет.

## Как работает

1. Клиент подключается к прокси:443 с SNI `fw-download.ui.com`
2. NGINX читает SNI, проксирует TCP на реальный `fw-download.ui.com:443`
3. TLS end-to-end, сертификаты Ubiquiti

Домены в конфиге: `fw-download.*`, `fw-update.*`, `apt*.artifacts.ui.com`, `dl.ui.com`, `dl.ubnt.com`, `static.ubnt.com`.

Опционально — маппинг домена контроллера на локальный адрес (см. конфиг).

## Где запускать

Хост с:
- входящим 443 от UniFi-сети
- исходящим доступом к серверам Ubiquiti (VPS за рубежом — типичный вариант для РФ)
- свободным портом 443

| Вариант | Схема |
|---|---|
| VPS за рубежом | DNS → VPS, устройства через VPN или белый IP |
| Локальный хост + VPN upstream | Прокси в LAN, выход в Ubiquiti через туннель |
| Хост в LAN | Split DNS → внутренний IP прокси |

## Запуск

```bash
git clone https://github.com/<your-username>/unifi-update-proxy.git
cd unifi-update-proxy
docker compose up -d --build
```

Логи SNI:

```bash
docker compose exec unifi-proxy tail -f /var/log/nginx/stream_access.log
```

Конфиг: `stream.conf.d/unifi-firmware-proxy.conf`. После правок — `docker compose up -d --build`.

## DNS

A-записи (или dnsmasq `address=/`) — все домены на IP прокси:

```
fw-download.ubnt.com
fw-download.ui.com
fw-update.ubnt.com
fw-update.ui.com
apt.artifacts.ui.com
apt-beta.artifacts.ui.com
apt-release-candidate.artifacts.ui.com
dl.ui.com
dl.ubnt.com
static.ubnt.com
```

Пример dnsmasq:

```
address=/fw-download.ui.com/192.168.1.50
address=/fw-update.ui.com/192.168.1.50
# ... остальные домены
```

Split DNS на роутере / Pi-hole / AdGuard — где удобно. UniFi-устройства должны резолвить через этот DNS.

Проверка:

```bash
dig +short fw-download.ui.com   # → IP прокси
```

## Белый список IP

В `stream.conf.d/unifi-firmware-proxy.conf`, блок `server`:

```nginx
  allow 203.0.113.10;
  allow 10.8.0.0/24;   # VPN-подсеть
  deny all;
```

`deny all` — обязательно последним. Пересборка: `docker compose up -d --build`.

Фильтруется IP источника TCP-соединения (не конечного устройства за NAT).

## Структура

```
├── docker-compose.yml
├── Dockerfile
├── nginx.conf
└── stream.conf.d/unifi-firmware-proxy.conf
```

## Лицензия

MIT
