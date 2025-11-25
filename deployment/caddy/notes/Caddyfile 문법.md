# Caddyfile 문법 가이드

## 1. 기본 구조

```caddyfile
# 전역 옵션 블록 (선택사항)
{
    # 전역 설정
    admin off
    email admin@example.com
}

# 사이트 블록
주소 {
    # 디렉티브들
}
```

## 2. 주소(Address) 지정

```caddyfile
# 포트만
:80
:8080

# 로컬호스트
localhost
localhost:8080

# 도메인 (자동 HTTPS)
example.com
*.example.com

# 여러 도메인
example.com, www.example.com {
    # 설정
}

# 경로 포함
example.com/blog
```

## 3. 주요 디렉티브

### 정적 파일 서빙

```caddyfile
# 기본
example.com {
    root * /var/www/html
    file_server
}

# 디렉토리 브라우징
example.com {
    root * /var/www
    file_server browse
}

# SPA (Single Page Application)
example.com {
    root * /var/www/app
    try_files {path} /index.html
    file_server
}
```

### 리버스 프록시

```caddyfile
# 기본
example.com {
    reverse_proxy localhost:8080
}

# 여러 백엔드 (로드밸런싱)
example.com {
    reverse_proxy backend1:8080 backend2:8080 backend3:8080
}

# 헤더 설정
example.com {
    reverse_proxy backend:8080 {
        header_up Host {upstream_hostport}
        header_up X-Real-IP {remote_host}
    }
}
```

### 경로별 처리 (handle)

```caddyfile
example.com {
    # 순서대로 매칭
    handle /api/* {
        reverse_proxy backend:8080
    }
    
    handle /static/* {
        root * /var/www
        file_server
    }
    
    # 나머지 모든 요청
    handle {
        root * /var/www/app
        file_server
    }
}
```

### 리다이렉트

```caddyfile
# 기본 리다이렉트
example.com {
    redir https://newsite.com
}

# 특정 경로
example.com {
    redir /old /new 301
}

# www 제거
www.example.com {
    redir https://example.com{uri} permanent
}
```

### 헤더 설정

```caddyfile
example.com {
    header {
        # 추가
        X-Custom-Header "value"
        
        # 삭제
        -Server
        -X-Powered-By
        
        # 보안 헤더
        Strict-Transport-Security "max-age=31536000;"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
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

### 요청/응답 수정

```caddyfile
example.com {
    # 요청 크기 제한
    request_body {
        max_size 10MB
    }
    
    # 간단한 응답
    respond "Hello, World!" 200
    respond /health "OK" 200
}
```

## 4. Matcher (조건부 처리)

### Named Matcher

```caddyfile
example.com {
    # matcher 정의
    @api {
        path /api/*
    }
    
    @static {
        path *.css *.js *.png
    }
    
    @admin {
        path /admin/*
        remote_ip 192.168.1.0/24
    }
    
    # matcher 사용
    reverse_proxy @api backend:8080
    header @static Cache-Control "max-age=31536000"
    handle @admin {
        basicauth {
            admin $2a$14$...
        }
    }
}
```

### Inline Matcher

```caddyfile
example.com {
    # path matcher
    reverse_proxy /api/* backend:8080
    
    # method matcher
    @post method POST
    handle @post {
        # POST 요청만 처리
    }
}
```

### 다양한 Matcher 타입

```caddyfile
example.com {
    @example {
        # 경로
        path /admin/* /api/*
        
        # HTTP 메서드
        method GET POST
        
        # 헤더
        header User-Agent *Mobile*
        
        # 쿼리 파라미터
        query debug=true
        
        # IP 주소
        remote_ip 192.168.1.0/24
        
        # 호스트
        host api.example.com
    }
}
```

## 5. 변수와 플레이스홀더

```caddyfile
example.com {
    # 요청 정보
    respond "Path: {path}"
    respond "Host: {host}"
    respond "Method: {method}"
    respond "IP: {remote_host}"
    
    # 헤더에서 사용
    reverse_proxy backend:8080 {
        header_up X-Original-URL {scheme}://{host}{uri}
    }
}
```

### 환경 변수

```caddyfile
# 환경 변수 사용
{$DOMAIN:localhost} {
    reverse_proxy {$BACKEND:localhost:8080}
}
```

```bash
# 실행
export DOMAIN=example.com
export BACKEND=backend:8080
caddy run
```

## 6. 전역 옵션

```caddyfile
{
    # 관리자 API
    admin off                    # API 비활성화
    admin 127.0.0.1:2019        # API 주소 지정
    
    # 이메일 (Let's Encrypt)
    email admin@example.com
    
    # 로그
    log {
        output file /var/log/caddy/access.log
        format json
    }
    
    # 서버 설정
    servers {
        timeouts {
            read_body 10s
            write 30s
        }
    }
}
```

## 7. 실전 예제

### 기본 웹사이트

```caddyfile
example.com {
    encode gzip
    root * /var/www/html
    file_server
}
```

### SPA + API

```caddyfile
example.com {
    # API
    handle /api/* {
        reverse_proxy backend:8080
    }
    
    # SPA
    handle {
        root * /var/www/app
        try_files {path} /index.html
        file_server
    }
}
```

### 다중 서비스

```caddyfile
# 메인 사이트
example.com {
    root * /var/www/main
    file_server
}

# API 서버
api.example.com {
    reverse_proxy backend:8080
}

# 관리자
admin.example.com {
    basicauth {
        admin $2a$14$...
    }
    reverse_proxy admin:3000
}
```

### 마이크로서비스

```caddyfile
api.example.com {
    # 인증
    handle /auth/* {
        reverse_proxy auth-service:8081
    }
    
    # 사용자
    handle /users/* {
        reverse_proxy user-service:8082
    }
    
    # 주문
    handle /orders/* {
        reverse_proxy order-service:8083
    }
    
    # WebSocket
    handle /ws {
        reverse_proxy notification-service:8084
    }
}
```

### 정적 + 동적 + 캐싱

```caddyfile
example.com {
    # 정적 파일 (장기 캐싱)
    @static path *.css *.js *.jpg *.png
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
    
    # HTML (짧은 캐싱)
    handle {
        header Cache-Control "public, max-age=300"
        root * /var/www/html
        file_server
    }
}
```

## 8. 주요 문법 규칙

### 순서
- **전역 블록** → **사이트 블록** → **디렉티브**
- `handle` 블록은 위에서 아래로 순차 평가
- 일반 디렉티브는 Caddy가 내부적으로 최적 순서로 재배열

### 주석
```caddyfile
# 한 줄 주석
example.com {
    # 디렉티브 주석
    file_server  # 인라인 주석
}
```

### 중괄호
```caddyfile
# 한 줄
example.com { respond "OK" }

# 여러 줄
example.com {
    respond "OK"
}

# 중첩
example.com {
    handle /api/* {
        reverse_proxy backend:8080 {
            header_up Host {host}
        }
    }
}
```

### 대소문자
- 디렉티브: 소문자
- 도메인: 대소문자 구분 없음
- 경로: 대소문자 구분

## 9. 디버깅

```bash
# 설정 검증
caddy validate --config Caddyfile

# 포맷팅
caddy fmt Caddyfile --overwrite

# JSON으로 변환 (내부 처리 확인)
caddy adapt --config Caddyfile

# 디버그 모드 실행
caddy run --watch --debug
```

## 10. 자주 사용하는 패턴

```caddyfile
# HTTPS 강제 (자동)
example.com {
    # 자동으로 HTTP → HTTPS 리다이렉트
}

# www 제거
www.example.com {
    redir https://example.com{uri}
}

# 404 페이지
example.com {
    handle_errors {
        @404 expression {http.error.status_code} == 404
        rewrite @404 /404.html
        file_server
    }
}

# CORS
example.com {
    header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Access-Control-Allow-Headers *
    }
}

# 타임아웃 설정
example.com {
    reverse_proxy backend:8080 {
        transport http {
            dial_timeout 30s
            response_header_timeout 60s
        }
    }
}
```