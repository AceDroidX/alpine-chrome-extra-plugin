import { launch, Launcher } from "chrome-launcher";
import fs from "fs";
import http from "http";
import net from "net";
import path from "path";
import puppeteer from "rebrowser-puppeteer";
import { fileURLToPath } from "url";

const chromeDebugPort = Number(process.env.CHROME_DEBUG_PORT ?? 9221);
const devtoolsPort = Number(process.env.DEVTOOLS_PORT ?? 9222);
const healthPort = Number(process.env.HEALTH_PORT ?? 3000);
const chromeWindowSize = process.env.CHROME_WINDOW_SIZE ?? "1336,768";
const appRoot =
    process.env.APP_ROOT ?? path.dirname(fileURLToPath(import.meta.url));

async function startBrowser() {
    if (fs.existsSync("/usr/bin/google-chrome")) {
        var exepath = "/usr/bin/google-chrome";
    } else if (fs.existsSync("/usr/bin/chromium")) {
        var exepath = "/usr/bin/chromium";
    } else if (fs.existsSync("/usr/bin/chromium-browser")) {
        var exepath = "/usr/bin/chromium-browser";
        // } else {
        //     if (process.platform === "win32") {
        //         var exepath = String.raw`D:\cli-tools\win64-991974\chrome-win\chrome.exe`;
    } else {
        var exepath = "D:\\Program\\Google\\Chrome\\Application\\chrome.exe";
    }
    const dataDir =
        process.platform === "win32"
            ? path.join(appRoot, "data", "puppeteer")
            : path.join(appRoot, "puppeteer");
    const singletonLockPath = path.join(dataDir, "SingletonLock");

    fs.mkdirSync(dataDir, { recursive: true });

    try {
        const lstat = fs.lstatSync(singletonLockPath);
        if (lstat.isSymbolicLink()) {
            fs.rmSync(singletonLockPath, { force: true });
            console.info("Removed SingletonLock");
        }
    } catch (e) {
        console.info("No SingletonLock");
    }

    // Default flags: https://github.com/GoogleChrome/chrome-launcher/blob/main/src/flags.ts
    const flags = Launcher.defaultFlags();
    // Add AutomationControlled to "disable-features" flag
    const indexDisableFeatures = flags.findIndex((flag) =>
        flag.startsWith("--disable-features")
    );
    flags[
        indexDisableFeatures
    ] = `${flags[indexDisableFeatures]},AutomationControlled`;
    // Remove "disable-component-update" flag
    const indexComponentUpdateFlag = flags.findIndex((flag) =>
        flag.startsWith("--disable-component-update")
    );
    flags.splice(indexComponentUpdateFlag, 1);
    const chromeFlags = [
        ...flags,
        // "--headless=new",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        `--window-size=${chromeWindowSize}`,
    ];
    return await launch({
        ignoreDefaultFlags: true,
        port: chromeDebugPort,
        userDataDir: dataDir,
        chromePath: exepath,
        chromeFlags,
    });
}

function startHealthServer(
    browser: Awaited<ReturnType<typeof launch>>,
    client: Awaited<ReturnType<typeof puppeteer.connect>>
) {
    const server = http.createServer(async (req, res) => {
        if (req.url === "/healthz") {
            try {
                const checks: Record<string, boolean> = {
                    chromeProcess: browser.pid > 0,
                    puppeteerConnected: client.connected,
                    devtoolsPort: false,
                };

                // Check if Chrome DevTools port is accessible
                try {
                    const socket = new net.Socket();
                    await new Promise<void>((resolve, reject) => {
                        socket.setTimeout(2000);
                        socket.on("connect", () => {
                            checks.devtoolsPort = true;
                            socket.destroy();
                            resolve();
                        });
                        socket.on("timeout", () => {
                            socket.destroy();
                            reject(new Error("timeout"));
                        });
                        socket.on("error", reject);
                        socket.connect(chromeDebugPort, "localhost");
                    });
                } catch {
                    checks.devtoolsPort = false;
                }

                // Check if Puppeteer can actually execute commands
                let page: Awaited<ReturnType<typeof client.newPage>> | null = null;
                try {
                    page = await client.newPage();
                    const result = await page.evaluate(() => 1 + 1);
                    checks.puppeteerExec = result === 2;
                } catch {
                    checks.puppeteerExec = false;
                } finally {
                    if (page) await page.close().catch(() => {});
                }

                const healthy =
                    checks.chromeProcess &&
                    checks.puppeteerConnected &&
                    checks.devtoolsPort &&
                    checks.puppeteerExec;

                res.writeHead(healthy ? 200 : 503, {
                    "Content-Type": "application/json",
                });
                res.end(
                    JSON.stringify({
                        status: healthy ? "ok" : "degraded",
                        checks,
                    })
                );
            } catch (error) {
                res.writeHead(503, { "Content-Type": "application/json" });
                res.end(
                    JSON.stringify({
                        status: "error",
                        error: error instanceof Error ? error.message : "Unknown error",
                    })
                );
            }
        } else {
            res.writeHead(404);
            res.end("Not Found");
        }
    });

    server.listen(healthPort, () => {
        console.info(`Health check server listening on port ${healthPort}`);
    });

    return server;
}

async function main() {
    const browser = await startBrowser();
    console.info(browser.port, browser.pid);
    const client = await puppeteer.connect({
        browserURL: `http://localhost:${browser.port}`,
    });
    console.info(await client.userAgent());
    console.info(`Started debuggingPort: ${devtoolsPort}`);
    
    startHealthServer(browser, client);
}

main();
