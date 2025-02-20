# 1. 기본 런타임 환경 설정
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80 443
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV ASPNETCORE_URLS="http://+:80"

# 2. 빌드 환경 설정
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Nuget.config", "Nuget.config"]
COPY ["Helper.Service/Helper.Service.csproj", "Helper.Service/"]
COPY ["AuthService/AuthService.csproj", "AuthService/"]
COPY ["AuthService/appsettings.json", "AuthService/"]
RUN dotnet restore "AuthService/AuthService.csproj" --configfile "Nuget.config"
COPY . .
WORKDIR "/src/AuthService"
RUN dotnet build "AuthService.csproj" -c Release -o /app/build

# 3. 퍼블리시 단계
FROM build AS publish
RUN dotnet publish "AuthService.csproj" -c Release -o /app/publish /p:UseAppHost=false --no-restore

# 4. 최종 실행 환경 설정
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AuthService.dll"]