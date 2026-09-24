# Proof of Handover

**Bukti serah terima barang on-chain.** Penjual mencatat, pembeli mengonfirmasi dari wallet-nya sendiri. Hasilnya bukti dua pihak yang tidak bisa dihapus atau diedit siapa pun.

> WhatsApp bisa dihapus, blockchain tidak.

**Live:** [www.proofofhandover.app](https://www.proofofhandover.app) · **Repo:** [github.com/Manjooo7/ProofOfHandover](https://github.com/Manjooo7/ProofOfHandover)

Dibangun di **BOT Chain** untuk Build Week Hackathon Vol.2 — track RWA.

---

## Masalah

Jual-beli barang bekas di Indonesia (HP, motor, laptop, kamera) hampir selalu lewat marketplace atau COD, dan buktinya cuma chat plus foto. Bukti seperti itu bisa dihapus sepihak, bisa dipalsukan lewat screenshot, tidak punya timestamp yang bisa dipercaya, dan tidak membuktikan bahwa **kedua** pihak setuju.

Muncullah sengketa klasik: "barang belum saya terima", "kondisinya tidak seperti itu waktu diserahkan", "saya tidak pernah setuju harga itu".

## Solusi

Catatan serah terima yang ditandatangani dua wallet berbeda, tersimpan permanen di BOT Chain. Setelah pembeli menekan konfirmasi, status terkunci selamanya beserta timestamp dari blok — dan siapa pun bisa memverifikasinya tanpa perlu percaya pada satu server.

Kontrak ini **tidak memegang dana sama sekali** (tidak ada fungsi `payable`). Tugasnya hanya mencatat kesepakatan.

---

## Deployment

| Jaringan | Chain ID | Alamat Kontrak | Explorer |
|---|---|---|---|
| **BOT Chain Mainnet** | 677 (`0x2a5`) | `0xeC9eC63F2c7E9f7dC9667e1b514eAce86bb0Da7F` | [scan.botchain.ai](https://scan.botchain.ai/address/0xeC9eC63F2c7E9f7dC9667e1b514eAce86bb0Da7F) |
| BOT Chain Testnet (Bohr) | 968 (`0x3c8`) | `0xcB71F6AbbC3bcEb2f0221c85f24b8d940fa41a8A` | [scan.bohr.life](https://scan.bohr.life/address/0xcB71F6AbbC3bcEb2f0221c85f24b8d940fa41a8A) |

- Compiler: `solc 0.8.20`, optimizer enabled (runs: 200)
- License: MIT
- Jaringan aktif di frontend: **mainnet** (`ACTIVE_NETWORK_KEY = "mainnet"` di `index.html`)

**Parameter jaringan mainnet untuk MetaMask**

| | |
|---|---|
| Network name | BOT Chain Mainnet |
| RPC URL | `https://rpc.botchain.ai` |
| Chain ID | 677 |
| Currency symbol | BOT |
| Block explorer | `https://scan.botchain.ai` |

Frontend menambahkan jaringan ini otomatis lewat `wallet_addEthereumChain` kalau belum ada di wallet.

---

## Cara Pakai

**Sebagai penjual**

1. Buka website, tekan **Connect Wallet** (MetaMask).
2. Isi nama barang, kondisi, harga, dan alamat wallet pembeli.
3. Submit dan bayar gas. Kamu dapat nomor ID, misalnya `#7`.
4. Bagikan link `?id=7` ke pembeli lewat WhatsApp (ada tombol share langsung).

**Sebagai pembeli**

1. Buka link dari penjual — detail barang langsung tampil, tanpa perlu wallet.
2. Connect wallet yang alamatnya ditunjuk sebagai pembeli.
3. Periksa barangnya, lalu tekan **Saya Terima** dan bayar gas.
4. Status berubah jadi `CONFIRMED` dan terkunci permanen.

**Sebagai pihak ketiga**

Masukkan ID di halaman Cek. Data dibaca langsung dari RPC publik, jadi tidak butuh wallet dan tidak ada biaya.

---

## Smart Contract

`ProofOfHandover.sol` · Solidity `^0.8.20`

```solidity
struct Handover {
    address seller;
    address buyer;
    string  itemName;
    string  condition;
    string  price;
    uint256 createdAt;
    uint256 confirmedAt;
    bool    isConfirmed;
}
```

| Fungsi | Tipe | Keterangan |
|---|---|---|
| `createHandover(buyer, itemName, condition, price)` | write | Menyimpan catatan baru, mengembalikan ID (dimulai dari 1) |
| `confirmHandover(id)` | write | Hanya pembeli yang ditunjuk, hanya sekali |
| `getHandover(id)` | view | Membaca seluruh isi catatan |
| `totalHandovers()` | view | Jumlah catatan yang pernah dibuat |

**Event:** `HandoverCreated(id, seller, buyer, itemName)` · `HandoverConfirmed(id, buyer, confirmedAt)`

**Pengaman**

- Alamat pembeli tidak boleh kosong dan tidak boleh sama dengan penjual
- Hanya `buyer` yang bisa memanggil `confirmHandover`
- Catatan yang sudah dikonfirmasi tidak bisa dikonfirmasi ulang atau diubah
- Timestamp diambil dari `block.timestamp`, bukan dari input pengguna
- Batas panjang input: nama barang 100 byte, kondisi 300 byte, harga 50 byte

Harga disimpan sebagai `string` supaya bisa ditulis apa adanya ("Rp 5.500.000"). Kontrak mencatat kesepakatan, bukan memproses pembayaran.

---

## Frontend

Satu file `index.html`, tanpa framework dan tanpa build step. Hanya ethers.js v6 dari CDN.

- Empat layar dalam satu halaman: Beranda, Buat, Cek, Konfirmasi
- Baca data via `JsonRpcProvider` sehingga verifikasi jalan tanpa wallet
- Deteksi jaringan salah, dengan tombol pindah/tambah jaringan otomatis
- Deep link `?id=<nomor>` untuk dibagikan ke pembeli
- **Mode terang & gelap**, mengikuti setelan sistem dan bisa diganti manual
- **Dua bahasa (Indonesia & Inggris)**, terdeteksi dari bahasa browser
- Mobile-first, tanpa jargon crypto di permukaan

### Mode gelap

Tombol ikon di header menukar tema. Nilai awalnya mengikuti `prefers-color-scheme`, dan pilihan manual disimpan di `localStorage` (`poh.theme`). Tema dipasang oleh skrip kecil di dalam `<head>` sebelum halaman dilukis, jadi tidak ada kedipan putih saat memuat. Seluruh warna memakai CSS custom property, sehingga mode gelap hanya menimpa token di `[data-theme="dark"]` — palet kertas-dan-tinta aslinya tetap dipertahankan, bukan diganti abu-abu netral.

### Dua bahasa

Pemilih `ID | EN` di header. Bahasa awal ditebak dari `navigator.language`, lalu pilihan manual selalu menang dan disimpan di `localStorage` (`poh.lang`).

Teks statis diberi atribut `data-i18n` (varian: `-html`, `-ph` untuk placeholder, `-aria` untuk label aksesibilitas) dan diisi dari satu kamus di `index.html` dengan format `"kunci": ["Indonesia", "English"]`. Teks yang dibuat runtime memakai `t("kunci")`, sehingga yang ikut diterjemahkan bukan cuma tampilan statis:

- pesan error MetaMask dan kegagalan jaringan
- pesan `require()` dari kontrak (teksnya berbahasa Indonesia, dipetakan lewat `REVERT_MAP`)
- label status kartu catatan dan penjelasan sesuai peran pembaca
- pesan WhatsApp yang dikirim ke pembeli
- format tanggal (`id-ID` atau `en-GB`) dan format angka saldo

### Menjalankan secara lokal

```bash
git clone https://github.com/Manjooo7/ProofOfHandover.git
cd ProofOfHandover
python -m http.server 8000
# buka http://localhost:8000
```

Buka lewat HTTP server, jangan `file://` — link share tidak akan terbentuk dan beberapa API browser dibatasi di protokol file.

### Deploy

Situs statis di GitHub Pages dari branch `main`, dengan custom domain lewat file `CNAME` → `www.proofofhandover.app`. Tidak ada backend, tidak ada database, tidak ada environment variable, tidak ada build step.

---

## Struktur Repo

```
ProofOfHandover/
├── index.html            # seluruh frontend (UI + logika + ABI)
├── ProofOfHandover.sol   # smart contract
├── CNAME                 # custom domain GitHub Pages
└── README.md
```

---

## Batasan

Tidak ada escrow atau penahanan dana, tidak ada upload foto/IPFS, catatan tidak bisa dibatalkan atau dihapus (memang disengaja), dan belum ada penolakan oleh pembeli. Sifat permanen adalah fitur, bukan bug: begitu dikonfirmasi, tidak ada pihak mana pun — termasuk pembuat kontrak — yang bisa mengubahnya.

## Rencana Lanjutan

Foto barang di IPFS, QR code per catatan, penolakan pembeli disertai alasan, mode escrow opsional, dan ekspor bukti ke PDF.

---

## Lisensi

MIT

---

Dibangun di [BOT Chain](https://botchain.ai) · Explorer: [scan.botchain.ai](https://scan.botchain.ai)
