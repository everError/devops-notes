# 프로젝트 기술 이슈 및 해결 방법 정리

## 1. Windows Docker 컨테이너 이미지 크기 최적화

### 문제
- Windows Server Core 기반 이미지가 약 4GB로 매우 큼
- Nano Server 사용 시 Nginx 실행 불가 (32비트/64비트 호환성 문제)

### 시도한 방법들

**1) Nano Server + 공식 Nginx**
- 결과: 실패 (exit code 3221225781)
- 원인: 공식 Nginx는 32비트 바이너리 포함, Nano Server는 64비트만 지원

**2) Server Core 사용**
- 결과: 정상 작동하지만 이미지 크기 4GB+
- 용도: 안정성이 중요한 경우 적합

**3) Caddy로 전환 (최종 선택)**
- Caddy는 Go로 작성된 64비트 네이티브 바이너리
- Nano Server에서 정상 작동
- 최종 이미지 크기: 약 300MB (Server Core 대비 93% 감소)

### 해결책

```dockerfile
# Stage 1: Build (Windows Server Core)
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS build
# ...

# Stage 2: Caddy 다운로드
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS caddy-download
RUN Invoke-WebRequest -Uri 'https://github.com/caddyserver/caddy/releases/download/v2.8.4/caddy_2.8.4_windows_amd64.zip' -OutFile caddy.zip; \
    Expand-Archive caddy.zip -DestinationPath C:\caddy

# Stage 3: Nano Server로 최종 이미지
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022
WORKDIR /app
COPY --from=caddy-download /caddy/caddy.exe /app/
COPY --from=build /app/dist /app/html
CMD ["C:\\app\\caddy.exe", "run", "--config", "C:\\app\\config\\Caddyfile"]
```

**주요 포인트:**
- Nginx → Caddy 전환으로 Nano Server 사용 가능