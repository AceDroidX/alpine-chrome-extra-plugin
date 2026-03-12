ARG USE_CHINA_MIRROR=false
ARG ENABLE_NOVNC=false

FROM node:24-trixie-slim AS base
ARG USE_CHINA_MIRROR
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
WORKDIR /app
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        sed -i 's|http://deb.debian.org/debian|http://mirrors.ustc.edu.cn/debian|g; s|http://deb.debian.org/debian-security|http://mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
        npm config set registry https://registry.npmmirror.com; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g pnpm@10.18.3 \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build
COPY pnpm-lock.yaml package.json ./
RUN pnpm fetch --prod
COPY . .
RUN pnpm install --offline --prod

FROM base AS release
ARG USE_CHINA_MIRROR
ARG ENABLE_NOVNC
ENV DEBIAN_FRONTEND=noninteractive
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        sed -i 's|http://deb.debian.org/debian|http://mirrors.ustc.edu.cn/debian|g; s|http://deb.debian.org/debian-security|http://mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
    fi \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        dumb-init \
        fonts-noto-color-emoji \
        fonts-wqy-zenhei \
        socat \
        xvfb \
        wget \
    && wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/google-chrome-stable_current_amd64.deb \
    && if [ "$ENABLE_NOVNC" = "true" ]; then \
        apt-get install -y --no-install-recommends novnc websockify x11vnc; \
    fi \
    && rm -f /tmp/google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

COPY local.conf /etc/fonts/local.conf

RUN useradd --create-home --shell /bin/bash chrome \
    && mkdir -p /app /app/puppeteer /tmp/.X11-unix \
    && chmod 1777 /tmp /tmp/.X11-unix \
    && chown -R chrome:chrome /app

USER chrome
WORKDIR /app

ENV CHROME_BIN=/usr/bin/google-chrome \
    CHROME_PATH=/opt/google/chrome/chrome \
    CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage" \
    DISPLAY=:7 \
    ENABLE_NOVNC=${ENABLE_NOVNC} \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    XVFB_SCREEN=0 \
    XVFB_WHD=1336x768x24 \
    CHROME_DEBUG_PORT=9221 \
    DEVTOOLS_PORT=9222

COPY --chown=chrome:chrome --from=build /app/node_modules ./node_modules
COPY --chown=chrome:chrome --from=build /app/index.ts ./index.ts
COPY --chown=chrome:chrome --from=build /app/wrap.sh ./wrap.sh
RUN sed -i 's/\r$//' /app/wrap.sh \
    && chmod 755 /app/wrap.sh

VOLUME /app/puppeteer
EXPOSE 9222/tcp
ENTRYPOINT ["dumb-init", "--", "/app/wrap.sh"]
