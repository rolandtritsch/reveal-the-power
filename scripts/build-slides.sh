#!/bin/bash
# Full pipeline: org -> HTML -> PDF + PDF-with-notes -> public/
# Usage: build-slides.sh <file-slides.org>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export NODE_PATH="$(npm root -g)"

FILE="$(realpath "$1")"
BASE="${FILE%.org}"
HTML="${BASE}.html"
PDF="${BASE}.pdf"
PDF_NOTES="${BASE}_with-notes.pdf"
PUBLIC="${REPO_ROOT}/public"
PUBLIC_HTML_NAME="${PUBLIC_HTML_NAME:-$(basename "${HTML}")}"

# 1. Generate HTML
echo "  Generating HTML from ${FILE}"
emacs --batch -Q \
    --eval "(add-to-list 'load-path (expand-file-name \"~/.emacs.d/lisp\"))" \
    --eval "(setq package-user-dir (expand-file-name \"~/.emacs.d/elpa\"))" \
    --eval "(package-initialize)" \
    --eval "(require 'org)" \
    --eval "(require 'org-re-reveal)" \
    --eval "(setq org-re-reveal-root \"https://cdn.jsdelivr.net/npm/reveal.js\")" \
    --visit "${FILE}" \
    --eval "(save-excursion (goto-char (point-min)) (while (re-search-forward \"{{{time(%Y-%m-%d_%H:%M:%S)}}}\" nil t) (replace-match (format-time-string \"%Y-%m-%d_%H:%M:%S\"))))" \
    --eval "(save-excursion (goto-char (point-min)) (while (re-search-forward \"{{{time(%Y-%m-%d %H:%M:%S)}}}\" nil t) (replace-match (format-time-string \"%Y-%m-%d %H:%M:%S\"))))" \
    --eval "(condition-case err (org-re-reveal-export-to-html) (error (message \"Error exporting %s: %s\" \"${FILE}\" err) (kill-emacs 1)))" \
    2>/dev/null

if [[ ! -s "${HTML}" ]]; then
    echo "  ERROR: emacs produced an empty file for ${FILE}" >&2
    exit 1
fi

# 2. Inject slide number style
sed -i 's|</head>|<style>.reveal .slide-number { right: auto; left: 0; width: 100%; text-align: center; background: transparent; color: #333; }</style>\n</head>|' "${HTML}"

# 3. Generate PDFs
echo "  Generating PDF from ${HTML}"
node "${SCRIPT_DIR}/print-slides.cjs" "file://${HTML}" "${PDF}"

echo "  Generating PDF with notes from ${HTML}"
node "${SCRIPT_DIR}/print-slides.cjs" "file://${HTML}" "${PDF_NOTES}" --notes

# 4. Move all artifacts to public/
mkdir -p "${PUBLIC}"
mv "${HTML}" "${PUBLIC}/${PUBLIC_HTML_NAME}"
mv "${PDF}" "${PUBLIC}/"
mv "${PDF_NOTES}" "${PUBLIC}/"
