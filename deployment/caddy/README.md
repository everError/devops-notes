네, 다시 정리하겠습니다. 숫자 비교는 빼고 개념과 특징, 예제 중심으로 작성하겠습니다.

---

# Caddy 완벽 가이드

## 1. Caddy란?

### 핵심 정의
Caddy는 Go로 작성된 강력하고 확장 가능한 플랫폼으로, 사이트, 서비스, 앱을 제공합니다. 대부분의 사람들은 Caddy를 웹서버나 프록시로 사용하지만, 핵심적으로 Caddy는 서버들의 서버입니다.

### 탄생과 발전
Caddy 프로젝트의 첫 git 커밋은 2014년이었습니다. Caddy 버전 1.0은 2019년 4월 24일에 릴리스되었으며, 당시 250명 이상의 기여자가 있었습니다. Caddy 버전 2는 2020년 5월 5일에 릴리스되었습니다.

### 설계 철학
설정은 Caddy의 API를 통해 동적이고 내보내기 가능합니다. 설정 파일이 필수는 아니지만 여전히 사용할 수 있으며, 대부분의 사람들이 선호하는 설정 방법은 Caddyfile입니다.

```caddyfile
# 가장 간단한 웹서버
localhost

respond "Hello, World!"
```

## 2. 핵심 기능

### 자동 HTTPS

**작동 원리:**
기본적으로 TLS는 비어있지 않은 호스트 matcher가 있는 모든 라우트에 자동으로 사용됩니다. 이는 Caddy가 서빙하는 사이트 이름이나 IP 주소로 가정되므로, Caddy는 설정된 호스트네임과 IP 주소에 대한 인증서를 자동으로 발급하고 갱신합니다.

자동 HTTPS가 활성화되면 Caddy는 HTTP 요청을 동등한 HTTPS 위치로 리다이렉트합니다. TLS 인증서를 자동으로 획득하기 위해 Caddy는 ACME(Automatic Certificate Management Environment) 프로토콜을 구현하여 Let's Encrypt 같은 서비스와 통신합니다.

```caddyfile
# 도메인만 입력하면 자동으로 HTTPS 활성화
example.com {
    root * /var/www/html
    file_server
}
# 자동으로 수행되는 작업:
# 1. Let's Encrypt에서 인증서 발급
# 2. HTTP → HTTPS 자동 리다이렉트
# 3. 만료 전 자동 갱신
```

**로컬 개발 환경:**
Caddy는 localhost와 내부 IP조차도 완전 자동화된 자체 관리 CA의 중간 인증서를 사용하여 TLS로 제공하며, 이는 대부분의 로컬 신뢰 저장소에 자동으로 설치됩니다.

```caddyfile
# 로컬 개발 - 자동으로 로컬 CA 인증서 사용
localhost {
    reverse_proxy /api/* backend:8080
}
```

### 플랫폼 독립성
Caddy는 모든 주요 플랫폼에서 컴파일되며 런타임 의존성이 없습니다.

Caddy는 정적으로 컴파일됩니다. 일반적으로 Caddy 바이너리는 외부 라이브러리를 필요로 하지 않으며 libc조차 필요하지 않습니다.

```bash
# 단일 바이너리로 실행
./caddy run

# 어디든 배포 가능 (의존성 없음)
scp caddy user@server:/usr/local/bin/
```

## 3. 설정 방식

### Caddyfile (권장)

**기본 구조:**
현재 디렉토리에 Caddyfile이라는 파일이 있고 다른 설정이 지정되지 않았다면, Caddy는 Caddyfile을 로드하고 자동으로 변환하여 바로 실행합니다.

```caddyfile
# 기본 정적 파일 서버
example.com {
    root * /var/www/html
    file_server
}

# 리버스 프록시
api.example.com {
    reverse_proxy backend:8080
}

# 여러 도메인 처리
blog.example.com {
    root * /var/www/blog
    encode gzip
    file_server
}
```

**경로별 처리:**
```caddyfile
example.com {
    # 정적 파일
    handle /static/* {
        root * /var/www/static
        file_server
    }
    
    # API 프록시
    handle /api/* {
        reverse_proxy backend:8080
    }
    
    # SPA (Single Page Application)
    handle {
        root * /var/www/app
        try_files {path} /index.html
        file_server
    }
}
```

### JSON 설정

Caddy의 핵심에서 설정은 단순히 JSON 문서입니다.

```json
{
  "apps": {
    "http": {
      "servers": {
        "example": {
          "listen": [":443"],
          "routes": [
            {
              "match": [{
                "host": ["example.com"]
              }],
              "handle": [{
                "handler": "file_server",
                "root": "/var/www/html"
              }]
            }
          ]
        }
      }
    }
  }
}
```

### 설정 변환
JSON이 Caddy의 네이티브 설정 언어이지만, Caddy는 설정 어댑터로부터 입력을 받을 수 있으며, 이는 본질적으로 선택한 모든 설정 형식을 JSON으로 변환할 수 있습니다: Caddyfile, JSON 5, YAML, TOML, NGINX 설정 등이 있습니다.

```bash
# Caddyfile을 JSON으로 변환
caddy adapt --config Caddyfile
```

## 4. 주요 디렉티브

### 정적 파일 서빙

```caddyfile
# 기본 파일 서버
example.com {
    root * /var/www/html
    file_server
}

# 디렉토리 브라우징 활성화
files.example.com {
    root * /var/www/files
    file_server browse
}

# 특정 경로만
example.com {
    handle /downloads/* {
        root * /var/www
        file_server
    }
}
```

### 리버스 프록시

```caddyfile
# 단일 백엔드
example.com {
    reverse_proxy localhost:8080
}

# 로드밸런싱
example.com {
    reverse_proxy backend1:8080 backend2:8080 backend3:8080 {
        lb_policy round_robin
    }
}

# 헤더 추가
example.com {
    reverse_proxy backend:8080 {
        header_up Host {upstream_hostport}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

### 압축

```caddyfile
example.com {
    encode gzip zstd
    file_server
}
```

### 리다이렉트

```caddyfile
# www → non-www
www.example.com {
    redir https://example.com{uri} permanent
}

# 특정 경로
example.com {
    redir /old-page /new-page 301
}
```

### 보안 헤더

```caddyfile
example.com {
    header {
        # HTTPS 강제
        Strict-Transport-Security "max-age=31536000;"
        
        # XSS 보호
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        
        # 서버 정보 숨김
        -Server
        -X-Powered-By
    }
    
    file_server
}
```

## 5. 고급 기능

### Matcher (조건부 처리)

```caddyfile
example.com {
    # 경로 기반
    @api path /api/*
    reverse_proxy @api backend:8080
    
    # 헤더 기반
    @mobile header User-Agent *Mobile*
    respond @mobile "Mobile version"
    
    # 복합 조건
    @admin {
        path /admin/*
        remote_ip 192.168.1.0/24
    }
    handle @admin {
        reverse_proxy admin:3000
    }
}
```

### 템플릿

```caddyfile
example.com {
    root * /var/www
    templates
    file_server
}
```

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<body>
    <h1>Server: {{env "HOSTNAME"}}</h1>
    <p>Path: {{.OriginalReq.URL.Path}}</p>
</body>
</html>
```

### 환경 변수

```caddyfile
{$DOMAIN:localhost} {
    reverse_proxy {$BACKEND_URL:localhost:8080}
}
```

```bash
export DOMAIN=example.com
export BACKEND_URL=backend:8080
caddy run
```

## 6. 보안 기능

### 기본 보안 수준
Caddy의 TLS 기본값은 안전하며 PCI, HIPAA, NIST 준수 요구사항을 통과합니다. 번거로움이 필요 없는 기본값입니다.

```caddyfile
example.com {
    # 기본적으로 안전한 TLS 설정
    # - TLS 1.2, 1.3만 활성화
    # - 강력한 암호화 알고리즘
    # - 완전 순방향 비밀성 (PFS)
    
    file_server
}
```

### 메모리 안전성
대부분의 서버(NGINX, Apache, HAProxy 등)와 그 의존성은 C로 작성되어 Heartbleed 같은 치명적인 메모리 안전성 버그(버퍼 오버플로우 등)에 취약합니다. Caddy 같은 Go 프로그램은 전체 보안 취약점 클래스에 영향을 받지 않습니다.

### 기본 인증

```caddyfile
admin.example.com {
    basicauth {
        admin $2a$14$Zkx19XLiW6VYouLHR5Nmf...
    }
    
    reverse_proxy admin-panel:3000
}
```

## 7. 실전 예제

### SPA 호스팅

```caddyfile
app.example.com {
    root * /var/www/app
    encode gzip
    
    # SPA 라우팅
    try_files {path} /index.html
    file_server
    
    # API 프록시
    reverse_proxy /api/* backend:8080
}
```

### 마이크로서비스

```caddyfile
api.example.com {
    # 사용자 서비스
    handle /users/* {
        reverse_proxy users-service:8081
    }
    
    # 주문 서비스
    handle /orders/* {
        reverse_proxy orders-service:8082
    }
    
    # 인증 서비스
    handle /auth/* {
        reverse_proxy auth-service:8083
    }
    
    # WebSocket
    handle /ws {
        reverse_proxy notifications:8084
    }
}
```

### 정적 + 동적 콘텐츠

```caddyfile
example.com {
    # 정적 에셋 (캐싱)
    @static path *.css *.js *.jpg *.png *.svg
    handle @static {
        header Cache-Control "public, max-age=31536000"
        root * /var/www/static
        file_server
    }
    
    # API (캐싱 없음)
    handle /api/* {
        header Cache-Control "no-store"
        reverse_proxy backend:8080
    }
    
    # 메인 애플리케이션
    handle {
        root * /var/www/app
        try_files {path} /index.html
        file_server
    }
}
```

## 8. 클러스터링

### 여러 인스턴스 조정
간단히 여러 Caddy 인스턴스를 동일한 스토리지로 구성하면 플릿으로 자동으로 인증서 관리를 조정하고 키와 OCSP staple 같은 리소스를 공유합니다!

```caddyfile
{
    # 공유 스토리지 설정
    storage file_system {
        root /shared/caddy
    }
}

example.com {
    # 모든 인스턴스가 같은 인증서 사용
    file_server
}
```

## 9. 플러그인 시스템

### 모듈 구조
공식 Caddy 배포판은 수십 개의 표준 모듈과 함께 제공됩니다. 다른 것들은 프로젝트 웹사이트, xcaddy 명령줄 도구 사용, 또는 수동으로 커스텀 빌드를 컴파일하여 추가할 수 있습니다.

```bash
# xcaddy로 커스텀 빌드
xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4

# 플러그인이 포함된 Caddy 바이너리 생성
```

## 10. 명령어

### 기본 명령어

```bash
# 포그라운드 실행
caddy run

# 백그라운드 실행
caddy start

# 중지
caddy stop

# 설정 검증
caddy validate --config Caddyfile

# 설정 포맷팅
caddy fmt Caddyfile --overwrite

# 무중단 리로드
caddy reload

# 즉시 파일 서버 (테스트용)
caddy file-server --listen :8080
```

### API 사용

```bash
# 현재 설정 조회
curl http://localhost:2019/config/

# 설정 리로드
curl -X POST http://localhost:2019/load \
  -H "Content-Type: text/caddyfile" \
  --data-binary @Caddyfile
```

## 11. Docker에서 Caddy

### 기본 사용

```dockerfile
FROM caddy:2.8-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY site /usr/share/caddy
```

### Docker Compose

```yaml
version: '3.8'

services:
  caddy:
    image: caddy:2.8-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./site:/usr/share/caddy
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

## 12. Caddy vs Nginx 비교

### 설정 복잡도

**Nginx의 복잡성:**
Nginx는 초보자에게 더 가파른 학습 곡선을 요구하는 더 복잡한 설정 언어를 사용합니다.

**Caddy의 간결함:**
Caddy는 Caddyfile에서 영감을 받은 간단하고 사람이 읽을 수 있는 설정 형식을 사용하여 사용자가 이해하고 수정하기 쉽게 만듭니다.

```caddyfile
# Caddy - 3줄
example.com {
    reverse_proxy backend:8080
}
```

```nginx
# Nginx - 15줄 이상
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 사용 사례별 추천

**Caddy가 적합:**
- 빠른 프로토타이핑과 배포
- 소규모~중규모 트래픽
- 자동 HTTPS가 필수인 경우
- 설정 단순화가 우선인 경우
- 개발 환경

**Nginx가 적합:**
- 극한의 성능 최적화 필요
- 매우 높은 트래픽 처리
- 복잡한 레거시 시스템
- 리소스 효율이 매우 중요

## 결론

**Caddy의 핵심 가치:**
- **단순함**: 설정이 직관적
- **자동화**: HTTPS 인증서 관리 불필요
- **보안**: 안전한 기본값
- **현대적**: HTTP/3, 클러스터링 기본 지원

**선택 기준:**
- 빠른 시작이 필요하다면 → Caddy
- 극한 최적화가 필요하다면 → Nginx
- 자동 HTTPS가 필수라면 → Caddy
- 기존 Nginx 자산이 많다면 → Nginx 유지

Caddy는 웹을 제공하는 방식을 바꿀 수 있는 현대적인 웹서버입니다.