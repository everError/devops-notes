````markdown
# Docker 주요 명령어 정리

이 문서는 자주 사용되는 Docker 명령어들을 기능별로 정리합니다.

---

## ## 이미지 가져오기 및 확인

### ### docker pull
레지스트리(Docker Hub 등)에서 도커 이미지를 로컬 머신으로 다운로드합니다.
```bash
docker pull ubuntu:22.04
````

### \#\#\# docker images

로컬 머신에 저장된 도커 이미지들의 목록을 확인합니다.

```bash
docker images
```

-----

## \#\# 이미지 생성

### \#\#\# docker build

`Dockerfile`을 사용하여 새로운 도커 이미지를 생성합니다. `-t` 옵션으로 이미지의 이름과 태그를 지정합니다.

```bash
# 현재 디렉터리의 Dockerfile을 사용하여 'my-app:1.0' 이라는 이미지 생성
docker build -t my-app:1.0 .
```

-----

## \#\# 컨테이너 실행 및 관리

### \#\#\# docker run

이미지를 기반으로 새로운 컨테이너를 생성하고 실행합니다.

  * `-d`: 백그라운드에서 실행
  * `-p`: 포트 포워딩 (호스트:컨테이너)
  * `--name`: 컨테이너에 이름 부여

<!-- end list -->

```bash
# 'my-app:1.0' 이미지로 'my-running-app' 이라는 이름의 컨테이너를 백그라운드에서 실행하고 8080 포트를 80 포트에 연결
docker run -d -p 8080:80 --name my-running-app my-app:1.0
```

### \#\#\# docker ps

현재 실행 중인 컨테이너들의 목록을 확인합니다. `-a` 옵션을 추가하면 중지된 컨테이너까지 모두 보여줍니다.

```bash
# 실행 중인 컨테이너 확인
docker ps

# 모든 컨테이너 확인
docker ps -a
```

### \#\#\# docker stop

실행 중인 컨테이너를 중지시킵니다.

```bash
docker stop my-running-app
```

### \#\#\# docker rm

중지된 컨테이너를 삭제합니다.

```bash
docker rm my-running-app
```

### \#\#\# docker rmi

로컬에 저장된 이미지를 삭제합니다. 해당 이미지를 사용하는 컨테이너가 없어야 삭제 가능합니다.

```bash
docker rmi my-app:1.0
```

-----

## \#\# 이미지 내보내기 및 가져오기

### \#\#\# docker save

도커 이미지를 `.tar` 아카이브 파일로 저장(내보내기)합니다. 인터넷이 안 되는 환경으로 이미지를 옮길 때 유용합니다.

```bash
# 'my-app:1.0' 이미지를 'my-app.tar' 파일로 저장
docker save -o my-app.tar my-app:1.0
```

### \#\#\# docker load

`.tar` 파일로부터 도커 이미지를 로컬 머신으로 가져옵니다.

```bash
# 'my-app.tar' 파일로부터 이미지 로드
docker load -i my-app.tar
```
