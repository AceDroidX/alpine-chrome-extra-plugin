# alpine-chrome-extra-plugin
[alpine-chrome](https://github.com/Zenika/alpine-chrome) with [puppeteer-real-browser](https://github.com/ZFC-Digital/puppeteer-real-browser)

thanks [rebrowser-puppeteer](https://github.com/rebrowser/rebrowser-puppeteer)

Using socat to [fix --headless=new](https://github.com/Zenika/alpine-chrome/issues/225)

## Features

- Chrome can optionally expose noVNC at `http://localhost:6080/vnc.html`
- Chrome DevTools remains reachable at `http://localhost:9222`
- Docker build can switch Alpine package sources with `USE_CHINA_MIRROR=true`
- Docker build enables noVNC only when `ENABLE_NOVNC=true`

## Build

```bash
docker build -t alpine-chrome-extra-plugin .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true .
docker build -t alpine-chrome-extra-plugin --build-arg ENABLE_NOVNC=true .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true --build-arg ENABLE_NOVNC=true .
```

When `USE_CHINA_MIRROR=true`, the image build runs:

```sh
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
```

## Run

```bash
docker run --rm -p 9222:9222 alpine-chrome-extra-plugin
docker run --rm -p 9222:9222 -p 6080:6080 alpine-chrome-extra-plugin
```

Only the image built with `ENABLE_NOVNC=true` serves noVNC. Then open `http://localhost:6080/vnc.html` to view the browser.

## Compose

See `compose.example.yml`. Set `build.args.USE_CHINA_MIRROR` to `"true"` when building from domestic mirrors, and set `build.args.ENABLE_NOVNC` to `"true"` when you want the VNC stack installed.
