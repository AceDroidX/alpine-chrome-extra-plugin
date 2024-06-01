import fs from "fs";
import puppeteer from "puppeteer-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";

async function getBrowser() {
    puppeteer.use(StealthPlugin());
    console.info("Using StealthPlugin");
    if (fs.existsSync("/usr/bin/google-chrome")) {
        var exepath = "/usr/bin/google-chrome";
    } else if (fs.existsSync("/usr/bin/chromium-browser")) {
        var exepath = "/usr/bin/chromium-browser";
        // } else {
        //     if (process.platform === "win32") {
        //         var exepath = String.raw`D:\cli-tools\win64-991974\chrome-win\chrome.exe`;
    } else {
        var exepath = "";
    }
    return await puppeteer.launch({
        // pipe: true,
        userDataDir:
            process.platform === "win32"
                ? "./data/puppeteer"
                : "/app/puppeteer",
        executablePath: exepath,
        // args: ['--no-sandbox', "--single-process", "--no-zygote", '--disable-dev-shm-usage'],
        // args: ['--no-sandbox', '--disable-setuid-sandbox',
        //   '--disable-dev-shm-usage', '--single-process',"--no-zygote"],
        args: [
            "--remote-debugging-port=9221",
            "--remote-debugging-address=0.0.0.0",
            "--no-sandbox",
            "--disable-dev-shm-usage",
        ],
        headless: true,
    });
}

async function main() {
    const browser = await getBrowser();
    console.info(await browser.userAgent());
    console.info("Started debuggingPort: 9222");
    // while (browser.connected) {
    //     await new Promise((resolve) => setTimeout(resolve, 1000));
    //     console.info("Running...");
    // }
    // console.info("Disconnected");
}

main();
