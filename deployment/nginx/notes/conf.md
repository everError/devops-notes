# Nginx 프록시 설정 정리 (WebSocket 포함)

## 📌 목적

**Nginx를 사용하여 API 서버 및 WebSocket 서버에 대한 프록시 설정 방법** 프론트엔드와 백엔드 간 통신을 원활하게 처리하고, WebSocket 연결까지 안정적으로 구성하는 방법을 설명합니다.

---

## Nginx 설정 파일 구조

Nginx의 기본 설정 파일인 `nginx.conf`는 일반적으로 다음과 같은 구조를 가집니다:

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    sendfile on;
    keepalive_timeout 65;

    include /etc/nginx/conf.d/*.conf;
}
```

---

## 주요 지시어 설명

### 1. 전역 설정

- **`user nginx;`**: Nginx 프로세스가 사용할 시스템 사용자 계정을 지정합니다. 일반적으로 `nginx` 또는 `www-data`를 사용합니다.

- **`worker_processes auto;`**: Nginx가 사용할 워커 프로세스의 수를 설정합니다. `auto`로 설정하면, Nginx는 자동으로 CPU 코어 수에 맞게 워커 프로세스 수를 조정합니다.

- **`error_log /var/log/nginx/error.log;`**: 에러 로그 파일의 위치와 이름을 지정합니다.

- **`pid /run/nginx.pid;`**: Nginx의 프로세스 ID(PID)를 저장할 파일의 위치를 지정합니다.

### 2. `events` 블록

- **`worker_connections 1024;`**: 각 워커 프로세스가 동시에 처리할 수 있는 최대 연결 수를 설정합니다.

### 3. `http` 블록

- **`include /etc/nginx/mime.types;`**: 파일 확장자와 MIME 타입의 매핑을 정의한 파일을 포함합니다. 이를 통해 Nginx는 다양한 파일 형식을 올바르게 처리할 수 있습니다.

- **`default_type application/octet-stream;`**: MIME 타입이 정의되지 않은 파일의 기본 MIME 타입을 설정합니다.

- **`log_format main ...;`**: 로그 형식을 정의합니다. 여기서는 `main`이라는 이름의 로그 형식을 설정하며, 로그에 포함될 정보를 지정합니다.

- **`access_log /var/log/nginx/access.log main;`**: 접근 로그 파일의 위치와 사용할 로그 형식을 지정합니다.

- **`sendfile on;`**: `sendfile` 기능을 활성화하여 파일 전송 성능을 향상시킵니다.

- **`keepalive_timeout 65;`**: 클라이언트와의 keep-alive 연결을 유지할 시간을 초 단위로 설정합니다.

- **`include /etc/nginx/conf.d/*.conf;`**: 추가적인 설정 파일을 포함합니다. 이를 통해 서버별 또는 기능별로 설정을 분리하여 관리할 수 있습니다.

---

## 리버스 프록시 설정

Nginx를 리버스 프록시로 설정하면, 클라이언트의 요청을 백엔드 서버로 전달하고 그 응답을 다시 클라이언트에게 반환하는 역할을 수행합니다.

### 기본 리버스 프록시 설정 예시

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend_server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

- **`proxy_pass http://backend_server;`**: 모든 요청을 `backend_server`로 전달합니다. `backend_server`는 IP 주소나 도메인으로 지정할 수 있습니다.

- **`proxy_set_header` 지시어들**: 클라이언트의 원본 정보를 백엔드 서버에 전달하기 위해 요청 헤더를 설정합니다.

### 고급 리버스 프록시 설정

리버스 프록시를 설정할 때, 추가적인 지시어를 활용하여 성능과 보안을 향상시킬 수 있습니다.

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend_server;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_buffering on;
        proxy_buffers 16 4k;
        proxy_buffer_size 2k;
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
        proxy_send_timeout 90;
    }
}
```

- **`proxy_buffering on;`**: 프록시된 서버의 응답을 버퍼링하여 클라이언트로 전송하기 전에 전체 응답을 수신합니다. 이는 느린 클라이언트로 인해 백엔드 서버의 리소스가 낭비되는 것을 방지합니다.

- **`proxy_buffers 16 4k;`**: 프록시된 서버의 응답을 저장할 버퍼의 수와 크기를 설정합니다.

- **`proxy_buffer_size 2k;`**: 응답의 첫 번째 부분(일반적으로 헤더)을 저장할 버퍼의 크기를 설정합니다.

- **`proxy_read_timeout 90;`**, **`proxy_connect_timeout 90;`**, **`proxy_send_timeout 90;`**: 각각 프록시 읽기, 연결, 전송 시간 초과를 설정합니다.

---

---

## 설정 예시

## ✅ 설정 항목 요약 정리표

| 항목                                     | 설명                                          |
| ---------------------------------------- | --------------------------------------------- |
| `listen 80;`                             | HTTP 요청을 수신할 포트 (기본 80)             |
| `server_name localhost;`                 | 요청 대상 도메인 설정                         |
| `location /`                             | 기본 정적 파일 요청 처리 경로 (SPA 대응 포함) |
| `location /api/`                         | API 요청을 백엔드 서버로 프록시 처리          |
| `proxy_pass`                             | 백엔드 서버 주소로 요청 전달                  |
| `proxy_http_version 1.1`                 | WebSocket 지원을 위한 HTTP 1.1 사용           |
| `proxy_set_header Upgrade $http_upgrade` | WebSocket 연결 업그레이드 헤더 전달           |
| `proxy_set_header Connection "upgrade"`  | 연결을 업그레이드 상태로 유지                 |
| `location /ws/`                          | WebSocket 전용 프록시 라우팅 설정             |

---

## ✅ 기본 프록시 설정 예시 (API 서버)

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://mes-demo-api-mes:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🔄 WebSocket 프록시 설정 예시

WebSocket 연결을 위한 별도의 경로 설정:

```nginx
location /ws/ {
    proxy_pass http://mes-demo-api-mes:5000/ws/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

---

## 📌 클라이언트 연결 코드 예시

```js
const socket = new WebSocket("ws://yourdomain.com/ws/");
```

---

## 📎 구성 흐름도 (텍스트 기반)

```
[브라우저] → [Nginx 80포트]
   ├─ /           → 정적 파일 서빙 (SPA)
   ├─ /api/       → 백엔드 API 프록시 (HTTP)
   └─ /ws/        → WebSocket 프록시 (WS)
```
