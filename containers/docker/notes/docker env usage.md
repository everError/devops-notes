# 🐳 Docker 환경 변수 사용 정리

## ✅ 기본 개념

Docker 및 Docker Compose에서는 `.env` 파일 또는 `environment` 항목을 통해 컨테이너 실행 시 환경 변수를 설정할 수 있습니다.

---

## 📄 1. `.env` 파일 사용

- `docker-compose.yml`과 **같은 경로**에 `.env` 파일을 두면 자동으로 로드됩니다.
- 포맷:

```env
# .env
POSTGRES_PASSWORD=mysecret
DB_PORT=5432
```

- 사용 예:

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${DB_PORT}:5432"
```

- 주의사항:

  - 공백 없이 작성해야 함: `KEY=value`
  - 주석은 `#`으로 시작
  - `.env` 파일은 `docker-compose.yml`과 같은 경로에 있어야 자동 적용됨

---

## 🧾 2. Compose 파일 내 `environment` 블록

- 직접 환경 변수 지정 가능:

```yaml
services:
  app:
    image: my-app:latest
    environment:
      - NODE_ENV=production
      - API_KEY=${API_KEY} # .env에서도 참조 가능
```

---

## 📤 3. Docker CLI에서 직접 지정

```bash
docker run -e VAR_NAME=value my-image
```

또는 여러 개를 `.env`에서 불러와서 사용:

```bash
docker run --env-file .env my-image
```

---

## 📌 기타 팁

| 항목                        | 설명                                                         |
| --------------------------- | ------------------------------------------------------------ |
| `docker-compose --env-file` | `v1.28+`부터 명시적으로 다른 `.env` 파일 지정 가능           |
| Git 저장소                  | `.env`는 민감 정보 포함되므로 `.gitignore`에 추가 권장       |
| 복수 환경                   | `.env.dev`, `.env.prod` 등 분리해서 shell script로 로딩 가능 |

```bash
# 예: 환경 지정
export $(cat .env.prod | xargs) && docker compose up
```

---

## ✅ 요약

| 방법               | 적용 대상         | 설명               |
| ------------------ | ----------------- | ------------------ |
| `.env` 파일        | docker-compose    | 자동 인식, 편리함  |
| `environment`      | compose 파일 내부 | 명시적으로 정의    |
| `-e`, `--env-file` | docker CLI        | 유연하게 지정 가능 |

환경 변수를 잘 활용하면 구성 변경 없이 다양한 배포 환경을 유연하게 다룰 수 있습니다.
