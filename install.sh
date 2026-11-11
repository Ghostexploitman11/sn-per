
#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

log()  { echo -e "${GREEN}[+]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
fail() { echo -e "${RED}[-]${RESET} $1"; exit 1; }

# Root kontrolü
if [[ "$EUID" -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

run_root() {
    if [[ -n "$SUDO" ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Dizinler
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="/opt/security-tools"
BIN_DIR="/usr/local/bin"

# Orijinal SNIPER dosyasını bul
SNIPER_SCRIPT=""

for file in snıper2.sh sniper2.sh snıper.sh sniper.sh; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        SNIPER_SCRIPT="$SCRIPT_DIR/$file"
        break
    fi
done

[[ -n "$SNIPER_SCRIPT" ]] || fail \
    "Orijinal SNIPER dosyasi bulunamadi!"

SNIPER_SCRIPT="$(realpath "$SNIPER_SCRIPT")"

# Debian / Kali kontrolü
command -v apt-get >/dev/null 2>&1 || fail \
    "Bu installer Kali / Debian tabanli sistemler icindir."

log "Kurulum baslatiliyor..."

# ==========================================
# 1. SYSTEM REQUIREMENTS
# ==========================================

log "Sistem gereksinimleri yukleniyor..."

run_root apt-get update

run_root apt-get install -y \
    git curl wget \
    python3 python3-pip python3-venv python3-dev \
    perl ruby ruby-dev \
    build-essential \
    nmap nikto dirb \
    bundler \
    libwww-perl \
    liblwp-protocol-https-perl \
    libjson-perl \
    libxml-libxml-perl \
    libxml-simple-perl \
    libnet-ssleay-perl

# ==========================================
# 2. TOOL DIRECTORY
# ==========================================

run_root mkdir -p "$TOOLS_DIR"
run_root mkdir -p "$BIN_DIR"

# ==========================================
# 3. GIT CLONE FUNCTION
# ==========================================

clone_tool() {
    local repo="$1"
    local folder="$2"

    if [[ -d "$TOOLS_DIR/$folder/.git" ]]; then
        log "$folder zaten mevcut, guncelleniyor..."
        run_root git -C "$TOOLS_DIR/$folder" pull --ff-only \
            || warn "$folder guncellenemedi."
    else
        log "$folder indiriliyor..."
        run_root git clone --depth 1 "$repo" "$TOOLS_DIR/$folder" \
            || warn "$folder indirilemedi."
    fi
}

# ==========================================
# 4. PYTHON TOOLS
# ==========================================

install_python_tool() {
    local name="$1"
    local package="$2"
    local venv="$TOOLS_DIR/venvs/$name"

    log "$name kuruluyor..."

    run_root mkdir -p "$TOOLS_DIR/venvs"

    if [[ ! -x "$venv/bin/python" ]]; then
        run_root python3 -m venv "$venv" \
            || { warn "$name sanal ortami olusturulamadi."; return 0; }
    fi

    run_root "$venv/bin/pip" install --upgrade pip \
        || warn "$name pip guncellenemedi."

    run_root "$venv/bin/pip" install "$package" \
        || warn "$name Python paketi kurulamadi."
}

install_python_tool "parsero" "parsero"
install_python_tool "plecost" "plecost"

# ==========================================
# 5. PARSERO
# ==========================================

cat > /tmp/parsero-launcher <<'EOF'
#!/usr/bin/env bash
exec /opt/security-tools/venvs/parsero/bin/parsero "$@"
EOF

run_root install -m 755 /tmp/parsero-launcher "$BIN_DIR/parsero"

# ==========================================
# 6. PLECOST
# ==========================================

cat > /tmp/plecost-launcher <<'EOF'
#!/usr/bin/env bash
exec /opt/security-tools/venvs/plecost/bin/plecost "$@"
EOF

run_root install -m 755 /tmp/plecost-launcher "$BIN_DIR/plecost"

# ==========================================
# 7. FIMAP
# ==========================================

clone_tool \
    "https://github.com/kurobeats/fimap.git" \
    "fimap"

cat > /tmp/fimap-launcher <<'EOF'
#!/usr/bin/env bash
cd /opt/security-tools/fimap

if command -v python2 >/dev/null 2>&1; then
    exec python2 fimap.py "$@"
else
    exec python3 fimap.py "$@"
fi
EOF

run_root install -m 755 /tmp/fimap-launcher "$BIN_DIR/fimap"

# ==========================================
# 8. UA-TESTER
# ==========================================

clone_tool \
    "https://github.com/amenezes/ua-tester.git" \
    "ua-tester"

if [[ -f "$TOOLS_DIR/ua-tester/Gemfile" ]]; then
    log "UA-Tester Ruby bagimliliklari kuruluyor..."

    (
        cd "$TOOLS_DIR/ua-tester"
        run_root bundle config set --local path vendor/bundle
        run_root bundle install
    ) || warn "UA-Tester bagimliliklari kurulamadi."
fi

cat > /tmp/ua-tester-launcher <<'EOF'
#!/usr/bin/env bash
cd /opt/security-tools/ua-tester
exec bundle exec ruby ua-tester.rb "$@"
EOF

run_root install -m 755 /tmp/ua-tester-launcher "$BIN_DIR/ua-tester"

# ==========================================
# 9. JOOMSCAN
# ==========================================

clone_tool \
    "https://github.com/rezasp/joomscan.git" \
    "joomscan"

cat > /tmp/joomscan-launcher <<'EOF'
#!/usr/bin/env bash
cd /opt/security-tools/joomscan
exec perl joomscan.pl "$@"
EOF

run_root install -m 755 /tmp/joomscan-launcher "$BIN_DIR/joomscan"

# ==========================================
# 10. UNISCAN
# ==========================================

clone_tool \
    "https://github.com/poerschke/Uniscan.git" \
    "Uniscan"

cat > /tmp/uniscan-launcher <<'EOF'
#!/usr/bin/env bash
cd /opt/security-tools/Uniscan
exec perl uniscan.pl "$@"
EOF

run_root install -m 755 /tmp/uniscan-launcher "$BIN_DIR/uniscan"

# ==========================================
# 11. DEBLAZE
# ==========================================

clone_tool \
    "https://github.com/SpiderLabs/deblaze.git" \
    "deblaze"

cat > /tmp/deblaze-launcher <<'EOF'
#!/usr/bin/env bash
cd /opt/security-tools/deblaze

for file in deblaze.py deblaze deblaze.sh main.py; do
    if [[ -f "$file" ]]; then
        case "$file" in
            *.py) exec python3 "$file" "$@" ;;
            *.sh) exec bash "$file" "$@" ;;
            *)    exec "./$file" "$@" ;;
        esac
    fi
done

echo "DeBlaze dosyalari indirildi ancak calistirilabilir giris dosyasi bulunamadi."
echo "Proje dizini: /opt/security-tools/deblaze"
exit 1
EOF

run_root install -m 755 /tmp/deblaze-launcher "$BIN_DIR/deblaze"

# ==========================================
# 12. APACHE USERS
# ==========================================

log "Apache Users paketi deneniyor..."

if run_root apt-get install -y apache-users; then
    log "Apache Users kuruldu."
else
    warn "Apache Users paketi depolarda bulunamadi."
fi

# ==========================================
# 13. ORIGINAL SNIPER GLOBAL COMMAND
# ==========================================

log "Orijinal SNIPER komutu ayarlaniyor..."

cat > /tmp/sniper-launcher <<EOF
#!/usr/bin/env bash
cd "$SCRIPT_DIR"
exec /usr/bin/env bash "$SNIPER_SCRIPT" "\$@"
EOF

run_root install -m 755 /tmp/sniper-launcher "$BIN_DIR/snıper"

run_root ln -sf "$BIN_DIR/snıper" "$BIN_DIR/sniper"

# ==========================================
# 14. CLEANUP
# ==========================================

rm -f /tmp/parsero-launcher
rm -f /tmp/plecost-launcher
rm -f /tmp/fimap-launcher
rm -f /tmp/ua-tester-launcher
rm -f /tmp/joomscan-launcher
rm -f /tmp/uniscan-launcher
rm -f /tmp/deblaze-launcher
rm -f /tmp/sniper-launcher

echo
log "KURULUM TAMAMLANDI!"
echo
echo "SNIPER:"
echo "  snıper"
echo "  sniper"
echo
echo "Kurulan araclar:"
echo "  Parsero"
echo "  Plecost"
echo "  Fimap"
echo "  UA-Tester"
echo "  JoomScan"
echo "  Uniscan"
echo "  DeBlaze (kaynak kod)"
echo "  Nmap"
echo "  Nikto"
echo "  DIRB"
echo "  Apache Users (paket mevcutsa)"
echo
