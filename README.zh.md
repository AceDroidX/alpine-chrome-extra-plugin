# alpine-chrome-extra-plugin
[English](README.md) | **简体中文**

[alpine-chrome](https://github.com/Zenika/alpine-chrome) 风格的 Google Chrome 容器，基于 `node:24-trixie-slim`，并集成了 [puppeteer-real-browser](https://github.com/ZFC-Digital/puppeteer-real-browser)

感谢 [rebrowser-puppeteer](https://github.com/rebrowser/rebrowser-puppeteer)

通过 `socat` 解决 [--headless=new](https://github.com/Zenika/alpine-chrome/issues/225) 相关问题。

## 特性

- 可选开启 noVNC，通过 `http://localhost:6080/vnc.html` 访问浏览器界面
- 浏览器二进制来自 `https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb`
- Chrome DevTools 调试端口固定暴露在 `http://localhost:9222`
- 当 `USE_CHINA_MIRROR=true` 时，会切换 Debian apt 国内源
- 当 `USE_CHINA_MIRROR=true` 时，npm 和 pnpm 使用 `https://registry.npmmirror.com`
- 只有 `ENABLE_NOVNC=true` 时才会安装 noVNC 相关组件

## 构建

```bash
docker build -t alpine-chrome-extra-plugin .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true .
docker build -t alpine-chrome-extra-plugin --build-arg ENABLE_NOVNC=true .
docker build -t alpine-chrome-extra-plugin --build-arg USE_CHINA_MIRROR=true --build-arg ENABLE_NOVNC=true .
```

当 `USE_CHINA_MIRROR=true` 时，构建过程会将 Debian apt 源切换到 USTC，并把 npm 源切换到 `https://registry.npmmirror.com`：

```sh
sed -i 's|http://deb.debian.org/debian|http://mirrors.ustc.edu.cn/debian|g; s|http://deb.debian.org/debian-security|http://mirrors.ustc.edu.cn/debian-security|g' /etc/apt/sources.list.d/debian.sources
npm config set registry https://registry.npmmirror.com
```

## 运行

```bash
docker run --rm -p 9222:9222 your-user/alpine-chrome-extra-plugin:latest
docker run --rm -p 9222:9222 your-user/alpine-chrome-extra-plugin:default
docker run --rm -p 9222:9222 -p 6080:6080 your-user/alpine-chrome-extra-plugin:vnc
```

已发布标签说明：

- `:latest` 和 `:default` 为标准镜像，不包含 noVNC
- `:vnc` 为带 noVNC 的镜像，可访问 `http://localhost:6080/vnc.html`

## Compose

参见 `compose.example.yml`。如果你在国内网络环境构建，可将 `build.args.USE_CHINA_MIRROR` 设为 `"true"`；如果需要 noVNC，则将 `build.args.ENABLE_NOVNC` 设为 `"true"`。
