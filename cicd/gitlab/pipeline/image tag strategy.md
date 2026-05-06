# Docker 이미지 태그 전략

CI/CD 파이프라인에서 빌드한 이미지에 어떤 태그를 붙일지에 대한 결정. 단순해 보이지만 **rollback 가능성**, **추적성**, **부분 빌드와의 호환성** 에 직접 영향을 준다.

---

## 🎯 결론부터

**최소 두 태그를 동시에 푸시한다**:

```bash
docker build \
  -t "$REGISTRY/myapp:$CI_COMMIT_SHORT_SHA" \   # 추적용 (immutable)
  -t "$REGISTRY/myapp:latest" \                 # 배포용 (mutable)
  .
docker push "$REGISTRY/myapp:$CI_COMMIT_SHORT_SHA"
docker push "$REGISTRY/myapp:latest"
```

배포는 **`:latest`** 로 받고, **`:SHA`** 는 audit / rollback 시 참조용으로 보관.

---

## 1. 후보 전략 비교

### A. SHA 태그만 사용

```yaml
deploy:
  variables:
    IMAGE_TAG: "${CI_COMMIT_SHORT_SHA}"
  script:
    - docker compose pull
```

| 장점 | 단점 |
|---|---|
| 어떤 commit 이 떠있는지 명확 | 부분 빌드와 호환 안 됨 — 일부만 빌드된 SHA 는 다른 서비스 이미지에 존재하지 않음 → `pull` 시 404 |
| immutable, audit 완벽 | rollback 시 compose 의 `image:` 라인을 수동 교체 |

### B. `:latest` 만 사용

| 장점 | 단점 |
|---|---|
| 단순. 부분 빌드 OK | 어떤 commit 인지 추적 어려움 (`docker inspect` 의 digest 로 매칭해야 함) |
| | rollback 시 직전 latest 가 이미 덮어씌워짐 |

### C. SHA + latest 동시 푸시 (권장)

| 장점 | 단점 |
|---|---|
| 단순 (deploy 는 :latest) | 약간의 디스크 — 같은 이미지 두 태그라 사실상 동일 (registry 가 layer 공유) |
| 추적 가능 (SHA 태그 보존) | |
| rollback 경로 존재 (registry 에서 SHA 태그로 pull) | |

→ 대부분의 CI 환경에서 **C** 가 표준.

---

## 2. 채널 태그 (선택)

서비스 규모가 커지면 환경별 채널 태그를 추가:

| 태그 | 의미 | 누가 갱신 |
|---|---|---|
| `:abc1234` | 특정 commit | 모든 빌드 |
| `:latest` | 가장 최근 빌드 | 모든 빌드 |
| `:dev` | 개발 환경 배포본 | dev 브랜치 빌드 |
| `:staging` | 스테이징 배포본 | 수동 승격 또는 staging 브랜치 |
| `:prod` | 운영 배포본 | 수동 승격 |
| `:stable` | 검증된 안정 빌드 (rollback 용) | 수동 |

각 환경의 compose 는 자기 환경 태그를 받음 (`prod-server` 는 `:prod` 만 pull).

승격 (promote) 은 별도 잡으로:

```yaml
promote_to_prod:
  stage: promote
  when: manual
  script:
    - docker pull "$REGISTRY/myapp:$CI_COMMIT_SHORT_SHA"
    - docker tag  "$REGISTRY/myapp:$CI_COMMIT_SHORT_SHA" "$REGISTRY/myapp:prod"
    - docker push "$REGISTRY/myapp:prod"
```

⚠️ 채널 태그 패턴은 **운영 부담이 늘어난다.** 작은 팀 / 작은 시스템에서는 **C 만으로 충분.** 필요해진 시점에 도입.

---

## 3. 빌드 캐시 태그

빌드 캐시 전용 태그 추가 (`:cache`):

```bash
docker build \
  --cache-from "$REGISTRY/myapp:cache" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t "$REGISTRY/myapp:$CI_COMMIT_SHORT_SHA" \
  -t "$REGISTRY/myapp:latest" \
  -t "$REGISTRY/myapp:cache" \
  .
```

- `:cache` 는 layer cache 메타데이터를 가진 이미지.
- 다음 빌드 시 `--cache-from` 으로 재사용 → 빌드 시간 단축.
- 첫 빌드 시 `:cache` 가 없으면 무시되고 (경고만) 정상 빌드.

⚠️ 일부 BuildKit 버전에서 `:cache` not found 가 fatal 로 처리되는 케이스가 있다. 그땐 첫 빌드만 `--cache-from` 빼고 통과시킨 후 다음 빌드부터 추가.

---

## 4. 부분 빌드 시나리오 — 흔한 함정

모노레포에서 web 만 변경된 push 가 발생:

1. `build_web` 만 실행 → `web:abc1234`, `web:latest` push
2. `build_backend` skip → backend 태그는 직전 상태 그대로
3. `deploy` 가 SHA 로 받으려 하면:
   ```
   docker compose pull
   → web:abc1234 ✅
   → backend:abc1234 ❌ 404 not found
   ```

### 해결

deploy 는 항상 `:latest` 로:

```yaml
deploy:
  script:
    - cd /opt/myapp
    - export IMAGE_TAG=latest    # SHA 가 아님
    - docker compose pull
    - docker compose up -d
```

→ web 은 새 latest, backend 는 직전 latest 그대로 유지. 정상 동작.

상세는 [monorepo pipeline strategy.md](monorepo%20pipeline%20strategy.md#3-builddeploy-사이의-함정--부분-빌드--sha-태그) 참조.

---

## 5. Rollback 절차 (SHA 태그 기반)

`:latest` 가 망가졌을 때:

```bash
# 1. registry 에서 직전 정상 SHA 확인 (Harbor/registry UI 의 Tag history)
PREV_SHA=abc1234

# 2. compose 의 image 줄을 임시로 SHA 로 변경
sed -i "s|myapp:latest|myapp:$PREV_SHA|g" docker-compose.yml

# 3. 재배포
docker compose pull
docker compose up -d

# 4. (선택) 다음 정상 빌드가 :latest 를 갱신할 때까지 SHA 고정
```

또는 그 SHA 이미지를 `:latest` 로 다시 태그해서 push:

```bash
docker pull "$REGISTRY/myapp:$PREV_SHA"
docker tag  "$REGISTRY/myapp:$PREV_SHA" "$REGISTRY/myapp:latest"
docker push "$REGISTRY/myapp:latest"

cd /opt/myapp
docker compose pull
docker compose up -d
```

---

## ✅ 체크리스트

- [ ] 빌드 잡은 **SHA 태그 + latest 태그** 같이 푸시
- [ ] 배포 잡은 **`:latest`** 강제 (`export IMAGE_TAG=latest`)
- [ ] (선택) 빌드 캐시용 `:cache` 태그
- [ ] (선택) 환경별 채널 태그 (`:dev`, `:prod`) — 규모 커지면
- [ ] Registry retention policy 로 오래된 SHA 태그 자동 정리 (디스크 절약)
