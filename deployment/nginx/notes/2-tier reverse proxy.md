# 2-tier Reverse Proxy 패턴 — 호스트 nginx + 컨테이너 nginx

호스트에 이미 떠있는 **공용 nginx 가 TLS 종료 + 도메인 라우팅** 을 담당하고, 각 앱은 **컨테이너 안의 자체 nginx 로 정적 파일 + API 프록시** 를 처리하는 2단 구조.

---

## 🎯 언제 쓰나

- 한 호스트에 **여러 앱 (`/srv/app1`, `/srv/app2`...) 이 동거**
- 각 앱이 자기만의 frontend dist 와 backend API 를 가짐
- TLS 인증서는 호스트 한 곳에 통합 (Let's Encrypt 자동 갱신 등)
- 앱마다 별도 도메인 또는 별도 포트로 노출

→ **호스트 nginx = SSL gateway + 라우팅**, **컨테이너 nginx = 앱별 정적/프록시**.

---

## 1. 트래픽 흐름

```
Browser
  ↓ https://app1.example.com (443)
[host-nginx]                    ← TLS 종료, vhost 분기
  │  app1.example.com  → app1-web:80
  │  app2.example.com  → app2-web:80
  ↓ http (같은 docker network)
[app1-web (컨테이너 nginx)]
  ├─ /            → 정적 파일 (Vue/React dist)
  ├─ /api/std/    → app1-bff-standard:8080
  ├─ /api/common/ → app1-bff-common:8080
  └─ /ws/         → app1-bff-common:8080 (WebSocket)
                       ↓ 내부 docker network
                  [app1-bff-* / app1-grpc-*]
                       ↓
                  [공용 DB / 공용 Redis]
```

---

## 2. 왜 2단으로?

### 1단으로 다 처리하면?

| 문제 | 설명 |
|---|---|
| 호스트 nginx 가 모든 앱의 디테일 알아야 함 | `/api/v1/users` → app1, `/api/v2/orders` → app2... 라우팅 점점 복잡 |
| 정적 파일 경로 매핑 | 호스트 nginx 가 각 앱의 dist 를 직접 마운트해서 root 로 줘야 함 |
| 앱 추가 시 호스트 nginx 도 같이 수정 | 변경 범위 큼 |

### 2단의 장점

| 장점 | 설명 |
|---|---|
| 호스트 nginx 는 **TLS + vhost 분기** 만 책임 | 단순. 도메인/포트만 보면 끝 |
| 앱별 라우팅은 **컨테이너 nginx 안에서** | 앱이 자기 도메인 안의 모든 룰을 캡슐화 |
| 앱 추가 시 호스트 nginx 는 **vhost 한 블록만** 추가 | 앱끼리 충돌 X |
| 컨테이너 nginx 는 **이미지에 빌드 됨** → CI 가 자동 배포 | 운영 부담 ↓ |

---

## 3. 호스트 nginx vhost 예시

각 앱마다 vhost 한 블록.

### 도메인 분기 방식

```nginx
# /etc/nginx/conf.d/app1.conf
server {
    listen 80;
    server_name app1.example.com;
    return 301 https://$host$request_uri;
}

server {
    charset utf-8;
    listen 443 ssl;
    server_name app1.example.com;

    client_max_body_size 0;

    ssl_certificate     /etc/letsencrypt/live/app1.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/app1.example.com/privkey.pem;

    # Let's Encrypt 갱신 통과
    location ~ /\.well-known/acme-challenge/ {
        allow all;
        root /var/www/letsencrypt;
    }

    location / {
        proxy_pass http://app1-web:80;            # 컨테이너명으로 직접
        proxy_http_version 1.1;
        proxy_set_header Upgrade           $http_upgrade;   # WebSocket
        proxy_set_header Connection        "upgrade";
        proxy_set_header Host              $http_host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Ssl   on;

        proxy_read_timeout 3600s;          # WebSocket 길게
        proxy_request_buffering off;
    }
}
```

### 포트 분기 방식 (도메인 하나에 포트별 앱)

도메인이 부족하거나 내부 환경일 때:

```nginx
# /etc/nginx/conf.d/app1.conf
server {
    listen 9080 ssl;
    server_name dev.example.com;
    
    ssl_certificate     /etc/letsencrypt/live/dev.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dev.example.com/privkey.pem;
    
    location / {
        proxy_pass http://app1-web:80;
        # ... (위와 동일)
    }
}
```

→ `https://dev.example.com:9080/` 으로 접근.

⚠️ 호스트 nginx 가 그 포트도 listen 해야 하니, nginx 컨테이너의 `ports:` 에 포트 매핑 추가:

```yaml
# /srv/host-nginx/docker-compose.yml
services:
  app-nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
      - "9080:9080"      # ← 추가
```

---

## 4. 컨테이너 nginx 예시 (앱 안)

```nginx
# /etc/nginx/conf.d/default.conf  (컨테이너 안)

upstream bff_standard { server bff-standard:8080; }
upstream bff_common   { server bff-common:8080; }

server {
    listen 80;
    server_name _;

    # ── 정적 파일 (SPA) ─────────────────────────
    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files $uri $uri/ /index.html;     # SPA fallback
    }

    # ── BFF API 프록시 ──────────────────────────
    location /api/std {
        proxy_pass         http://bff_standard;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    location /api/common {
        proxy_pass         http://bff_common;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }

    # ── WebSocket ───────────────────────────────
    location /ws {
        proxy_pass         http://bff_common;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade           $http_upgrade;
        proxy_set_header   Connection        "upgrade";
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_read_timeout 3600s;
    }

    # ── 헬스체크 ────────────────────────────────
    location = /healthz {
        access_log off;
        return 200 "ok\n";
    }
}
```

이 conf 는 **앱 이미지에 빌드** 되어 컨테이너에 들어감 (CI 가 빌드 시 COPY).

---

## 5. Docker Network 연결 — 핵심

호스트 nginx 컨테이너가 앱 컨테이너에 닿으려면 **같은 docker network** 에 있어야 한다.

### 패턴 — 호스트 nginx 가 미리 만든 edge network 에 앱이 합류

```yaml
# /srv/host-nginx/docker-compose.yml (이미 떠있음)
services:
  app-nginx:
    image: nginx:alpine
    networks:
      - app-edge
    ports: ["80:80", "443:443"]
networks:
  app-edge:
    name: app-edge      # 명시적 이름
```

```yaml
# /srv/app1/docker-compose.yml (우리 앱)
services:
  app1-web:
    image: app1/web:latest
    networks:
      - internal
      - app-edge        # ← 여기 합류 → 호스트 nginx 가 컨테이너명으로 접근 가능
    expose:
      - "80"

networks:
  internal:
    driver: bridge
  app-edge:
    external: true
```

→ 호스트 nginx 의 conf 에서 `proxy_pass http://app1-web:80` 이 동작.

상세는 [containers/docker/notes/joining external networks.md](../../../containers/docker/notes/joining%20external%20networks.md) 참조.

---

## 6. 호스트 포트는 점유하지 않음 — `expose` 만

앱 web 컨테이너는 호스트 포트를 잡지 않음:

```yaml
services:
  app1-web:
    networks:
      - app-edge
    expose:               # ← 컨테이너 포트만 노출 (network 안에서만 접근)
      - "80"
    # ports:              # ← 사용하지 않음 (호스트 포트 안 잡음)
```

`expose` 는 docker network 내에서만 의미가 있음. 호스트 포트는 호스트 nginx 만 점유.

→ 한 호스트에 앱 여러 개 띄워도 포트 충돌 없음.

---

## 7. WebSocket 헤더 — 잊으면 끊김

WebSocket 이 필요한 location 은 **반드시** 다음 두 줄:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection "upgrade";
```

이게 없으면 nginx 가 `Connection: close` 보내서 핸드셰이크 실패. 일반 HTTP 는 동작하는데 WebSocket 만 안 되면 99% 이거.

호스트 nginx 와 컨테이너 nginx **둘 다** 이 헤더가 있어야 한다 (한 곳만 있으면 다른 단계에서 끊김).

또한:
```nginx
proxy_read_timeout 3600s;
```
→ idle 한 WebSocket 이 1분 후 끊기지 않도록 (기본 60s).

---

## 8. nginx location 매칭 — 꼭 짚어야 할 것

```nginx
location /ws/  { ... }       # /ws/ , /ws/foo 만 매칭. /ws (slash 없이) 는 안 됨
location /ws   { ... }       # /ws , /ws/ , /ws/foo , /ws?token=x 모두 매칭
location = /ws { ... }       # 정확히 /ws 만. /ws/ , /ws?x 도 안 됨
```

### 권장
- prefix location 은 **slash 없이**: `location /api`, `location /ws`
- query string (`?token=...`) 은 path 로 안 보이지만, **slash 위치**가 매칭에 영향
- 클라이언트가 만드는 실제 URL 을 먼저 확인 (브라우저 개발자도구 → Network)

---

## 9. proxy_pass 끝의 slash — 미묘한 차이

```nginx
location /api/ {
    proxy_pass http://backend;       # 클라이언트 path 그대로 → /api/items
}

location /api/ {
    proxy_pass http://backend/;      # location prefix 제거 후 전달 → /items
}
```

대부분 **slash 없이** 하는 게 직관적 (path 그대로 전달). backend 가 `/api/...` 를 받든 `/...` 만 받든 backend 의 라우팅에 맞추기.

---

## 10. 흔한 함정

### 10.1 컨테이너 nginx 의 listen 포트와 expose 불일치

```nginx
server { listen 80; }       # 컨테이너 안에서 80 으로 받음
```

```yaml
expose:
  - "80"                    # ← 일치
```

만약 컨테이너 안에서 `listen 8080` 으로 했으면 `expose: "8080"` 그리고 호스트 nginx 도 `proxy_pass http://app:8080`.

### 10.2 호스트 nginx 가 다른 network 에 있어서 컨테이너 못 찾음

```
nginx: [emerg] host not found in upstream "app1-web"
```

→ 호스트 nginx 컨테이너가 `app-edge` network 에 join 안 됨. compose 확인.

### 10.3 letsencrypt 인증서 갱신 시 acme-challenge 가 컨테이너로 가서 실패

호스트 nginx vhost 마다 acme-challenge location 을 명시적으로 처리:

```nginx
location ~ /\.well-known/acme-challenge/ {
    allow all;
    root /var/www/letsencrypt;
}
```

이게 다른 location (예: `/`) 보다 위에 와야 함 (또는 정확한 priority).

### 10.4 X-Forwarded-* 가 backend 까지 안 감

호스트 nginx 만 헤더 세팅하고 컨테이너 nginx 가 다시 안 보내면 backend 는 모름. 컨테이너 nginx 도:

```nginx
proxy_set_header X-Real-IP         $remote_addr;
proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

`$proxy_add_x_forwarded_for` 는 기존 헤더에 자기 IP 를 append 하는 마법 변수. 그대로 사용 OK.

---

## ✅ 체크리스트

- [ ] 호스트 nginx 와 앱 컨테이너가 같은 docker network (`external: true` 로 합류)
- [ ] 앱 web 컨테이너는 `ports` 안 잡고 `expose` 만
- [ ] 호스트 nginx 의 vhost 가 TLS + 라우팅 담당
- [ ] 컨테이너 nginx 는 정적 파일 + API/WebSocket proxy 담당
- [ ] WebSocket location 에 `Upgrade`/`Connection: upgrade` 헤더 + `proxy_read_timeout`
- [ ] location 의 trailing slash 가 클라이언트 URL 과 매칭되는지 확인
- [ ] `X-Forwarded-*` 헤더 두 단계 모두 전달
- [ ] Let's Encrypt acme-challenge location 명시
