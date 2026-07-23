#!/bin/bash

# ============================================================
#  setup.sh — Inisialisasi repository GitHub Pages untuk tardi77
#  Jalankan sekali saja di awal
#  Penggunaan: chmod +x setup.sh && ./setup.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[38;5;178m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${GOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║${NC}  ${BOLD}Setup GitHub Pages${NC} — ${GOLD}tardi77${NC}                       ${GOLD}║${NC}"
echo -e "${GOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""

REPO_NAME="tardi77.github.io"

# Step 1
echo -e "  ${CYAN}[1/6]${NC} Membuat repository di GitHub..."
echo ""
echo -e "  ${YELLOW}Pilih salah satu:${NC}"
echo "    a) Repository sudah ada → tekan Enter"
echo "    b) Buat baru via gh cli  → ketik 'new'"
read -p "  Pilihan [Enter/new]: " CHOICE

if [ "$CHOICE" = "new" ]; then
  if command -v gh &> /dev/null; then
    gh repo create "$REPO_NAME" --public --description "Personal website of tardi77" --clone=false
    echo -e "  ${GREEN}✔${NC} Repository '$REPO_NAME' dibuat"
  else
    echo -e "  ${RED}✖${NC} gh CLI tidak tersedia. Buat manual di:"
    echo "    https://github.com/new"
    exit 1
  fi
else
  echo -e "  ${GREEN}✔${NC} Skip — menggunakan repository yang sudah ada"
fi

# Step 2
echo ""
echo -e "  ${CYAN}[2/6]${NC} Menginisialisasi git lokal..."
if [ ! -d ".git" ]; then
  git init
  git checkout -b main
  echo -e "  ${GREEN}✔${NC} Git diinisialisasi (branch: main)"
else
  echo -e "  ${GREEN}✔${NC} Git sudah terinisialisasi"
fi

# Step 3
echo ""
echo -e "  ${CYAN}[3/6]${NC} Menghubungkan remote..."
if ! git remote get-url origin &> /dev/null; then
  git remote add origin "https://github.com/tardi77/$REPO_NAME.git"
  echo -e "  ${GREEN}✔${NC} Remote ditambahkan"
else
  CURRENT_REMOTE=$(git remote get-url origin)
  git remote set-url origin "https://github.com/tardi77/$REPO_NAME.git"
  echo -e "  ${GREEN}✔${NC} Remote diperbarui ($CURRENT_REMOTE → origin)"
fi

# Step 4
echo ""
echo -e "  ${CYAN}[4/6]${NC} Membuat struktur GitHub Actions..."
mkdir -p .github/workflows

if [ ! -f ".github/workflows/deploy.yml" ]; then
  cat > .github/workflows/deploy.yml << 'YAML_EOF'
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: "pages"
  cancel-in-progress: false
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: "."
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
YAML_EOF
  echo -e "  ${GREEN}✔${NC} .github/workflows/deploy.yml dibuat"
else
  echo -e "  ${GREEN}✔${NC} Workflow sudah ada, skip"
fi

# Step 5
echo ""
echo -e "  ${CYAN}[5/6]${NC} Commit awal..."
git add -A
git commit -m "feat: initial commit — personal website" --allow-empty 2>/dev/null || true
echo -e "  ${GREEN}✔${NC} Commit dibuat"

# Step 6
echo ""
echo -e "  ${CYAN}[6/6]${NC} Push ke GitHub..."
echo -e "  ${YELLOW}Menjalankan: git push -u origin main${NC}"
echo ""
git push -u origin main
echo -e "  ${GREEN}✔${NC} Push berhasil!"

# Final
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Setup Selesai!${NC} 🎉                                  ${GREEN}║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Langkah selanjutnya:                            ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  1. Buka: ${CYAN}https://github.com/tardi77/${REPO_NAME}${NC}    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  2. Masuk ke ${BOLD}Settings → Pages${NC}                    ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  3. Source: pilih ${BOLD}GitHub Actions${NC}                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  4. Tunggu deploy selesai (±1 menit)              ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  5. Buka: ${CYAN}https://tardi77.github.io${NC}              ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
