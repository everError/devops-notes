### 📌 `graalvm.md`

# 🚀 GraalVM: 고성능 멀티 런타임

GraalVM은 **고성능 다중 언어 실행 환경**으로, Java뿐만 아니라 여러 프로그래밍 언어(JavaScript, Python, C, C++ 등)를 실행할 수 있으며,  
**네이티브 이미지(Native Image) 기능을 활용하여 Java 애플리케이션을 AOT(Ahead-Of-Time) 컴파일하여 실행 속도를 극대화할 수 있습니다.**

## ✅ GraalVM의 특징

- **JIT & AOT 지원** → 실행 중 최적화(JIT) + 네이티브 바이너리 빌드(AOT) 가능
- **멀티 언어 지원** → Java, Kotlin, Scala, JavaScript, Python, C, C++ 실행 가능
- **빠른 기동 속도** → 네이티브 이미지 빌드 시 실행 속도가 JIT 대비 10배 이상 빠름
- **낮은 메모리 사용량** → JIT를 제거한 네이티브 이미지 활용 가능

## ✅ GraalVM 설치 및 기본 사용법

### 📌 1) GraalVM 설치

```sh
# GraalVM 다운로드 (Java 21 버전)
sdk install java 21.0.1-graal
```

````

### 📌 2) GraalVM 네이티브 이미지 빌드

```sh
# 프로젝트 빌드 후 네이티브 바이너리 생성
native-image -jar myapp.jar
./myapp  # 네이티브 바이너리 실행
```

## ✅ GraalVM과 JIT vs AOT 비교

| 비교 항목           | 기존 JVM (JIT)  | GraalVM (AOT)   |
| ------------------- | --------------- | --------------- |
| **기동 속도**       | 느림 (~초 단위) | 빠름 (~ms 단위) |
| **메모리 사용량**   | 많음            | 적음            |
| **컨테이너 최적화** | 일반적          | 매우 적합       |

```
````
