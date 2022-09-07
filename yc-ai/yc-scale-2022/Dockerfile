#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y libpng-dev libjpeg-dev curl libxi6 build-essential libgl1-mesa-glx
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs


FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y libpng-dev libjpeg-dev curl libxi6 build-essential libgl1-mesa-glx
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt-get install -y nodejs
WORKDIR /src
COPY ["yc-scale-2022/yc-scale-2022.csproj", "yc-scale-2022/"]
RUN dotnet restore "yc-scale-2022/yc-scale-2022.csproj"
COPY . .
WORKDIR "/src/yc-scale-2022"
RUN dotnet build "yc-scale-2022.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "yc-scale-2022.csproj" -c Release -o /app/publish

FROM node:16 AS build-web
COPY ./yc-scale-2022/ClientApp/package.json /yc-scale-2022/ClientApp/package.json
COPY ./yc-scale-2022/ClientApp/package-lock.json /yc-scale-2022/ClientApp/package-lock.json
WORKDIR /yc-scale-2022/ClientApp
RUN npm install
COPY ./yc-scale-2022/ClientApp/ /yc-scale-2022/ClientApp
RUN npm run build


FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
COPY --from=build-web /yc-scale-2022/ClientApp/build ./ClientApp/build
ENTRYPOINT ["dotnet", "yc-scale-2022.dll"]