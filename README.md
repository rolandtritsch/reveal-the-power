# The Power of Why

An org-mode Reveal.js presentation about helping people connect their work to
something they care about.

The canonical source is `slides/why-slides.org`. The published browser
entrypoint is `public/why.html` so existing links to the old deck keep working.

## Prerequisites

- Emacs with org-mode and org-re-reveal available
- Node.js with Puppeteer available globally (`npm install -g puppeteer`)
- LaTeX tooling if document PDF targets are added later

## Usage

```sh
make publish
```

`make publish` builds:

- `public/why.html`
- `public/why-slides.pdf`
- `public/why-slides_with-notes.pdf`

GitHub Actions runs the same publish target on pushes to `trunk` and deploys
`public/` to GitHub Pages.
