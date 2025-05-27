# Nginx 성능 향상을 위한 설정 예시 가이드 (Static + Proxy)

## ✅ 개요

Nginx는 고성능 웹 서버이자 reverse proxy로서 널리 사용됩니다. 이 문서는 Vue/React 같은 SPA 및 API 백엔드를 처리하는 Nginx의 성능을 극대화하기 위한 실제 운영 환경 기반의 설정 및 튜닝 항목들을 다룹니다.

---

## 1. 기본 구조 및 설정 예시

```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server_tokens off;

    gzip on;
    gzip_min_length 1024;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # 캐시 제어를 위한 map
    map $uri $cache_control {
        default                             "public, max-age=31536000, immutable";
        ~^/index\.html$                     "no-cache";
    }

    server {
        listen 80;
        server_name example.com;
        root /var/www/html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        location = /index.html {
            add_header Cache-Control "no-cache";
        }

        location ~* \.(js|css|woff2?|ttf|eot|otf|ico|jpg|jpeg|png|svg|gif|webp)$ {
            add_header Cache-Control $cache_control;
            access_log off;
        }

        # API 프록시
        location /api/ {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_buffering on;
            proxy_buffers 16 4k;
            proxy_busy_buffers_size 8k;
            proxy_read_timeout 30s;
        }
    }
}
```

---

## 2. 성능 향상을 위한 주요 튜닝 항목

| 항목                                    | 설명                          | 목적                                 |
| --------------------------------------- | ----------------------------- | ------------------------------------ |
| `worker_processes auto`                 | CPU 수에 따라 자동 설정       | 병렬 처리 최적화                     |
| `sendfile`, `tcp_nopush`, `tcp_nodelay` | 커널 버퍼 활용 및 지연 최소화 | 정적 파일 전송 성능 향상             |
| `gzip`                                  | 압축 사용 설정                | 전송 데이터 크기 축소 및 대역폭 절약 |
| `Cache-Control` 헤더                    | `immutable` + 장기 캐싱       | 재요청 최소화 및 빠른 로딩           |
| `proxy_buffering`, `proxy_buffers`      | API 응답 프록싱 성능 개선     | 백엔드 부하 감소 및 응답 속도 개선   |
| `proxy_read_timeout`                    | 응답 대기 시간 증가           | 느린 API 처리 대응                   |
| `access_log off`                        | 정적 파일 로그 제거           | 디스크 I/O 감소                      |
| `server_tokens off`                     | Nginx 버전 숨김               | 보안 및 응답 바이트 최적화           |

---

## 3. 고급 성능 최적화 기법

### 3.1. HTTP/2 및 HTTP/3

- HTTP/2: 다중 요청을 하나의 TCP 연결로 처리, 헤더 압축 등 성능 이점
- HTTP/3(QUIC): UDP 기반 전송, 지연 시간 최소화 (Nginx 1.25 이상 + quiche 필요)

```nginx
listen 443 ssl http2;
```

---

### 3.2. Brotli 압축

- gzip보다 더 높은 압축률 제공
- 별도 모듈 설치 필요 (ngx_brotli)

```nginx
brotli on;
brotli_types text/plain text/css application/javascript application/json;
```

---

### 3.3. 정적 파일 디스크 캐시 활용

- OS 레벨 캐시를 적극 활용하기 위해 파일 접근 권한 및 inode 캐싱 설정 확인

---

### 3.4. CDN 연동

- Cloudflare, CloudFront 등과 연동하여 글로벌 전파 및 캐시 활용

---

## 4. 보안 및 기타 고려 사항

| 항목                                | 설명                                         |
| ----------------------------------- | -------------------------------------------- |
| `ssl_session_cache shared:SSL:10m;` | SSL 세션 재사용으로 TLS 핸드쉐이크 비용 감소 |
| `limit_conn`, `limit_req`           | 요청 수 제한을 통한 DoS 방어                 |
| `client_max_body_size`              | 업로드 제한 설정 (기본 1MB)                  |
| `error_log` 수준 조절               | 디버그용이 아닌 운영 수준의 로그 설정 필요   |

---

## 5. 배포 전 테스트 명령어

```bash
nginx -t             # 설정 문법 확인
nginx -s reload      # 설정 적용
systemctl restart nginx  # 시스템 재시작 (Linux)
```

---

## 🔚 마치며

이 문서는 Vue/React 기반 SPA 또는 정적 페이지 및 백엔드 API 프록시를 구성할 때 Nginx의 성능을 극대화하기 위한 실전 최적화 항목들을 정리한 것입니다. 운영 환경에서는 실제 트래픽, 리소스 사용량 등을 고려하여 각 항목을 미세 조정하는 것이 중요합니다.

필요하다면 설정 자동화, 서비스 감시, 헬스체크 등을 포함한 고가용성 구성을 병행해보는 것도 고려해볼 수 있습니다.
