#!/bin/bash

# ============================================================
#  deploy.sh — GitHub Pages Deploy Script untuk tardi77
#  Penggunaan: chmod +x deploy.sh && ./deploy.sh
# ============================================================

set -e  # Hentikan jika ada error

# ---------- KONFIGURASI ----------
REPO="tardi77/tardi77.github.io"
BRANCH="main"
DEPLOY_DIR=".deploy"
BUILD_FILE="index.html"

# ---------- WARNA ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GOLD='\033[38;5;178m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ---------- HELPER FUNCTIONS ----------
print_header() {
  echo ""
  echo -e "${GOLD}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${GOLD}║${NC}  ${BOLD}GitHub Pages Deploy${NC} — ${GOLD}tardi77${NC}                    ${GOLD}║${NC}"
  echo -e "${GOLD}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_step() {
  echo -e "  ${CYAN}▶${NC} $1"
}

print_success() {
  echo -e "  ${GREEN}✔${NC} $1"
}

print_warning() {
  echo -e "  ${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "  ${RED}✖${NC} $1"
}

print_divider() {
  echo -e "  ${GOLD}─────────────────────────────────────────${NC}"
}

# ---------- PRE-CHECKS ----------
print_header

# Cek git
print_step "Memeriksa instalasi Git..."
if ! command -v git &> /dev/null; then
  print_error "Git tidak terinstall. Install terlebih dahulu:"
  echo "    sudo apt install git        # Debian/Ubuntu"
  echo "    brew install git            # macOS"
  exit 1
fi
print_success "Git terdeteksi: $(git --version)"

# Cek file build
print_step "Memeriksa file build..."
if [ ! -f "$BUILD_FILE" ]; then
  print_error "File '$BUILD_FILE' tidak ditemukan di direktori saat ini."
  echo "    Pastikan kamu berada di folder yang berisi $BUILD_FILE"
  exit 1
fi
FILE_SIZE=$(du -h "$BUILD_FILE" | cut -f1)
print_success "File ditemukan: $BUILD_FILE ($FILE_SIZE)"

# Cek authentication
print_step "Memeriksa autentikasi GitHub..."
GH_USER=$(gh auth status 2>&1 | grep "Logged in to" | head -1 || echo "")
if [ -z "$GH_USER" ]; then
  print_warning "GitHub CLI tidak login. Mencoba fallback ke SSH..."
  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    print_success "SSH authentication terdeteksi"
  else
    print_warning "SSH juga belum dikonfigurasi."
    echo ""
    echo -e "    ${BOLD}Cara login:${NC}"
    echo "    gh auth login                  # GitHub CLI (direkomendasikan)"
    echo "    atau setup SSH key:"
    echo "    ssh-keygen -t ed25519 -C 'your@email.com'"
    echo "    gh ssh-key add ~/.ssh/id_ed25519.pub"
    exit 1
  fi
else
  print_success "$GH_USER"
fi

# ---------- BUILD ----------
print_divider
print_step "Menyiapkan direktori deploy..."

# Bersihkan deploy sebelumnya
if [ -d "$DEPLOY_DIR" ]; then
  rm -rf "$DEPLOY_DIR"
  print_success "Direktori lama dibersihkan"
fi

mkdir -p "$DEPLOY_DIR"
cp "$BUILD_FILE" "$DEPLOY_DIR/"
print_success "File disalin ke $DEPLOY_DIR/"

# ---------- DEPLOY ----------
print_divider
print_step "Memulai deploy ke GitHub Pages..."

cd "$DEPLOY_DIR"

# Inisialisasi git jika belum ada
git init
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# Konfigurasi user (opsional, override jika belum set)
if [ -z "$(git config user.name)" ]; then
  git config user.name "tardi77"
  git config user.email "tardi77@users.noreply.github.com"
  print_success "Git user dikonfigurasi"
fi

# Tambah remote jika belum ada
if ! git remote get-url origin &> /dev/null; then
  git remote add origin "https://github.com/$REPO.git"
  print_success "Remote ditambahkan: $REPO"
else
  git remote set-url origin "https://github.com/$REPO.git"
  print_success "Remote diperbarui: $REPO"
fi

# Fetch & reset ke remote
git fetch origin "$BRANCH" 2>/dev/null || true
git reset "origin/$BRANCH" 2>/dev/null || true

# Copy ulang file (setelah reset)
cp "../$BUILD_FILE" "./"

# Commit & Push
git add -A
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M:%S') — $(git rev-parse --short HEAD 2>/dev/null || echo 'init')" --allow-empty

print_step "Pushing ke $BRANCH..."
if git push -f origin "$BRANCH" 2>&1; then
  print_success "Push berhasil!"
else
  print_error "Push gagal. Coba manual:"
  echo "    cd $DEPLOY_DIR && git push -f origin $BRANCH"
  cd ..
  exit 1
fi

cd ..

# ---------- CLEANUP ----------
print_divider
print_step "Membersihkan file sementara..."
rm -rf "$DEPLOY_DIR"
print_success "Cleanup selesai"

# ---------- DONE ----------
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  ${BOLD}Deploy Berhasil!${NC} 🚀                              ${GREEN}║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  URL:  ${CYAN}https://tardi77.github.io${NC}              ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Branch:  ${GOLD}$BRANCH${NC}                                 ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  Waktu:  $(date '+%Y-%m-%d %H:%M:%S')              ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  ${YELLOW}Note: Propagasi CDN butuh 1-5 menit${NC}          ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                  ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
