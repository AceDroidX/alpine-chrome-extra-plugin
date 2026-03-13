FROM node:24-trixie-slim

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources \
    && apt update && apt install -y \
    git \
    curl \
    wget \
    nano \
    && npm config set registry https://registry.npmmirror.com/ \
    && npm install -g pnpm@10.18.3
