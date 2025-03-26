ARG PROJECT_DIR
ARG PROJECT_NAME

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG PROJECT_DIR
ARG PROJECT_NAME

WORKDIR /app
COPY . .

WORKDIR /app/${PROJECT_DIR}
RUN dotnet restore ${PROJECT_NAME}.csproj
RUN dotnet publish ${PROJECT_NAME}.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
ARG PROJECT_NAME
ENV PROJECT_NAME=${PROJECT_NAME}
WORKDIR /app
COPY --from=build /app/publish ./
ENTRYPOINT ["/bin/sh", "-c", "dotnet \"$PROJECT_NAME.dll\""]