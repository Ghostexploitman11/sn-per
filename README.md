# sn-per
A Bash-based security tool for automated reconnaissance and web vulnerability scanning.Otomatik keşif ve web güvenlik açığı taraması için geliştirilmiş Bash tabanlı bir güvenlik aracı.
# SNIPER

**Security Tools Manager | Bash-Based Security Toolkit**

SNIPER, Linux sistemlerinde çeşitli siber güvenlik ve keşif araçlarını tek bir terminal arayüzü üzerinden yönetmek için geliştirilmiş Bash tabanlı bir projedir.

## Özellikler

- Merkezi terminal menüsü
- Birden fazla güvenlik aracını tek noktadan çalıştırma
- Araç bağımlılıklarını otomatik kurma
- Python sanal ortamı desteği
- GitHub üzerinden araç indirme
- Komut satırı argümanlarıyla araç çalıştırma
- Farklı Linux paket yöneticileri için kurulum desteği

## Desteklenen Araçlar

| Araç | Açıklama |
|---|---|
| Parsero | robots.txt analizi |
| Plecost | WordPress güvenlik incelemesi |
| Apache Users | Apache UserDir kontrolü |
| Fimap | LFI/RFI testleri |
| UA-Tester | User-Agent testleri |
| Uniscan | Web güvenlik kontrolleri |
| JoomScan | Joomla güvenlik analizi |
| Nmap | Port ve servis keşfi |
| Nikto | Web sunucusu güvenlik kontrolleri |
| DIRB | Dizin ve dosya keşfi |
| DeBlaze | Araç ve kaynak incelemesi |

## Gereksinimler

- Linux (Kali Linux, Debian vb.)
- Bash
- Git
- Python 3
- Python venv ve pip
- Perl
- Ruby
- İnternet bağlantısı

## Kurulum

Depoyu indirin:

```bash
git clone https://github.com/Ghostexploitmam11/snıper
```

Proje dizinine girin:

```bash
cd snıper
```

Kurulum dosyasına çalıştırma izni verin:

```bash
chmod +x install.sh
```

Kurulumu başlatın:

```bash
sudo bash install.sh
```

## Kullanım

Kurulum tamamlandıktan sonra herhangi bir dizinden:

```bash
sniper
```

veya:

```bash
snıper
```

komutuyla ana menüyü açabilirsiniz.

## Proje Yapısı

```text
SNIPER/
├── install.sh
└── README.md
```

Kurulum sonrasında:

```text
/opt/security-tools/
├── venvs/
├── parsero/
├── plecost/
├── fimap/
├── ua-tester/
├── joomscan/
├── uniscan/
└── reports/

/usr/local/lib/security-tools/
├── dispatch.sh
└── sniper.sh
```

## Güvenlik ve Sorumluluk

SNIPER, yalnızca izin verilen sistemlerde ve yetkili güvenlik testlerinde kullanılmalıdır.

Araçların kullanımından doğabilecek sorumluluk kullanıcıya aittir.

## Geliştirici

**Ghostexploitman11**

GitHub: [Ghostexploitman11](https://github.com/Ghostexploitman11)

**Repository:** [SNIPER](https://github.com/Ghostexploitmam11/snıper)

---

*SNIPER | Security Tools Manager*
