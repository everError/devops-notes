# Windows Server Docker HNS 버그 해결 사례

## 문제 상황

**환경:** Windows Server 2022/2025 + Docker

**증상:**

- `docker compose up` 시 3번째 컨테이너부터 "Starting"에서 멈춤
- HNS 프로세스 CPU 20-30% 점유
- 모든 docker 명령어 무응답
- 서비스 재시작 불가, 재부팅만이 해결책

**원인:**

- Windows Server 2022/2025의 HNS(Host Network Service) 버그
- `ports`로 포트를 노출하는 컨테이너가 3개 이상 동시 시작 시 발생
- Windows Server 2019에서는 문제 없음

## 해결 방법: Gateway 패턴

### 기존 구조 (문제 발생)

```
[외부]
   ├── :80, :443  → web-prod (ports)
   └── :7008      → web-dev  (ports)

ports 사용 컨테이너: 2개 → HNS 버그 위험
```

### 개선된 구조 (해결)

```
[외부]
   │
   └── :80, :443, :7008 → gateway (ports) ─┬→ web-prod (expose)
                                           └→ web-dev  (expose)

ports 사용 컨테이너: 1개 → HNS 버그 위험 최소화
```

## 구현

### 1. Gateway 서비스 추가

```yaml
# gateway/docker-compose.yml
networks:
  prod:
    external: true
    name: prod
  dev:
    external: true
    name: dev

services:
  gateway:
    container_name: gateway
    image: caddy:2-windowsservercore-ltsc2022
    restart: always
    ports:
      - "80:80"
      - "443:443"
      - "7008:7008"
    volumes:
      - ./config:C:/etc/caddy
      - D:\certs:C:/certs
    networks:
      - prod
      - dev
```

### 2. Gateway 설정 (Caddyfile)

```caddyfile
# config/Caddyfile
:443 {
    tls C:/certs/cert.pem C:/certs/key.pem
    reverse_proxy backend-prod:443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}

:80 {
    reverse_proxy backend-prod:80
}

:7008 {
    reverse_proxy backend-dev:80
}
```

### 3. 기존 서비스에서 ports 제거

```yaml
# prod/docker-compose.yml
services:
  web:
    expose:
      - "80"
      - "443"
    # ports: 삭제!
```

```yaml
# dev/docker-compose.yml
services:
  web:
    expose:
      - "80"
      - "443"
    # ports: 삭제!
```

### 4. 시작 순서

```powershell
# 1. 백엔드 먼저 (네트워크 생성됨)
cd C:\app\prod
docker compose up -d

cd C:\app\dev
docker compose up -d

# 2. Gateway 마지막
cd C:\app\gateway
docker compose up -d
```

## 주의사항

### Windows 볼륨 마운트

파일 단독 마운트 불가:

```yaml
# ❌ 안 됨
volumes:
  - ./Caddyfile:C:/etc/caddy/Caddyfile

# ✅ 폴더로 마운트
volumes:
  - ./config:C:/etc/caddy
```

### 네트워크 연결

Gateway가 여러 네트워크의 컨테이너에 접근하려면 해당 네트워크에 모두 연결되어야 함:

```yaml
networks:
  - prod
  - dev
```

## 결과

| 항목                | 변경 전  | 변경 후  |
| ------------------- | -------- | -------- |
| ports 사용 컨테이너 | 2개 이상 | **1개**  |
| HNS 동시 처리       | 분산     | **집중** |
| HNS 버그 위험       | 높음     | **낮음** |

## 추가 예방책

```powershell
# 주간 재부팅 스케줄
schtasks /create /tn "WeeklyReboot" /tr "shutdown /r /f /t 0" /sc weekly /d SUN /st 03:00

# 주기적 정리
docker system prune -f
```
