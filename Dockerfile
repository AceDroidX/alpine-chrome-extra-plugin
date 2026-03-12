ARG USE_CHINA_MIRROR=false
ARG ENABLE_NOVNC=false

FROM node:24.10-alpine AS base
ARG USE_CHINA_MIRROR
WORKDIR /app
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories; fi \
    && npm install -g pnpm@10.18.3 \
    && npm cache clean --force

FROM base AS build
COPY pnpm-lock.yaml ./
RUN pnpm fetch --prod
COPY . .
RUN pnpm install --offline --prod

# https://github.com/jlandure/alpine-chrome/blob/master/Dockerfile

FROM base AS chrome
ARG USE_CHINA_MIRROR

# Installs latest Chromium package.
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then COMMUNITY_REPO_BASE=https://mirrors.ustc.edu.cn/alpine; else COMMUNITY_REPO_BASE=https://dl-cdn.alpinelinux.org/alpine; fi \
    && ALPINE_VERSION=$(cut -d. -f1,2 /etc/alpine-release) \
    && COMMUNITY_REPO="$COMMUNITY_REPO_BASE/v${ALPINE_VERSION}/community" \
    && apk upgrade --no-cache --available \
    && apk add --no-cache \
      chromium-swiftshader \
      ttf-freefont \
      font-noto-emoji \
    && apk add --no-cache \
      --repository="$COMMUNITY_REPO" \
      font-wqy-zenhei

COPY local.conf /etc/fonts/local.conf

# Add Chrome as a user
RUN mkdir -p /usr/src/app \
    && adduser -D chrome \
    && chown -R chrome:chrome /usr/src/app
# Run Chrome as non-privileged
USER chrome
WORKDIR /usr/src/app

ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/

# Autorun chrome headless
ENV CHROMIUM_FLAGS="--disable-software-rasterizer --disable-dev-shm-usage"
ENTRYPOINT ["chromium-browser"]

FROM chrome AS release
WORKDIR /app
USER root
ARG USE_CHINA_MIRROR
ARG ENABLE_NOVNC
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then COMMUNITY_REPO_BASE=https://mirrors.ustc.edu.cn/alpine; else COMMUNITY_REPO_BASE=https://dl-cdn.alpinelinux.org/alpine; fi \
    && ALPINE_VERSION=$(cut -d. -f1,2 /etc/alpine-release) \
    && COMMUNITY_REPO="$COMMUNITY_REPO_BASE/v${ALPINE_VERSION}/community" \
    && apk add --no-cache curl wget bash socat xvfb \
    && if [ "$ENABLE_NOVNC" = "true" ]; then apk add --no-cache x11vnc novnc websockify --repository="$COMMUNITY_REPO"; fi
RUN chown -R chrome /app ;
USER chrome
COPY --chown=chrome --from=build /app/node_modules node_modules
COPY --chown=chrome --from=build /app/index.ts /app/wrap.sh ./
RUN sed -i 's/\r$//' /app/wrap.sh \
    && mkdir /app/puppeteer \
    && chown chrome:chrome /app/puppeteer
VOLUME /app/puppeteer
EXPOSE 9222/tcp
ENV DISPLAY=:7 \
    ENABLE_NOVNC=${ENABLE_NOVNC} \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    XVFB_SCREEN=0 \
    XVFB_WHD=1336x768x24 \
    CHROME_DEBUG_PORT=9221 \
    DEVTOOLS_PORT=9222
#https://stackoverflow.com/questions/47088261/restarting-an-unhealthy-docker-container-based-on-healthcheck/64041910#64041910
#HEALTHCHECK --interval=5m --timeout=2m --start-period=45s \
#   CMD curl -f --retry 6 --max-time 5 --retry-delay 10 --retry-max-time 60 "http://localhost:8080/health" || bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'
ENTRYPOINT ["sh", "wrap.sh"]
