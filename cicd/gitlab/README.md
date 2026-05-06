# GitLab CI/CD 노트

GitLab 을 사용한 CI/CD 운영 노트. **Server / Runner / Pipeline** 세 레이어로 분류.

```
┌──────────────────────────────────┐
│ Server   GitLab 서버 그 자체       │  외부 URL, reverse proxy 통합, 백업
├──────────────────────────────────┤
│ Runner   잡을 실제로 실행하는 호스트 │  config.toml, executor, 컨테이너화
├──────────────────────────────────┤
│ Pipeline .gitlab-ci.yml           │  rules, stages, matrix, 캐시 전략
└──────────────────────────────────┘
```

---

## 📂 server/

GitLab 서버 자체의 설치/운영.

- [docker-compose.yml](server/docker-compose.yml) — GitLab CE + Runner 를 docker compose 로 띄우는 예시

---

## 📂 runner/

GitLab Runner 등록/설정.

- [setup.md](runner/setup.md) — Runner 등록 기본 절차

---

## 📂 pipeline/

`.gitlab-ci.yml` 작성법과 운영 전략.

- [ci syntax.md](pipeline/ci%20syntax.md) — `.gitlab-ci.yml` 핵심 문법
- [docker build pipeline.md](pipeline/docker%20build%20pipeline.md) — Docker 이미지 빌드 + 푸시 + 배포 전체 흐름
- [monorepo pipeline strategy.md](pipeline/monorepo%20pipeline%20strategy.md) — 모노레포에서 부분 빌드 + matrix 병렬

---

## 📂 issues/

GitLab CI 사용 중 자주 마주치는 트러블슈팅.

(주제별 파일이 추가되는 폴더)

---

## 🔗 연관 문서

- [containers/docker/notes/](../../containers/docker/notes/) — Dockerfile 작성, BuildKit, network
- [deployment/nginx/notes/](../../deployment/nginx/notes/) — reverse proxy, TLS
- [build/dotnet/issues/](../../build/dotnet/issues/) — .NET 빌드 관련 이슈 (NuGet 인증 등)
