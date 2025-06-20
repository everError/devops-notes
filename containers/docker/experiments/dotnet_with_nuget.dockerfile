# 1단계: 빌드 환경

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
ARG GITLAB_TOKEN

WORKDIR /src

# NuGet 소스 추가 (비밀번호는 ARG로 전달)

RUN dotnet nuget add source \
 --name [xxx] \
 --username [xxx] \
 --password "$GITLAB_TOKEN" \
 --store-password-in-clear-text \
 [xxx]

# 필요한 파일만 먼저 복사

COPY Helper.Service/Helper.Service.csproj Helper.Service/
COPY AuthService/AuthService.csproj AuthService/

# 복원

RUN dotnet restore AuthService/AuthService.csproj

# 전체 복사

COPY . .

# 빌드

WORKDIR /src/AuthService
RUN dotnet publish AuthService.csproj -c Release -o /app/publish /p:UseAppHost=false

# 2단계: 런타임 환경

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app

# 타임존 설정

RUN ln -snf /usr/share/zoneinfo/Asia/Seoul /etc/localtime && echo Asia/Seoul > /etc/timezone

# 결과물 복사

COPY --from=build /app/publish .

# 포트 노출

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["dotnet", "AuthService.dll"]
