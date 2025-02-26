# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
WORKDIR /app
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

# install dependencies into temp directory
# this will cache them and speed up future builds
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lockb /temp/dev/
# RUN cd /temp/dev && bunx prisma
RUN cd /temp/dev && bun install --frozen-lockfile

# install with --production (exclude devDependencies)
RUN mkdir -p /temp/prod
COPY package.json bun.lockb /temp/prod/
RUN cd /temp/prod && bun install --frozen-lockfile --production

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .

# [optional] tests & build
ENV NODE_ENV=production
# RUN bun test
# RUN bun run build
# RUN bun x prisma generate

# https://github.com/jlandure/alpine-chrome/blob/master/Dockerfile

FROM alpine:3.21.3 AS chrome

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
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
# Disable the runtime transpiler cache by default inside Docker containers.
# On ephemeral containers, the cache is not useful
ARG BUN_RUNTIME_TRANSPILER_CACHE_PATH=0
ENV BUN_RUNTIME_TRANSPILER_CACHE_PATH=${BUN_RUNTIME_TRANSPILER_CACHE_PATH}
# Ensure `bun install -g` works
# ARG BUN_INSTALL_BIN=/usr/local/bin
# ENV BUN_INSTALL_BIN=${BUN_INSTALL_BIN}
USER root
RUN apk add --no-cache curl wget bash socat
# https://github.com/oven-sh/bun/blob/main/dockerhub/alpine/Dockerfile
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.34-r0/glibc-2.34-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.34-r0/glibc-bin-2.34-r0.apk && \
    apk --no-cache --force-overwrite --allow-untrusted add glibc-2.34-r0.apk glibc-bin-2.34-r0.apk && \
    rm glibc-2.34-r0.apk glibc-bin-2.34-r0.apk
RUN chown -R chrome /app ;
USER chrome
RUN curl -fsSL https://bun.sh/install | bash
COPY --chown=chrome --from=install /temp/prod/node_modules node_modules
COPY --chown=chrome --from=prerelease /app/index.ts /app/wrap.sh ./
RUN mkdir /app/puppeteer && chown chrome:chrome /app/puppeteer
VOLUME /app/puppeteer
EXPOSE 9222/tcp
#https://stackoverflow.com/questions/47088261/restarting-an-unhealthy-docker-container-based-on-healthcheck/64041910#64041910
#HEALTHCHECK --interval=5m --timeout=2m --start-period=45s \
#   CMD curl -f --retry 6 --max-time 5 --retry-delay 10 --retry-max-time 60 "http://localhost:8080/health" || bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'
ENTRYPOINT ["sh", "wrap.sh"]