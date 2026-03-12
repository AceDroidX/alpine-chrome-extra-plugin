# alpine-chrome-extra-plugin
[alpine-chrome](https://github.com/Zenika/alpine-chrome) inspired Chromium container, now based on `node:24-trixie-slim`, with [puppeteer-real-browser](https://github.com/ZFC-Digital/puppeteer-real-browser)

thanks [rebrowser-puppeteer](https://github.com/rebrowser/rebrowser-puppeteer)

Using socat to [fix --headless=new](https://github.com/Zenika/alpine-chrome/issues/225)

## Features

- Chrome can optionally expose noVNC at `http://localhost:6080/vnc.html`
- Chrome DevTools remains reachable at `http://localhost:9222`
- Docker build can switch Debian package sources with `USE_CHINA_MIRROR=true`
- When `USE_CHINA_MIRROR=true`, npm and pnpm use `https://registry.npmmirror.com`
- Docker build enables noVNC only when `ENABLE_NOVNC=true`

## Build

```bash
docker build -t alpine-chrome-extra-plugin .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true .
docker build -t alpine-chrome-extra-plugin --build-arg ENABLE_NOVNC=true .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true --build-arg ENABLE_NOVNC=true .
```

When `USE_CHINA_MIRROR=true`, the image build rewrites Debian apt sources to USTC mirrors and switches npm to `https://registry.npmmirror.com`:

```sh
sed -i 's|http://deb.debian.org/debian|http://mirrors.ustc.edu.cn/debian|g; s|http://deb.debian.org/debian-security|http://mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources
npm config set registry https://registry.npmmirror.com
```

## Run

```bash
docker run --rm -p 9222:9222 alpine-chrome-extra-plugin
docker run --rm -p 9222:9222 -p 6080:6080 alpine-chrome-extra-plugin
```

Only the image built with `ENABLE_NOVNC=true` serves noVNC. Then open `http://localhost:6080/vnc.html` to view the browser.

## Compose

See `compose.example.yml`. Set `build.args.USE_CHINA_MIRROR` to `"true"` when building from domestic mirrors, and set `build.args.ENABLE_NOVNC` to `"true"` when you want the VNC stack installed.
