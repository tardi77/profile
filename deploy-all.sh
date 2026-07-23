#!/bin/bash

# ============================================================
#  deploy-all.sh — All-in-One Deploy Tool untuk tardi77
#  Penggunaan:
#    ./deploy-all.sh setup     → Inisialisasi awal
#    ./deploy-all.sh deploy    → Deploy manual
#    ./deploy-all.sh status    → Cek status
#    ./deploy-all.sh logs      → Lihat deploy logs
#    ./deploy-all.sh rollback  → Kembali ke versi sebelumnya
# ============================================================

set -e

# ---------- CONFIG ----------
REPO="tardi77/tardi77.github.io"
BRANCH="main"
BUILD_FILE="index.html"
DEPLOY_DIR=".deploy"
HISTORY_FILE=".deploy-history.log"

# ---------- COLORS ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
GOLD='\033[38;5;178m'; CYAN='\033[0;36m'; DIM='\033[2m'
NC='\033[0m'; BOLD='\033[1m'

log()    { echo -e "  ${CYAN}▶${NC} $1"; }
ok()     { echo -e "  ${GREEN}✔${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()    { echo -e "  ${RED}✖${NC} $1"; }
line()   { echo -e "  ${GOLD}─────────────────────────────────────────${NC}"; }
header() {
  echo ""
  echo -e "${GOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${GOLD}║${NC}  ${BOLD}$1${NC}"
  echo -e "${GOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}
save_history() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $1 | $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')" >> "$HISTORY_FILE"
}

# ---------- COMMAND: SETUP ----------
cmd_setup() {
  header "Setup GitHub Pages — tardi77"

  log "Membuat struktur workflow..."
  mkdir -p .github/workflows

  cat > .github/workflows/deploy.yml << 'EOF'
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
  group: pages
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
EOF

  ok "Workflow dibuat: .github/workflows/deploy.yml"

  if [ ! -d ".git" ]; then
    log "Inisialisasi git..."
    git init
    git checkout -b "$BRANCH"
    ok "Git initialized (branch: $BRANCH)"
  else
    ok "Git sudah ada"
  fi

  if ! git remote get-url origin &> /dev/null; then
    git remote add origin "https://github.com/$REPO.git"
    ok "Remote: $REPO"
  fi

  log "Commit awal..."
  git add -A
  git commit -m "chore: initial setup with GitHub Actions" --allow-empty 2>/dev/null || true
  ok "Siap di-push"

  echo ""
  warn "Jalankan './deploy-all.sh deploy' untuk push & deploy"
  echo ""
  echo -e "  ${DIM}Atau aktifkan GitHub Pages manual:${NC}"
  echo "  Settings → Pages → Source: GitHub Actions"
  echo ""
}

# ---------- COMMAND: DEPLOY ----------
cmd_deploy() {
  header "Deploy — tardi77"

  # Pre-check
  [ ! -f "$BUILD_FILE" ] && { err "File '$BUILD_FILE' tidak ditemukan!"; exit 1; }
  ok "Build file: $BUILD_FILE ($(du -h "$BUILD_FILE" | cut -f1))"

  # Push
  log "Staging changes..."
  git add -A
  CHANGES=$(git diff --cached --stat 2>/dev/null | tail -1)
  if [ -z "$CHANGES" ]; then
    warn "Tidak ada perubahan. Force deploy dengan --force? (y/N)"
    read -r CONFIRM
    [ "$CONFIRM" != "y" ] && { echo "  Dibatalkan."; exit 0; }
    git commit -m "deploy: force redeploy $(date '+%Y-%m-%d %H:%M:%S')" --allow-empty
  else
    ok "Perubahan: $CHANGES"
    git commit -m "deploy: $(date '+%Y-%m-%d %H:%M:%S')"
  fi

  log "Pushing ke $BRANCH..."
  git push origin "$BRANCH"
  ok "Push berhasil!"

  save_history "deploy"
  line

  echo -e "  ${GREEN}🚀 Deploy terkirim!${NC}"
  echo -e "  ${DIM}URL: https://tardi77.github.io${NC}"
  echo -e "  ${DIM}Actions: https://github.com/$REPO/actions${NC}"
  echo ""
}

# ---------- COMMAND: STATUS ----------
cmd_status() {
  header "Status — tardi77"

  # Git status
  log "Git status:"
  git status -sb 2>/dev/null | sed 's/^/    /' || warn "Bukan repo git"

  # Last commit
  echo ""
  log "Commit terakhir:"
  git log -1 --oneline --format="    %h | %s | %ar" 2>/dev/null || warn "N/A"

  # Remote
  echo ""
  log "Remote:"
  git remote -v 2>/dev/null | sed 's/^/    /' || warn "N/A"

  # Build file
  echo ""
  log "Build file:"
  if [ -f "$BUILD_FILE" ]; then
    SIZE=$(du -h "$BUILD_FILE" | cut -f1)
    LINES=$(wc -l < "$BUILD_FILE")
    MODIFIED=$(stat -c %y "$BUILD_FILE" 2>/dev/null || stat -f %Sm "$BUILD_FILE" 2>/dev/null)
    echo "    $BUILD_FILE — ${SIZE}, ${LINES} baris"
    echo "    Terakhir diubah: ${MODIFIED}"
  else
    warn "$BUILD_FILE tidak ditemukan"
  fi

  # Deploy history
  echo ""
  log "Riwayat deploy:"
  if [ -f "$HISTORY_FILE" ]; then
    tail -5 "$HISTORY_FILE" | sed 's/^/    /'
  else
    warn "Belum ada riwayat deploy"
  fi

  # GitHub Actions status
  echo ""
  log "GitHub Actions:"
  if command -v gh &> /dev/null; then
    gh run list --repo "$REPO" --limit 3 2>/dev/null | sed 's/^/    /' || warn "Tidak bisa mengakses"
  else
    warn "Install gh CLI untuk melihat status Actions"
  fi

  echo ""
}

# ---------- COMMAND: LOGS ----------
cmd_logs() {
  header "Deploy Logs — tardi77"

  if command -v gh &> /dev/null; then
    log "5 run terakhir:"
    gh run list --repo "$REPO" --limit 5
    echo ""
    log "Detail run terakhir:"
    gh run view --repo "$REPO" --log 2>/dev/null | tail -30 || warn "Tidak ada log"
  else
    if [ -f "$HISTORY_FILE" ]; then
      cat "$HISTORY_FILE"
    else
      warn "Tidak ada log. Install gh CLI untuk log GitHub Actions."
    fi
  fi
  echo ""
}

# ---------- COMMAND: ROLLBACK ----------
cmd_rollback() {
  header "Rollback — tardi77"

  log "Commit sebelumnya:"
  PREV=$(git log -2 --oneline | tail -1 | awk '{print $1}')
  git log -2 --oneline | sed 's/^/    /'

  echo ""
  warn "Rollback ke commit $PREV? (y/N)"
  read -r CONFIRM
  [ "$CONFIRM" != "y" ] && { echo "  Dibatalkan."; exit 0; }

  log "Resetting ke $PREV..."
  git reset --hard "$PREV"

  log "Force pushing..."
  git push -f origin "$BRANCH"

  save_history "rollback → $PREV"
  ok "Rollback berhasil!"
  echo ""
}

# ---------- COMMAND: HELP ----------
cmd_help() {
  header "Deploy Tool — tardi77"
  echo -e "  ${BOLD}Penggunaan:${NC}  ./deploy-all.sh <command>"
  echo ""
  echo -e "  ${GOLD}Commands:${NC}"
  echo "    setup      Inisialisasi repo & GitHub Actions workflow"
  echo "    deploy     Build & push ke GitHub Pages"
  echo "    status     Cek status repo, build file, dan Actions"
  echo "    logs       Lihat riwayat deploy & GitHub Actions logs"
  echo "    rollback   Kembali ke versi deploy sebelumnya"
  echo "    help       Tampilkan pesan ini"
  echo ""
  echo -e "  ${GOLD}Examples:${NC}"
  echo "    ./deploy-all.sh setup"
  echo "    ./deploy-all.sh deploy"
  echo "    ./deploy-all.sh status"
  echo ""
  echo -e "  ${DIM}Repository: https://github.com/$REPO${NC}"
  echo -e "  ${DIM}Site:       https://tardi77.github.io${NC}"
  echo ""
}

# ---------- ROUTER ----------
case "${1:-help}" in
  setup)    cmd_setup ;;
  deploy)   cmd_deploy ;;
  status)   cmd_status ;;
  logs)     cmd_logs ;;
  rollback) cmd_rollback ;;
  help|*)   cmd_help ;;
esac
