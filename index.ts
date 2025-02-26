import { launch, Launcher } from "chrome-launcher";
import fs from "fs";
import puppeteer from "rebrowser-puppeteer";

async function startBrowser() {
    if (fs.existsSync("/usr/bin/google-chrome")) {
        var exepath = "/usr/bin/google-chrome";
    } else if (fs.existsSync("/usr/bin/chromium-browser")) {
        var exepath = "/usr/bin/chromium-browser";
        // } else {
        //     if (process.platform === "win32") {
        //         var exepath = String.raw`D:\cli-tools\win64-991974\chrome-win\chrome.exe`;
    } else {
        var exepath = "D:\\Program\\Google\\Chrome\\Application\\chrome.exe";
    }
    const dataDir =
        process.platform === "win32" ? "./data/puppeteer" : "/app/puppeteer";
    try {
        const lstat = await fs.lstatSync(dataDir + "/SingletonLock");
        if (lstat.isSymbolicLink()) {
            fs.rmSync(dataDir + "/SingletonLock", { force: true });
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
    ];
    return await launch({
        ignoreDefaultFlags: true,
        port: 9221,
        userDataDir: dataDir,
        chromePath: exepath,
        chromeFlags,
    });
}

async function main() {
    const browser = await startBrowser();
    console.info(browser.port, browser.pid);
    const client = await puppeteer.connect({
        browserURL: `http://localhost:${browser.port}`,
    });
    console.info(await client.userAgent());
    console.info("Started debuggingPort: 9222");
    // while (browser.connected) {
    //     await new Promise((resolve) => setTimeout(resolve, 1000));
    //     console.info("Running...");
    // }
    // console.info("Disconnected");
}

main();
