#!/bin/bash
# Full pipeline: org -> PDF -> public/
# Usage: build-doc.sh <file-doc.org>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FILE="$(realpath "$1")"
BASE="${FILE%.org}"
PDF="${BASE}.pdf"
TEX="${BASE}.tex"
PUBLIC="${REPO_ROOT}/public"

# 1. Generate PDF via LaTeX
echo "  Generating PDF from ${FILE}"
emacs --batch -Q \
    --eval "(setq package-user-dir (expand-file-name \"~/.emacs.d/elpa\"))" \
    --eval "(package-initialize)" \
    --eval "(require 'org)" \
    --eval "(require 'ox-latex)" \
    --visit "${FILE}" \
    --eval "(save-excursion (goto-char (point-min)) (while (re-search-forward \"{{{time(%Y-%m-%d %H:%M:%S)}}}\" nil t) (replace-match (format-time-string \"%Y-%m-%d %H:%M:%S\"))))" \
    --eval "(condition-case err (org-latex-export-to-pdf) (error (message \"Error exporting %s: %s\" \"${FILE}\" err) (kill-emacs 1)))" \
    2>/dev/null

# 2. Move to public/
mkdir -p "${PUBLIC}"
mv "${PDF}" "${PUBLIC}/"
mv "${TEX}" "${PUBLIC}/"
