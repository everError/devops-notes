# 🚀 .NET Native AOT: .NET 애플리케이션의 네이티브 실행

.NET Native AOT는 **.NET 7+부터 공식 지원되는 AOT(Ahead-Of-Time) 컴파일 기능**으로,  
**JIT 없이 .NET 애플리케이션을 네이티브 바이너리로 변환**하여 빠른 실행 속도와 낮은 메모리 사용량을 제공합니다.

## ✅ .NET Native AOT의 특징

- **런타임 없이 실행 가능** → 독립적인 실행 파일 생성 (Self-Contained)
- **JIT 없이 즉시 실행** → 서버리스 및 컨테이너 환경에서 빠른 기동
- **메모리 사용량 감소** → JIT & GC 최적화

## ✅ .NET Native AOT 적용 방법

### 📌 1) 프로젝트 파일 수정 (`.csproj`)

```xml
<PropertyGroup>
    <PublishAot>true</PublishAot>
    <RuntimeIdentifier>linux-x64</RuntimeIdentifier>
    <SelfContained>true</SelfContained>
</PropertyGroup>
```

### 📌 2) AOT 빌드 실행

```sh
dotnet publish -c Release -r linux-x64 --self-contained true -p:PublishAot=true
```

## ✅ .NET Native AOT vs JIT 비교

| 비교 항목         | 기존 .NET (JIT) | .NET Native AOT |
| ----------------- | --------------- | --------------- |
| **기동 속도**     | 느림 (~초 단위) | 빠름 (~ms 단위) |
| **메모리 사용량** | 많음            | 적음            |
| **컨테이너 크기** | 200~500MB       | 30~50MB         |

💡 **.NET Native AOT를 활용하면 컨테이너 크기를 줄이고, 서버리스 환경에서 빠른 실행이 가능합니다.** 🚀
