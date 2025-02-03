# 🐳 Docker 기본 명령어 정리

---

## 👐 1️⃣ Docker 설치 확인

```bash
docker --version
```

✔ 설치된 Docker의 버전을 확인합니다.

```bash
docker info
```

✔ Docker 데머니 실행 중인지, 전체적인 환경을 확인합니다.

---

## 📀 2️⃣ Docker 콘텐이너 실행 및 관리

### ▶ **콘텐이너 실행**

```bash
docker run hello-world
```

✔ `hello-world` 콘텐이너를 실행하여 Docker가 정상적으로 동작하는지 확인합니다.

```bash
docker run -it ubuntu /bin/bash
```

✔ `ubuntu` 콘텐이너를 실행하고, 내보에서 Bash 셀을 사용할 수 있도록 합니다.  
✔ `-it` 옵션: **대화형 모드(interactive) + 터미널(tty) 활성화**

```bash
docker run -d --name my-container nginx
```

✔ 백그라운드(`-d`)에서 `nginx` 콘텐이너 실행  
✔ `--name my-container`으로 콘텐이너 이름 지정

---

### ▶ **실행 중인 콘텐이너 목록 조회**

```bash
docker ps
```

✔ 현재 실행 중인 콘텐이너 목록을 확인합니다.

```bash
docker ps -a
```

✔ 종료된 콘텐이너를 포함한 모든 콘텐이너 목록을 확인합니다.

```bash
docker ps --filter "status=exited"
```

✔ 종료된 콘텐이너만 필터링하여 출력합니다.

---

### ▶ **콘텐이너 정지 및 삭제**

```bash
docker stop <콘텐이너_ID 또는 콘텐이너_이름>
```

✔ 실행 중인 콘텐이너를 정지합니다.

```bash
docker rm <콘텐이너_ID 또는 콘텐이너_이름>
```

✔ 정지된 콘텐이너를 삭제합니다.

```bash
docker rm -f <콘텐이너_ID>
```

✔ 강제(`-f`)로 실행 중인 콘텐이너를 중지하고 삭제합니다.
