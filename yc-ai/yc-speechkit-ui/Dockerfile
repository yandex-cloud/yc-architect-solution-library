#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y libpng-dev libjpeg-dev curl libxi6 build-essential libgl1-mesa-glx
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y libpng-dev libjpeg-dev curl libxi6 build-essential libgl1-mesa-glx
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs
WORKDIR /src
COPY ["yc-speechkit-ui/yc-speechkit-ui.csproj", "yc-speechkit-ui/"]
RUN dotnet restore "yc-speechkit-ui/yc-speechkit-ui.csproj"
COPY . .
WORKDIR "/src/yc-speechkit-ui"
RUN dotnet build "yc-speechkit-ui.csproj" -c Release -o /app/build

FROM build AS publish
RUN npm config set @yandex-data-ui:registry=https://npm.yandex-team.ru/@yandex-data-ui
RUN npm config set @yandex-cloud:registry=https://npm.yandex-team.ru/@yandex-cloud
RUN dotnet publish "yc-speechkit-ui.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "yc-speechkit-ui.dll"]