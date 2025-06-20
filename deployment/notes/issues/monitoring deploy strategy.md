## 📈 모니터링 페이지 재배포 전략

### ✅ 목표

> 장애 상황 (정적 페이지 미제공, API 서버 다운 등)에서도 모니터링 페이지가 **최대한 무중단으로 동작**하고, 장애가 발생해도 **사용자가 빠르게 복구됨을 인지하거나 자동 복구**되도록 구성한다.

---

### ✅ 구성 요소

| 구성 요소                  | 역할                                                                                     |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| **HAProxy (단일 진입점)**  | `/` 요청은 정적 파일 서버로, `/api/*` 요청은 API 서버로 라우팅 + 상태 기반 failover 수행 |
| **정적 파일 서버 (Nginx)** | index.html, JS, CSS, 이미지 제공                                                         |
| **Main API 서버**          | 실제 API 응답 제공                                                                       |
| **Fallback API 서버**      | 장애 시 응답: `{ status: 'maintenance' }` 등의 메시지 반환                               |
| **정적 Fallback 페이지**   | `/maintenance.html` 같은 파일로 점검 메시지 표시 및 복구 감지 기능 포함                  |

---

### ✅ 요청 흐름 및 설계 개요

이 전략은 모든 클라이언트 요청이 HAProxy를 통해 정적 자원 서버와 API 서버로 라우팅되고, 어느 한 쪽이라도 정상 응답을 하지 못할 경우 HAProxy가 `/maintenance.html` 정적 페이지로 라우팅하도록 구성되어 있다. 이 fallback 페이지는 클라이언트 단에서 서버들의 정상 복구 여부를 주기적으로 확인하며, 두 서버 모두 복구되었을 때 자동으로 원래 페이지(`/`)로 새로고침하여 최신 상태로 복귀하게 된다.

- 장애가 발생해도 사용자에게 안내 메시지를 제공하고, 수동 조작 없이 자동으로 복구될 수 있는 UX 보장
- 클라이언트는 API와 정적 파일 서버를 각각 병렬로 헬스 체크하며, 둘 다 OK일 경우에만 복귀
- 복귀 시 `/?v=timestamp` 쿼리를 추가하여 캐시를 무효화하고 최신 정적 자산 로딩을 유도

---

### ✅ fallback 정적 페이지 내 JS 코드 예시

```html
<script>
  async function checkRecovery() {
    const [apiOk, staticOk] = await Promise.all([
      fetch("/api/healthz", { cache: "no-store" })
        .then((res) => res.ok)
        .catch(() => false),

      fetch("/healthz", { cache: "no-store" })
        .then((res) => res.ok)
        .catch(() => false),
    ]);

    if (apiOk && staticOk) {
      location.href = "/?v=" + Date.now();
    }
  }

  setInterval(checkRecovery, 5000);
</script>
```

---

### ✅ 장애 대응 전략

| 장애 유형                    | 대응 방식                                                             |
| ---------------------------- | --------------------------------------------------------------------- |
| 정적 서버 또는 API 서버 다운 | HAProxy가 `/maintenance.html`로 라우팅                                |
| fallback 정적 페이지 진입 후 | JS에서 `/api/healthz` + `/healthz` 병렬 체크 → 복구되면 자동 새로고침 |

---

### ✅ Fallback HTML의 복구 처리 로직

- **정적 서버와 API 서버가 모두 살아있는 상태를 확인해야만 자동 복귀**
- 정적 페이지 자체가 최신 상태로 다시 로드되도록 `/?v=timestamp` 쿼리 추가

---

### ✅ HAProxy 설정 예시

```haproxy
frontend http-in
    bind *:80
    acl is_api path_beg /api
    use_backend api_backend if is_api
    default_backend static_backend

backend api_backend
    option httpchk GET /healthz
    server main_api 10.0.0.10:8080 check
    server fallback_api 10.0.0.11:8080 backup

backend static_backend
    option httpchk GET /healthz
    server main_static 10.0.0.20:80 check
    server fallback_static 10.0.0.21:80 backup
```

---

### ✅ 주요 시나리오별 플로우 정리

#### 📌 정상 상태

- `/` 요청 → Nginx → index.html 제공
- `/api/data` → API 서버 정상 응답

#### 📌 API 또는 정적 서버 중 하나라도 다운됨

- HAProxy가 `/maintenance.html`로 라우팅
- JS에서 상태 확인 중, 복구되면 자동 새로고침

#### 📌 재배포 후 복구됨

- JS가 `/healthz`, `/api/healthz`에서 모두 OK 응답 확인
- location.href = `/?v=timestamp` 호출로 최신 페이지 자동 로딩

---

### ✅ 배포 전략 요약

- 장애가 발생하면 무조건 fallback 정적 페이지로 진입시켜, 복구 시점은 클라이언트 JS가 판단
- `/maintenance.html`에서 정적 서버와 API 서버 상태를 병렬로 확인해 자동 복구 처리
- 모든 요청은 반드시 HAProxy를 거치며 상태 기반 라우팅
- 복구 시 정적 캐시 무효화를 위해 `location.href = '/?v=' + Date.now()` 방식 사용
