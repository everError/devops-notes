# 🐳 Dockerfile 기본 개념 및 작성법

Dockerfile은 **컨테이너 이미지를 생성하기 위한 스크립트 파일**로, 애플리케이션 실행에 필요한 환경을 정의합니다.

## 📌 Dockerfile 기본 구조

Dockerfile은 각 명령어가 단계별로 실행되며, 아래와 같은 기본 구조를 가집니다.

```dockerfile
# 1. 기본 베이스 이미지 설정
FROM ubuntu:20.04

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 파일 복사
COPY . .

# 4. 패키지 업데이트 및 필수 패키지 설치
RUN apt-get update && apt-get install -y curl

# 5. 환경 변수 설정
ENV APP_ENV=production

# 6. 컨테이너 실행 시 기본 실행 명령어
CMD ["bash"]
```

---

## 📌 주요 명령어 설명

### ✅ `FROM <이미지>`

- **기본 이미지(Base Image)**를 지정합니다.
- 예: `FROM node:18`, `FROM python:3.9`

### ✅ `WORKDIR <경로>`

- 컨테이너 내부의 **작업 디렉토리**를 지정합니다.
- 예: `WORKDIR /usr/src/app`

### ✅ `COPY <로컬경로> <컨테이너경로>`

- 호스트의 파일을 컨테이너 내부로 복사합니다.
- 예: `COPY . /app`

### ✅ `RUN <명령어>`

- **이미지 빌드 중 실행될 명령어**를 작성합니다.
- 예: `RUN apt-get update && apt-get install -y curl`

### ✅ `ENV <변수명> <값>`

- 컨테이너 내에서 사용할 **환경 변수**를 설정합니다.
- 예: `ENV NODE_ENV=production`

### ✅ `CMD ["명령어", "인자"]`

- 컨테이너가 실행될 때 기본으로 실행할 명령어를 지정합니다.
- 예: `CMD ["node", "server.js"]`

### ✅ `ENTRYPOINT ["명령어"]`

- 컨테이너 실행 시 **기본 실행 프로그램**을 설정합니다.
- `CMD`와의 차이점: `CMD`는 실행 시 인자로 변경 가능하지만, `ENTRYPOINT`는 고정됨.
- 예: `ENTRYPOINT ["python"]`

---

## 📌 Dockerfile을 이용한 이미지 빌드 및 실행

### ▶ **이미지 빌드**

```bash
docker build -t my-custom-image .
```

✔ 현재 디렉토리에 있는 `Dockerfile`을 기반으로 `my-custom-image`라는 이름으로 빌드합니다.

### ▶ **컨테이너 실행**

```bash
docker run -it my-custom-image
```

✔ `my-custom-image`를 실행합니다.

---
