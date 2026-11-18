FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y wine wine32 wine64 libstdc++6:i386 ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

EXPOSE 8192/udp
EXPOSE 8080/tcp

CMD ["bash", "start.sh"]
