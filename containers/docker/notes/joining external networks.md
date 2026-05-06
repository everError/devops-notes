# 기존 Docker Network 에 합류하기 (`external: true`)

이미 호스트에 떠있는 다른 docker compose 의 컨테이너 (예: 공용 DB, 공용 reverse proxy) 와 통신하려면, 그 컨테이너가 속한 **network 에 합류** 한다. 컨테이너간은 컨테이너명/service 이름으로 DNS 통신 가능.

---

## 🎯 언제 쓰나

- **공용 인프라 컨테이너** 가 별도 compose 로 운영됨 (DB, Redis, MinIO, reverse proxy 등)
- 그 인프라를 우리 앱 compose 와 **격리해서 관리** 하고 싶지만, 통신은 가능해야 함
- 인프라쪽 compose 를 수정하지 않고 우리 쪽에서만 합류

---

## 1. 사전 확인 — 어느 network 인가

대상 컨테이너가 어느 network 에 붙어있는지 확인:

```bash
docker inspect postgres --format '{{json .NetworkSettings.Networks}}' | jq
```

또는 짧게:

```bash
docker inspect postgres --format '{{range $name, $cfg := .NetworkSettings.Networks}}{{$name}} {{end}}'
# postgresql_default
```

여러 network 에 동시에 붙어있을 수 있음. 이 중 합류 대상을 선택.

### Compose 가 만드는 network 이름 규칙

다른 compose 가 명시적으로 `name:` 안 줬으면, network 이름은 **`<프로젝트명>_<compose 안의 networks 키>`** 형식.

| compose 위치 | 기본 프로젝트명 | networks 키 | 실제 network 이름 |
|---|---|---|---|
| `/srv/postgres/docker-compose.yml` | `postgres` (디렉토리명) | (생략 시) | `postgres_default` |
| `/srv/postgres/docker-compose.yml` | `postgres` | `db-net` | `postgres_db-net` |

직접 `docker network ls` 로 확인.

---

## 2. 우리 compose 에서 external network 선언

```yaml
networks:
  # 우리 서비스끼리 통신
  myapp-internal:
    name: myapp-internal
    driver: bridge
  
  # 기존 인프라 network 재사용
  postgresql_default:
    external: true                    # ← 이 network 는 외부 (다른 compose) 가 만든 것

services:
  myapi:
    image: myapi:latest
    networks:
      - myapp-internal                # 다른 자기 서비스와 통신
      - postgresql_default            # postgres 와 통신
    environment:
      DB_HOST: postgres               # ← 컨테이너명/alias 그대로
      DB_PORT: 5432
```

`external: true` 의 의미:
- compose 가 이 network 를 **만들지 않고**, 이미 존재한다고 가정
- compose `down` 해도 이 network 는 삭제 안 됨 (다른 compose 가 사용 중이니)

network 이름이 다를 수 있을 때 명시적 매핑:

```yaml
networks:
  shared-db:
    external: true
    name: postgresql_default          # 실제 docker network 이름
```

---

## 3. 실전 예시 — 앱 + 공용 DB + 공용 nginx

```
호스트
├── /srv/postgres/      ← 별도 compose
│   └── postgres 컨테이너 (network: postgresql_default)
│
├── /srv/nginx/         ← 별도 compose
│   └── nginx 컨테이너 (network: app-edge)
│
└── /srv/myapp/         ← 우리 앱 compose
    ├── api 컨테이너 (networks: myapp-internal + postgresql_default + app-edge)
    ├── worker 컨테이너 (networks: myapp-internal + postgresql_default)
    └── web 컨테이너 (networks: myapp-internal + app-edge)
```

```yaml
# /srv/myapp/docker-compose.yml
networks:
  myapp-internal:
    driver: bridge
  postgresql_default:
    external: true
  app-edge:
    external: true

services:
  api:
    image: myapp/api
    networks:
      - myapp-internal       # worker 와 통신
      - postgresql_default   # postgres 와 통신
      - app-edge             # nginx 가 reverse proxy 하도록 외부 network 에도 노출
    expose:
      - "8080"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432

  worker:
    image: myapp/worker
    networks:
      - myapp-internal
      - postgresql_default

  web:
    image: myapp/web
    networks:
      - myapp-internal
      - app-edge
    expose:
      - "80"
```

호스트 nginx 는 `app-edge` network 에 이미 붙어있으니, conf 에서 `proxy_pass http://web:80` 처럼 컨테이너명으로 바로 접근 가능.

---

## 4. 컨테이너간 DNS — 어떤 이름이 통하나

같은 network 안의 컨테이너끼리는 다음 이름이 모두 DNS 로 해석됨:

| 이름 | 설명 |
|---|---|
| **service 이름** (compose 의 `services:` 키) | 가장 일반적 |
| **container_name** (compose 의 `container_name:`) | 명시했을 때 |
| **alias** (compose 의 `networks.<n>.aliases`) | 추가 별명 |

```yaml
services:
  myapi:
    container_name: my-api-prod
    networks:
      myapp-internal:
        aliases:
          - api
          - api-server
```

→ 다음이 모두 통함:
- `http://myapi:8080` (service 이름)
- `http://my-api-prod:8080` (container_name)
- `http://api:8080`, `http://api-server:8080` (alias)

**권장**: service 이름을 기본으로 사용. 컨벤션상 가장 명확.

---

## 5. 흔한 실수

### 5.1 network 이름 오타

```yaml
networks:
  postgres_default:    # ❌ 실제는 postgresql_default
    external: true
```

→ `docker compose up` 시 `network postgres_default not found` 에러. `docker network ls` 로 확인.

### 5.2 external: true 인데 name 누락 + 이름 다름

```yaml
networks:
  shared:              # 이 키 이름이 곧 network 이름
    external: true
```

위 경우 docker 에 `shared` 라는 network 가 있어야 함. 실제 이름이 `postgresql_default` 면:

```yaml
networks:
  shared:
    external: true
    name: postgresql_default   # ← 실제 이름 명시
```

### 5.3 우리 compose down 시 인프라 network 삭제 걱정

`external: true` 면 **compose down 해도 그 network 는 삭제 안 함**. 안전.

내부 network (예: `myapp-internal`) 는 down 시 삭제됨 (compose 가 만든 거니까) — 정상 동작.

### 5.4 Service 가 여러 network 에 있을 때 routing

여러 network 에 join 한 서비스가 어느 IP 로 응답할지는 docker 가 결정. 보통 문제없지만, 특정 network 의 IP 강제하려면 `ipv4_address` 명시 필요 (드물게 사용).

### 5.5 compose 버전 호환

`external: true` 는 모든 compose 버전에서 지원. 단 `name:` 으로 실제 이름 분리하는 문법은 compose v2 (newer) 에서 안정적.

```yaml
# 구버전 (compose v1) — 제한적
networks:
  shared:
    external:
      name: postgresql_default     # 구문법 (deprecated)

# 신버전 (compose v2)
networks:
  shared:
    external: true
    name: postgresql_default       # 권장
```

---

## 6. 디버깅 명령

```bash
# 컨테이너가 어느 network 에 있나
docker inspect <name> --format '{{range $n,$_ := .NetworkSettings.Networks}}{{$n}} {{end}}'

# Network 안의 모든 컨테이너 보기
docker network inspect postgresql_default | jq '.[].Containers'

# 같은 network 안에서 ping
docker exec myapi-container ping -c 2 postgres
docker exec myapi-container nslookup postgres

# Network 만들지 않고 우리 compose 가 거부하는 경우
docker compose up
# → network "postgresql_default" declared as external, but could not be found
# → docker network ls 로 실제 이름 확인
```

---

## ✅ 체크리스트

- [ ] 합류 대상 network 이름을 `docker network ls` 또는 `docker inspect` 로 정확히 확인
- [ ] 우리 compose 의 `networks` 에 `external: true` 와 (필요 시) `name:` 명시
- [ ] 통신 대상은 service 이름/container_name 으로 호출
- [ ] 우리 서비스가 여러 network 에 join 해야 하면 `services.<x>.networks` 에 모두 나열
- [ ] compose down 시 external network 가 살아있는지 확인 (정상 동작)
