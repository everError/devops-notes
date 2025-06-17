## 🐞 문제 요약: Nginx 실행 시 Ocelot 게이트웨이 응답 지연

### 📌 현상

- Ocelot 게이트웨이 서비스 (`http://localhost:7020`)를 통해 Swagger UI에서 다른 서비스 (`http://localhost:7021`)로 요청을 보냄
- Nginx가 실행 중일 때, **게이트웨이 자체에 직접 접근해도 응답이 느려짐**
- 반면, **Nginx가 꺼져 있으면 응답 속도 정상**

---

## 🔍 원인 분석

### ✅ 1. `localhost` 주소 사용으로 인한 loopback 충돌

- Ocelot이나 Swagger에서 **`localhost`** 주소를 사용 중
- Nginx 또한 `localhost` 기반에서 리버스 프록시 구동 중
- Windows 환경에서는 `localhost`가 `::1`(IPv6), `127.0.0.1`(IPv4)을 **번갈아 시도하거나 충돌 발생**
- Nginx가 실행 중이면 루프백 리소스가 점유되어 병목 발생

### ✅ 2. Ocelot 내부 HttpClient 또는 Swagger 서버가 `localhost` 주소에 의존

- 이로 인해 **Nginx와의 loopback 리소스 충돌**, **불필요한 DNS lookup 반복**, **커넥션 경합** 등이 발생함

---

## ✅ 해결 방법

### 1. 모든 내부 주소를 `localhost` → `127.0.0.1`로 변경

- Ocelot의 `ocelot.json`:

```json
"DownstreamHostAndPorts": [
  { "Host": "127.0.0.1", "Port": 7021 }
]
```

- Swagger 설정 (`servers`):

```json
"servers": [
  { "url": "http://127.0.0.1:7021" }
]
```

### 2. Nginx에서 `worker_processes` 제한 (권장)

```nginx
worker_processes 1;
```

### 3. 필요한 경우 Kestrel도 명시적으로 `127.0.0.1` 바인딩

```csharp
webBuilder.UseUrls("http://127.0.0.1:7020");
```

---

## ✅ 결론

> Windows 환경에서 `localhost`를 다중 프로세스 간에 공유할 경우, Nginx나 Ocelot처럼 고속 loopback 통신이 필요한 서비스들 사이에서 **병목 현상이 발생**할 수 있다. 따라서 내부 통신에는 항상 `127.0.0.1`을 명시적으로 사용하는 것이 안전하다.
