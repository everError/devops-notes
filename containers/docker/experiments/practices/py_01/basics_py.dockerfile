# FROM: 기반 레이어가 되는 이미지를 지정.
FROM registry.access.redhat.com/ubi8/python-39
# ENV: 앱의 환경 변수 설정
ENV PORT=8080
# EXPOSE: 컨테이너 네트워크에 포트를 노출
EXPOSE 8080
# WORKDIR: 컨테이너 내부 작업 디렉터리 설정
WORKDIR /usr/src/app
# COPY: 도커 파일을 빌드하는 워크스테이션의 소스 파일을 
# 컨테이너 이미지 레이어, 이 경우에는 WORKDIR에 복사
COPY requirements.txt ./
# RUN: 기반 이미지에 포함된 도구를 사용하여 컨테이너 안에서 명령을 실행.
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# ENDPOINT: 컨테이너 내부의 앱 진입점(entrypoint)을 정의. 바이너리일 수도 있고, 
# 스크립트일 수도 있다. 이 예제에서는 파이썬 인터프리터.
ENTRYPOINT ["python"]
# CMD: 컨테이너를 시작할 때 사용하는 명령어.
CMD ["app.py"]

# docker build -f <Dockerfile경로> -t <이미지명>:<태그> <컨텍스트경로>  
# 도커파일 지정하여 이미지 이름과 태그로 빌드, 컨텍스트는 파일 복사 기준 경로
