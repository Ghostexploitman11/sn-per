
#!/usr/bin/env bash

# ============================================================
#                    SNIPER2 v6.0
#                  NEON CYBER EDITION
# ============================================================
# Authorized security testing only.
# Bash 4+ recommended.
# ============================================================

set -o pipefail

VERSION="6.0"
REPORT_DIR="reports"
CONFIG_DIR="config"

mkdir -p "$REPORT_DIR" "$CONFIG_DIR"

# -------------------- NEON COLORS ---------------------------

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

GREEN='\033[38;5;46m'
CYAN='\033[38;5;51m'
BLUE='\033[38;5;39m'
PURPLE='\033[38;5;135m'
PINK='\033[38;5;201m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;244m'

# -------------------- GLOBAL STATE -------------------------

TARGET=""
TOOL=""
TOOL_NAME=""
BIN=""
CHOICE=""
LOGFILE=""

# -------------------- UI FUNCTIONS -------------------------

clear_screen() {
    clear 2>/dev/null || printf '\033c'
}

line() {
    echo -e "${GRAY}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

success() {
    echo -e "  ${GREEN}[+]${RESET} $*"
}

error() {
    echo -e "  ${RED}[!]${RESET} $*"
}

info() {
    echo -e "  ${CYAN}[*]${RESET} $*"
}

warning() {
    echo -e "  ${YELLOW}[!]${RESET} $*"
}

pause() {
    echo
    read -r -p "$(echo -e "${PURPLE}  ENTER${RESET} ${GRAY}ile devam et...${RESET}")" _
}

header() {
    clear_screen

    echo -e "${GREEN}${BOLD}"
    echo '  ███████╗███╗   ██╗██╗██████╗ ███████╗██████╗ '
    echo '  ██╔════╝████╗  ██║██║██╔══██╗██╔════╝██╔══██╗'
    echo '  ███████╗██╔██╗ ██║██║██████╔╝█████╗  ██████╔╝'
    echo '  ╚════██║██║╚██╗██║██║██╔═══╝ ██╔══╝  ██╔══██╗'
    echo '  ███████║██║ ╚████║██║██║     ███████╗██║  ██║'
    echo '  ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝'
    echo -e "${RESET}"

    echo -e "             ${CYAN}${BOLD}S N I P E R 2${RESET}"
    echo -e "          ${PURPLE}N E O N   C Y B E R${RESET}"
    echo -e "              ${GRAY}VERSION $VERSION${RESET}"

    line
    echo -e "       ${GREEN}AUTHORIZED SECURITY TOOLKIT${RESET}"
    line
    echo
}

section() {
    echo
    echo -e "${PURPLE}${BOLD}  $1${RESET}"
    line
}

# -------------------- INPUT FUNCTIONS ----------------------

read_choice() {
    local prompt="$1"
    local result

    read -r -p "$(echo -e "${GREEN}  SNIPER2 ${PINK}➜ ${RESET}${WHITE}$prompt${RESET}:")" result

    CHOICE=$(printf '%s' "$result" | tr '[:upper:]' '[:lower:]')
}

ask_url() {
    local value

    while true; do
        echo
        read -r -p "  Hedef URL: " value

        if [[ "$value" =~ ^https?://[^/[:space:]]+ ]]; then
            TARGET="$value"
            return 0
        fi

        error "Geçerli bir http:// veya https:// adresi gir."
    done
}

ask_host() {
    local value

    while true; do
        echo
        read -r -p "  Hedef IP / alan adı: " value

        if [[ -n "$value" &&
              "$value" != -* &&
              "$value" != *[[:space:]]* ]]; then
            TARGET="$value"
            return 0
        fi

        error "Geçerli bir IP veya alan adı gir."
    done
}

# -------------------- TOOL DEFINITIONS ---------------------

tool_info() {
    case "$1" in
        parsero)
            TOOL_NAME="PARSER0"
            BIN="parsero"
            ;;
        plecost)
            TOOL_NAME="PLECOST"
            BIN="plecost"
            ;;
        apache-users)
            TOOL_NAME="APACHE USERS"
            BIN="apache-users"
            ;;
        fimap)
            TOOL_NAME="FIMAP"
            BIN="fimap"
            ;;
        ua-tester)
            TOOL_NAME="UA TESTER"
            BIN="ua-tester"
            ;;
        uniscan)
            TOOL_NAME="UNISCAN"
            BIN="uniscan"
            ;;
        joomscan)
            TOOL_NAME="JOOMSCAN"
            BIN="joomscan"
            ;;
        nmap)
            TOOL_NAME="NMAP"
            BIN="nmap"
            ;;
        nikto)
            TOOL_NAME="NIKTO"
            BIN="nikto"
            ;;
        dirb)
            TOOL_NAME="DIRB"
            BIN="dirb"
            ;;
        *)
            TOOL_NAME="UNKNOWN"
            BIN=""
            return 1
            ;;
    esac
}

tool_exists() {
    tool_info "$1" || return 1

    if [[ -z "$BIN" ]] || ! command -v "$BIN" >/dev/null 2>&1; then
        error "$TOOL_NAME bulunamadı."
        echo
        echo "  Beklenen komut: $BIN"
        echo "  Kurulumunu veya komut adını kontrol et."
        return 1
    fi

    success "$TOOL_NAME bulundu: $(command -v "$BIN")"
    return 0
}

# -------------------- REPORT SYSTEM ------------------------

new_report() {
    local safe_name
    safe_name=$(printf '%s' "$1" | tr -cd '[:alnum:]_-')

    LOGFILE="$REPORT_DIR/${safe_name}_$(date +%Y%m%d_%H%M%S).log"
}

execute_command() {
    local status

    if [[ "$#" -lt 1 ]]; then
        error "Çalıştırılacak komut bulunamadı."
        return 1
    fi

    new_report "$TOOL"

    echo
    line
    info "Komut: $*"
    info "Rapor: $LOGFILE"
    line

    "$@" 2>&1 | tee "$LOGFILE"
    status=${PIPESTATUS[0]}

    line

    if [[ "$status" -eq 0 ]]; then
        success "Komut başarıyla tamamlandı."
    else
        error "Komut hata koduyla tamamlandı: $status"
        warning "Rapor dosyasını incele."
    fi

    return "$status"
}

# -------------------- HELP SYSTEM --------------------------

show_help() {
    if ! tool_exists "$1"; then
        pause
        return
    fi

    header
    section "$TOOL_NAME - YARDIM"

    echo "  Aracın yerel yardım çıktısı:"
    echo

    "$BIN" --help 2>&1

    local status=$?

    if [[ "$status" -ne 0 ]]; then
        echo
        warning "--help desteklenmiyor olabilir. -h deneniyor."
        "$BIN" -h 2>&1 || true
    fi

    pause
}

# -------------------- FEATURE SYSTEM -----------------------

show_features() {
    header
    section "$TOOL_NAME - ÖZELLİKLER"

    case "$1" in
        parsero)
            echo "  [01] robots.txt analizi"
            echo "  [02] Disallow kayıtlarının incelenmesi"
            echo "  [03] Web yollarının keşfi"
            echo "  [04] Robots yapılandırmasının değerlendirilmesi"
            ;;
        plecost)
            echo "  [01] WordPress eklenti keşfi"
            echo "  [02] Eklenti sürümü araştırması"
            echo "  [03] Bilinen güvenlik sorunlarının incelenmesi"
            echo "  [04] WordPress bileşen analizi"
            ;;
        apache-users)
            echo "  [01] Apache UserDir yapılandırması"
            echo "  [02] Kullanıcı dizini erişilebilirliği"
            echo "  [03] Sunucu yapılandırma incelemesi"
            ;;
        fimap)
            echo "  [01] LFI analizleri"
            echo "  [02] RFI analizleri"
            echo "  [03] URL parametre kontrolleri"
            echo "  [04] Dosya dahil etme davranışları"
            ;;
        ua-tester)
            echo "  [01] User-Agent testi"
            echo "  [02] HTTP istemci kimliği karşılaştırması"
            echo "  [03] İstek davranışı incelemesi"
            ;;
        uniscan)
            echo "  [01] Web keşfi"
            echo "  [02] Dizin ve dosya kontrolleri"
            echo "  [03] Statik analiz"
            echo "  [04] Dinamik analiz"
            echo "  [05] Web sunucusu parmak izi"
            ;;
        joomscan)
            echo "  [01] Joomla kurulum analizi"
            echo "  [02] Bileşen keşfi"
            echo "  [03] Joomla güvenlik kontrolleri"
            ;;
        nmap)
            echo "  [01] TCP port keşfi"
            echo "  [02] UDP port keşfi"
            echo "  [03] Servis ve sürüm tespiti"
            echo "  [04] İşletim sistemi tespiti"
            echo "  [05] Ağ keşfi"
            ;;
        nikto)
            echo "  [01] Web sunucusu kontrolleri"
            echo "  [02] Yaygın yapılandırma sorunları"
            echo "  [03] Eski bileşenlerin araştırılması"
            echo "  [04] Web sunucusu dosya kontrolleri"
            ;;
        dirb)
            echo "  [01] Dizin keşfi"
            echo "  [02] Dosya keşfi"
            echo "  [03] Wordlist desteği"
            echo "  [04] Özel wordlist kullanımı"
            ;;
    esac

    line
    echo -e "  ${GRAY}Not: Bu bölüm özellikleri açıklar; tarama başlatmaz.${RESET}"
    pause
}

# -------------------- CUSTOM COMMAND ----------------------

custom_command() {
    local -a args

    if ! tool_exists "$1"; then
        pause
        return
    fi

    header
    section "$TOOL_NAME - ÖZEL KOMUT"

    echo "  Önce desteklenen parametreleri görmek için yardım:"
    echo

    "$BIN" --help 2>&1 || "$BIN" -h 2>&1 || true

    echo
    warning "Yalnızca aracın desteklediği parametreleri gir."
    echo "  Hedef dahil tüm argümanları yaz."
    echo "  Örnek: -u https://example.com"
    echo

    read -r -a args -p "  Argümanlar: "

    if [[ "${#args[@]}" -eq 0 ]]; then
        error "Argüman girilmedi."
        pause
        return
    fi

    execute_command "$BIN" "${args[@]}"
    pause
}

# -------------------- BASIC SCANS --------------------------

basic_scan() {
    local tool="$1"

    if ! tool_exists "$tool"; then
        pause
        return
    fi

    case "$tool" in
        parsero|fimap|joomscan|nikto|dirb)
            ask_url
            ;;
        nmap)
            ask_host
            ;;
        *)
            custom_command "$tool"
            return
            ;;
    esac

    case "$tool" in
        parsero)
            execute_command "$BIN" -u "$TARGET"
            ;;
        fimap)
            execute_command "$BIN" -u "$TARGET"
            ;;
        joomscan)
            execute_command "$BIN" -u "$TARGET"
            ;;
        nikto)
            execute_command "$BIN" -h "$TARGET"
            ;;
        dirb)
            execute_command "$BIN" "$TARGET"
            ;;
        nmap)
            warning "Bu profil sınırlı ve düşük hızlı TCP keşfidir."
            read -r -p "  Başlatmak için EVET yaz: " confirm

            if [[ "$confirm" == "EVET" ]]; then
                execute_command "$BIN" -sV -T2 -F "$TARGET"
            else
                info "İşlem iptal edildi."
            fi
            ;;
    esac

    pause
}

# -------------------- ADVANCED SCAN -------------------------

advanced_scan() {
    local tool="$1"
    local -a args

    if ! tool_exists "$tool"; then
        pause
        return
    fi

    header
    section "$TOOL_NAME - GELİŞMİŞ KOMUT"

    echo "  Bu bölüm araç parametrelerini senin belirlemene izin verir."
    echo "  Önce aracın kendi yardımını incele."
    echo

    "$BIN" --help 2>&1 || "$BIN" -h 2>&1 || true

    echo
    warning "Yalnızca izinli hedeflerde ve aracın desteklediği parametrelerle çalıştır."
    echo

    read -r -a args -p "  Komut argümanları: "

    if [[ "${#args[@]}" -eq 0 ]]; then
        error "Argüman girilmedi."
        pause
        return
    fi

    execute_command "$BIN" "${args[@]}"
    pause
}

# -------------------- TOOL MENU ----------------------------

tool_menu() {
    local tool="$1"
    local choice

    tool_info "$tool" || return

    while true; do
        header

        section "$TOOL_NAME"

        echo -e "  ${CYAN}[1]${RESET} Standart tarama"
        echo -e "  ${CYAN}[2]${RESET} Gelişmiş / özel komut"
        echo -e "  ${PURPLE}[3]${RESET} Aracın yardım menüsü"
        echo -e "  ${PINK}[4]${RESET} Özellikler"
        echo -e "  ${YELLOW}[5]${RESET} Kurulum kontrolü"
        echo -e "  ${RED}[0]${RESET} Ana menüye dön"

        echo
        line

        read_choice "$TOOL_NAME"

        case "$CHOICE" in
            1)
                basic_scan "$tool"
                ;;
            2)
                advanced_scan "$tool"
                ;;
            3)
                show_help "$tool"
                ;;
            4|h)
                show_features "$tool"
                ;;
            5)
                header
                tool_exists "$tool" || true
                pause
                ;;
            0|q|back)
                return
                ;;
            *)
                error "Geçersiz seçim."
                sleep 1
                ;;
        esac
    done
}

# -------------------- TOOL STATUS --------------------------

tool_status() {
    local tool
    local -a tools=(
        parsero
        plecost
        apache-users
        fimap
        ua-tester
        uniscan
        joomscan
        nmap
        nikto
        dirb
    )

    header
    section "ARAÇ DURUMU"

    for tool in "${tools[@]}"; do
        tool_info "$tool"

        if command -v "$BIN" >/dev/null 2>&1; then
            echo -e "  ${GREEN}[ INSTALLED ]${RESET} $TOOL_NAME"
        else
            echo -e "  ${RED}[ MISSING ]${RESET} $TOOL_NAME"
        fi
    done

    pause
}

# -------------------- REPORT MENU --------------------------

report_menu() {
    header
    section "TARAMA RAPORLARI"

    if [[ -z "$(find "$REPORT_DIR" -maxdepth 1 -type f -print -quit)" ]]; then
        warning "Henüz rapor oluşturulmamış."
    else
        ls -lah "$REPORT_DIR"
    fi

    pause
}

# -------------------- SYSTEM INFORMATION -------------------

system_info() {
    header
    section "SİSTEM BİLGİLERİ"

    echo "  İşletim sistemi:"
    if [[ -r /etc/os-release ]]; then
        . /etc/os-release
        echo "  $PRETTY_NAME"
    else
        uname -s
    fi

    echo
    echo "  Kernel: $(uname -r)"
    echo "  Shell: $BASH_VERSION"
    echo "  Kullanıcı: $(id -un)"
    echo "  Rapor klasörü: $REPORT_DIR"

    pause
}

# -------------------- MAIN MENU ----------------------------

main_menu() {
    while true; do
        header

        echo -e "  ${GREEN}${BOLD}WEB SECURITY TOOLS${RESET}"
        echo

        echo -e "  ${CYAN}[01]${RESET} Parsero"
        echo -e "  ${CYAN}[02]${RESET} Plecost"
        echo -e "  ${CYAN}[03]${RESET} Apache Users"
        echo -e "  ${CYAN}[04]${RESET} Fimap"
        echo -e "  ${CYAN}[05]${RESET} UA-Tester"
        echo -e "  ${CYAN}[06]${RESET} Uniscan"
        echo -e "  ${CYAN}[07]${RESET} JoomScan"
        echo -e "  ${CYAN}[08]${RESET} Nmap"
        echo -e "  ${CYAN}[09]${RESET} Nikto"
        echo -e "  ${CYAN}[10]${RESET} DIRB"

        echo
        line

        echo -e "  ${PURPLE}[11]${RESET} Araç durumları"
        echo -e "  ${PURPLE}[12]${RESET} Raporları görüntüle"
        echo -e "  ${PURPLE}[13]${RESET} Sistem bilgileri"
        echo -e "  ${RED}[00]${RESET} Çıkış"

        echo
        line

        read_choice "MAIN MENU"

        case "$CHOICE" in
            1) tool_menu parsero ;;
            2) tool_menu plecost ;;
            3) tool_menu apache-users ;;
            4) tool_menu fimap ;;
            5) tool_menu ua-tester ;;
            6) tool_menu uniscan ;;
            7) tool_menu joomscan ;;
            8) tool_menu nmap ;;
            9) tool_menu nikto ;;
            10) tool_menu dirb ;;
            11) tool_status ;;
            12) report_menu ;;
            13) system_info ;;
            0|00|q|exit)
                clear_screen
                echo -e "${GREEN}SNIPER2 kapatıldı.${RESET}"
                exit 0
                ;;
            *)
                error "Geçersiz seçim."
                sleep 1
                ;;
        esac
    done
}

# -------------------- START -------------------------------

if (( BASH_VERSINFO[0] < 4 )); then
    echo "Bash 4 veya üzeri gereklidir."
    exit 1
fi

main_menu
