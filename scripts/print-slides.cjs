'use strict';
// Render a Reveal.js presentation to PDF via Puppeteer.
//
// Usage:
//   node print-slides.cjs <url> <output.pdf> [--notes]
//
// Without --notes: renders ?print-pdf             (slides only)
// With    --notes: renders ?print-pdf&showNotes=true (slides + speaker notes)

const puppeteer = require('puppeteer');

const args = process.argv.slice(2);
const notesFlag = args.includes('--notes');
const [baseUrl, output] = args.filter(a => !a.startsWith('--'));

const separator = baseUrl.includes('?') ? '&' : '?';
const url = baseUrl + separator + 'print-pdf' + (notesFlag ? '&showNotes=true' : '');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  // Wide landscape viewport so reveal's width:"80%" yields a landscape @page.
  await page.setViewport({ width: 1400, height: 900 });
  await page.emulateMediaType('screen');
  await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
  await page.waitForFunction(
    () => typeof Reveal !== 'undefined' && Reveal.isReady(),
    { timeout: 60000 },
  );
  // Reveal.js 5.x creates .pdf-page elements asynchronously (via requestAnimationFrame)
  // after isReady() fires. Wait until at least one .pdf-page exists before printing.
  await page.waitForFunction(
    () => document.querySelectorAll('.pdf-page').length > 0,
    { timeout: 60000 },
  );

  if (notesFlag) {
    // Reveal.js injects @page { size: <w>px <h>px } where h = one slide height.
    // For the notes layout (slide top-half, notes bottom-half) the page must be
    // 2× tall.  Double the @page height and all .pdf-page element heights.
    await page.evaluate(() => {
      let pageWidth = 1232, pageHeight = 728; // fallback defaults
      for (const s of document.styleSheets) {
        try {
          for (const r of s.cssRules) {
            if (r.type === CSSRule.PAGE_RULE) {
              const m = r.cssText.match(/size:\s*([\d.]+)px\s+([\d.]+)px/);
              if (m) { pageWidth = parseFloat(m[1]); pageHeight = parseFloat(m[2]); }
            }
          }
        } catch (_) {}
      }
      const doubleH = pageHeight * 2;
      const style = document.createElement('style');
      style.textContent = `@page { size: ${pageWidth}px ${doubleH}px !important; margin: 0; }`;
      document.head.appendChild(style);
      for (const pp of document.querySelectorAll('.pdf-page')) {
        pp.style.height = doubleH + 'px';
      }
    });
  }

  await page.pdf({ path: output, printBackground: true, preferCSSPageSize: true });
  await browser.close();
})();
