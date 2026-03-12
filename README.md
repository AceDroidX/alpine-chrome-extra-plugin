# alpine-chrome-extra-plugin
[alpine-chrome](https://github.com/Zenika/alpine-chrome) with [puppeteer-real-browser](https://github.com/ZFC-Digital/puppeteer-real-browser)

thanks [rebrowser-puppeteer](https://github.com/rebrowser/rebrowser-puppeteer)

Using socat to [fix --headless=new](https://github.com/Zenika/alpine-chrome/issues/225)

## Features

- Chrome runs inside `Xvfb` and is reachable with noVNC at `http://localhost:6080/vnc.html`
- Chrome DevTools remains reachable at `http://localhost:9222`
- Docker build can switch Alpine package sources with `USE_CHINA_MIRROR=true`

## Build

```bash
docker build -t alpine-chrome-extra-plugin .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true .
```

When `USE_CHINA_MIRROR=true`, the image build runs:

```sh
sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
```

## Run

```bash
docker run --rm -p 9222:9222 -p 6080:6080 alpine-chrome-extra-plugin
```

Open `http://localhost:6080/vnc.html` to view the browser.

## Compose

See `compose.example.yml`. Set `build.args.USE_CHINA_MIRROR` to `"true"` when building from domestic mirrors.
