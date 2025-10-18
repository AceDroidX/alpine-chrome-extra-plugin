FROM node:24.10-alpine AS base
WORKDIR /app
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
RUN npm install -g pnpm@10.18.3 && npm cache clean --force

FROM base AS build
COPY pnpm-lock.yaml ./
RUN pnpm fetch --prod
COPY . .
RUN pnpm install --offline --prod

# https://github.com/jlandure/alpine-chrome/blob/master/Dockerfile

FROM base AS chrome

# Installs latest Chromium package.
RUN apk upgrade --no-cache --available \
    && apk add --no-cache \
      chromium-swiftshader \
      ttf-freefont \
      font-noto-emoji \
    && apk add --no-cache \
      --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
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
ENTRYPOINT ["chromium-browser", "--headless"]

FROM chrome AS release
WORKDIR /app
USER root
RUN apk add --no-cache curl wget bash socat xvfb
RUN chown -R chrome /app ;
USER chrome
COPY --chown=chrome --from=build /app/node_modules node_modules
COPY --chown=chrome --from=build /app/index.ts /app/wrap.sh ./
RUN mkdir /app/puppeteer && chown chrome:chrome /app/puppeteer
VOLUME /app/puppeteer
EXPOSE 9222/tcp
ENV DISPLAY=:7
#https://stackoverflow.com/questions/47088261/restarting-an-unhealthy-docker-container-based-on-healthcheck/64041910#64041910
#HEALTHCHECK --interval=5m --timeout=2m --start-period=45s \
#   CMD curl -f --retry 6 --max-time 5 --retry-delay 10 --retry-max-time 60 "http://localhost:8080/health" || bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'
ENTRYPOINT ["sh", "wrap.sh"]