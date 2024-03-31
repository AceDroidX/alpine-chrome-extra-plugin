ARG IMAGE_TAG=dev

FROM node:18-alpine AS build
WORKDIR /app
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
RUN npm install -g pnpm@8.15.5 && npm cache clean --force
COPY pnpm-lock.yaml ./
RUN pnpm fetch
COPY package.json tsconfig.json index.ts ./
RUN pnpm install --offline
RUN pnpm run build

FROM zenika/alpine-chrome:123
WORKDIR /app
ENV TZ=Asia/Shanghai \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome
USER root
RUN apk add --no-cache nodejs npm socat
RUN chown -R chrome /app ; npm install -g pnpm@8.15.5 && npm cache clean --force
USER chrome
COPY --chown=chrome pnpm-lock.yaml ./
RUN pnpm fetch --prod
COPY --chown=chrome package.json wrap.sh ./
COPY --from=build --chown=chrome /app/dist/ ./dist/
RUN mkdir /app/puppeteer && chown chrome:chrome /app/puppeteer
VOLUME /app/puppeteer
RUN pnpm install --offline --prod
EXPOSE 9222
ENTRYPOINT ["sh", "wrap.sh"]
