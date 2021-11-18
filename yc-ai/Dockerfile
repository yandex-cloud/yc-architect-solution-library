#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /app/yc-speechkit-streaming-asr

FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
###############################################################
#  yc-speechkit-streaming-asr
###############################################################
WORKDIR /src/yc-speechkit-streaming-asr/
COPY ["yc-speechkit-streaming-asr/yc-speechkit-streaming-asr.csproj", "."]
RUN dotnet restore "./yc-speechkit-streaming-asr.csproj"
COPY ./yc-speechkit-streaming-asr/ .
WORKDIR "/src/yc-speechkit-streaming-asr/."
RUN dotnet build "yc-speechkit-streaming-asr.csproj" -c Release -o /app/yc-speechkit-streaming-asr/build

###############################################################
#  yc-speechkit-hybrid
###############################################################
WORKDIR /src/yc-speechkit-hybrid/
COPY ["yc-speechkit-hybrid/yc-speechkit-hybrid.csproj", "."]
RUN dotnet restore "./yc-speechkit-hybrid.csproj"
COPY ./yc-speechkit-hybrid/ .
WORKDIR "/src/yc-speechkit-hybrid/."
RUN dotnet build "yc-speechkit-hybrid.csproj" -c Release -o /app/yc-speechkit-hybrid/build

###############################################################
#  yc-speechkit-batch-asr
###############################################################
WORKDIR /src/yc-speechkit-batch-asr/
COPY ["yc-speechkit-batch-asr/yc-speechkit-batch-asr.csproj", "."]
RUN dotnet restore "./yc-speechkit-batch-asr.csproj"
COPY ./yc-speechkit-batch-asr/ .
WORKDIR "/src/yc-speechkit-batch-asr/."
RUN dotnet build "yc-speechkit-batch-asr.csproj" -c Release -o /app/yc-speechkit-batch-asr/build

FROM build AS publish
RUN dotnet publish "yc-speechkit-streaming-asr.csproj" -c Release -o /app/yc-speechkit-streaming-asr/
RUN dotnet publish "yc-speechkit-hybrid.csproj" -c Release -o /app/yc-speechkit-hybrid/
RUN dotnet publish "yc-speechkit-batch-asr.csproj" -c Release -o /app/yc-speechkit-batch-asr/

FROM base AS final
WORKDIR /app/yc-speechkit-streaming-asr/
COPY --from=publish /app/yc-speechkit-streaming-asr/ .

WORKDIR /app/yc-speechkit-batch-asr/
COPY --from=publish /app/yc-speechkit-batch-asr/ .
#ENTRYPOINT ["dotnet", "yc-speechkit-streaming-asr.dll"]

WORKDIR /app/yc-speechkit-hybrid/
COPY --from=publish /app/yc-speechkit-hybrid/ .

WORKDIR /app