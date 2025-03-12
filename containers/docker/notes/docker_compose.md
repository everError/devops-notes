# Docker Compose 가이드 (자세한 설명)

## 📌 개요

Docker Compose는 여러 개의 Docker 컨테이너 애플리케이션을 정의하고 실행할 수 있도록 도와주는 도구입니다. `docker-compose.yml` 파일 하나로 **컨테이너 정의, 네트워크, 볼륨, 환경 변수, 포트 설정 등**을 관리할 수 있습니다.

---

## ✅ 기본 구조

```yaml
version: "3.8" # Compose 파일 버전

services: # 애플리케이션을 구성하는 컨테이너 목록
  web: # 서비스 이름 (컨테이너 명)
    image: nginx # 사용할 이미지
    ports:
      - "80:80" # 호스트:컨테이너 포트 매핑
```

---

## ✅ 주요 항목 설명

| 항목           | 설명                                                |
| -------------- | --------------------------------------------------- |
| version        | Compose 파일 포맷 버전 (보통 3.x 권장)              |
| services       | 여러 개의 컨테이너를 정의하는 블록                  |
| image          | 사용할 Docker 이미지 이름 또는 태그                 |
| container_name | 컨테이너 명을 명시적으로 지정 (생략 시 자동 생성됨) |
| build          | 이미지 빌드를 위한 Dockerfile 경로 지정 가능        |
| ports          | 호스트-컨테이너 포트 바인딩 설정                    |
| volumes        | 호스트 ↔ 컨테이너 간 파일 공유 설정                 |
| networks       | 컨테이너가 사용할 네트워크 설정                     |
| environment    | 환경 변수 지정 (DB 비밀번호 등)                     |
| depends_on     | 다른 서비스 실행 순서 제어                          |

---

## ✅ 예시: Nginx + API 서버 구성

```yaml
version: "3.8"

services:
  nginx:
    container_name: app-nginx
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - /etc/letsencrypt:/etc/letsencrypt
    networks:
      - mynet

  api:
    container_name: app-api
    build:
      context: ./api
      dockerfile: Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
    networks:
      - mynet

depends_on:
  - api

networks:
  mynet:
    driver: bridge
```

---

## ✅ volumes 예시 설명

```yaml
volumes:
  - ./data:/var/lib/data
```

| 항목          | 설명                      |
| ------------- | ------------------------- |
| ./data        | 호스트 디렉토리 경로      |
| /var/lib/data | 컨테이너 내부 마운트 위치 |

이 설정은 컨테이너 종료 후에도 데이터를 유지하거나 호스트와 실시간 동기화할 때 유용합니다.

---

## ✅ networks 예시 설명

```yaml
networks:
  app-net:
    driver: bridge
```

- `bridge`: 기본 가상 네트워크 드라이버입니다. 컨테이너 간 통신 가능하게 합니다.

---

## 📎 기타 유용한 명령어

| 명령어                              | 설명                                     |
| ----------------------------------- | ---------------------------------------- |
| `docker-compose up`                 | 설정된 컨테이너들 실행                   |
| `docker-compose up -d`              | 백그라운드(Detached 모드) 실행           |
| `docker-compose down`               | 실행 중인 모든 컨테이너 및 네트워크 정리 |
| `docker-compose ps`                 | 현재 실행 중인 서비스 상태 확인          |
| `docker-compose logs`               | 서비스 로그 출력                         |
| `docker-compose exec 서비스명 bash` | 컨테이너 내부 접근 (bash)                |

---

## ✅ 결론

- Docker Compose는 복잡한 컨테이너 기반 애플리케이션을 단순하게 구성하고 관리할 수 있게 해주는 강력한 도구입니다.
- 하나의 `docker-compose.yml` 파일로 **컨테이너, 네트워크, 볼륨, 환경 변수, 실행 순서**까지 모두 통합 관리 가능합니다.

필요 시 `.env` 파일과 연계하여 동적 구성도 가능하며, 실무 환경에서 널리 사용됩니다.
