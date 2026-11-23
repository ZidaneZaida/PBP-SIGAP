# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## SIGAP --- Sistem Informasi dan Kesiapsiagaan Bencana Kota Padang

**Versi dokumen:** 1.0\
**Status:** Draft untuk validasi dan perencanaan MVP\
**Platform:** Android (Flutter) dan Website (PC/Desktop)\
**Wilayah operasional awal:** Kota Padang, Sumatera Barat\
**Nama produk:** SIGAP\
**Tagline usulan:** *Siap Informasi, Siap Tindakan.*

------------------------------------------------------------------------

## 1. Ringkasan Produk

SIGAP adalah aplikasi informasi dan kesiapsiagaan bencana yang dirancang
untuk membantu masyarakat Kota Padang memperoleh informasi kebencanaan,
memahami risiko wilayah, menemukan bantuan dan lokasi evakuasi, serta
berkomunikasi mengenai kondisi keluarga ketika terjadi keadaan darurat.

SIGAP direncanakan hadir dalam dua platform: 1. **Aplikasi Android**,
dikembangkan menggunakan Flutter, dengan pengalaman yang mengutamakan
akses cepat dan penggunaan saat pengguna sedang bergerak. 2. **Website
untuk PC/desktop**, dengan tata letak yang lebih luas untuk membaca
informasi, memantau peta, dan mengelola data pengguna.

Kedua platform menggunakan sumber data dan aturan bisnis yang sama agar
informasi yang tampil tetap konsisten. SIGAP bukan lembaga resmi yang
menerbitkan peringatan bencana. Informasi resmi harus merujuk kepada
instansi berwenang, ditampilkan bersama sumber dan waktu pembaruan,
serta tidak boleh dibuat seolah-olah merupakan peringatan resmi SIGAP.

### 1.1 Masalah yang ingin diselesaikan

-   Informasi bencana, panduan keselamatan, lokasi bantuan, dan
    informasi keluarga dapat tersebar di banyak tempat.
-   Pengguna membutuhkan informasi yang cepat ditemukan dan mudah
    dipahami, khususnya dalam situasi darurat.
-   Pengguna mungkin tidak mengetahui langkah yang harus dilakukan
    setelah menerima peringatan.
-   Keluarga membutuhkan cara sederhana untuk menyampaikan status aman
    atau meminta bantuan.
-   Informasi risiko wilayah perlu disajikan dengan konteks lokasi dan
    sumber yang jelas.

### 1.2 Tujuan produk

-   Memudahkan masyarakat Kota Padang mengakses informasi kebencanaan
    yang dapat ditelusuri sumbernya.
-   Membantu pengguna memahami tindakan yang disarankan sebelum, saat,
    dan setelah bencana.
-   Menyediakan peta informasi risiko dan lokasi penting yang bersumber
    dari data yang dapat dipertanggungjawabkan.
-   Membantu keluarga mengirim dan melihat konfirmasi status aman.
-   Menyediakan akses praktis ke kontak darurat, posko, fasilitas
    kesehatan, dan titik evakuasi yang telah diverifikasi.
-   Menyediakan pengalaman yang konsisten antara Android dan website.

### 1.3 Prinsip produk

1.  **Keselamatan lebih utama daripada dekorasi:** informasi darurat
    harus menjadi fokus visual.
2.  **Sumber transparan:** tampilkan penerbit, waktu terbit, waktu
    pembaruan, dan status verifikasi.
3.  **Tidak menyesatkan:** jangan mengarang data, prediksi, status aman,
    jalur evakuasi, atau kontak.
4.  **Mudah digunakan:** tindakan penting harus dapat ditemukan dengan
    sedikit langkah.
5.  **Inklusif:** gunakan bahasa sederhana, kontras memadai, ukuran teks
    yang dapat dibaca, dan indikator yang tidak hanya mengandalkan
    warna.
6.  **Privasi berdasarkan kebutuhan:** kumpulkan lokasi dan data
    keluarga hanya jika diperlukan serta dengan persetujuan yang jelas.
7.  **Tangguh terhadap jaringan buruk:** sediakan informasi keselamatan
    dasar yang dapat dibaca tanpa koneksi jika memungkinkan.

------------------------------------------------------------------------

## 2. Pengguna Sasaran dan Kebutuhan

### 2.1 Segmen pengguna

  -----------------------------------------------------------------------
  Pengguna                            Kebutuhan utama
  ----------------------------------- -----------------------------------
  Warga Kota Padang                   Melihat peringatan, berita, peta
                                      risiko, dan panduan keselamatan

  Keluarga/rumah tangga               Membagikan status aman dan
                                      mengetahui anggota yang belum
                                      memberi konfirmasi

  Mahasiswa, pekerja, dan pendatang   Memahami risiko lokasi serta
                                      menemukan bantuan dan titik
                                      evakuasi

  Pengguna dengan kebutuhan           Mengakses informasi dengan teks
  aksesibilitas                       jelas, navigasi sederhana, dan
                                      alternatif visual/audio

  Admin/pengelola informasi (fitur    Memeriksa laporan masyarakat dan
  lanjutan)                           mengelola informasi yang memang
                                      menjadi kewenangannya
  -----------------------------------------------------------------------

### 2.2 Kebutuhan utama pengguna

-   Saya ingin mengetahui apakah ada peringatan bencana yang relevan
    dengan lokasi saya.
-   Saya ingin mengetahui sumber dan waktu pembaruan sebuah informasi.
-   Saya ingin melihat tingkat risiko suatu wilayah tanpa menganggapnya
    sebagai prediksi pasti.
-   Saya ingin menemukan lokasi evakuasi, posko, rumah sakit, dan kontak
    bantuan yang terverifikasi.
-   Saya ingin memberi tahu keluarga bahwa saya aman.
-   Saya ingin membaca panduan tindakan yang jelas untuk jenis bencana
    tertentu.
-   Saya ingin tetap dapat membuka panduan keselamatan dasar ketika
    koneksi internet buruk.

------------------------------------------------------------------------

## 3. Ruang Lingkup Produk

### 3.1 Termasuk dalam MVP

1.  Registrasi, login, logout, dan pemulihan akun.
2.  Dashboard kebencanaan untuk Kota Padang.
3.  Daftar peringatan dan detail peringatan.
4.  Berita kebencanaan dari sumber yang dapat ditelusuri.
5.  Peta lokasi dan risiko wilayah berdasarkan data yang tersedia.
6.  Daftar lokasi penting: titik evakuasi, posko, fasilitas kesehatan,
    dan bantuan.
7.  Profil pengguna dan pengaturan notifikasi.
8.  Kontak darurat yang telah diverifikasi.
9.  Fitur keluarga dasar: membuat/bergabung dengan grup keluarga,
    menambahkan anggota, dan mengirim status aman.
10. Panduan kesiapsiagaan dan langkah keselamatan.
11. Tampilan Android dan website dengan data serta aturan bisnis yang
    konsisten.

### 3.2 Fitur lanjutan setelah MVP

-   Pelaporan kejadian oleh masyarakat dengan foto, koordinat, kategori,
    dan status verifikasi.
-   Panel admin untuk moderasi laporan dan pengelolaan konten yang
    berwenang.
-   Pemberitahuan berbasis wilayah (geofencing) jika data lokasi dan
    izin tersedia.
-   Mode offline yang lebih lengkap, termasuk penyimpanan panduan dan
    peta tertentu.
-   Informasi jalur evakuasi dinamis jika tersedia data resmi dan
    integrasi yang layak.
-   Dukungan bahasa tambahan dan aksesibilitas tingkat lanjut.
-   Analitik penggunaan yang menjaga privasi untuk evaluasi produk.

### 3.3 Di luar ruang lingkup awal

-   Menggantikan fungsi BMKG, BPBD, Basarnas, pemerintah daerah, atau
    instansi resmi lainnya.
-   Menerbitkan prediksi gempa atau tsunami sendiri.
-   Menjamin keselamatan pengguna atau menjamin semua data selalu
    tersedia.
-   Mengirim bantuan fisik secara langsung.
-   Menampilkan rute evakuasi real-time tanpa sumber data dan validasi
    yang memadai.

------------------------------------------------------------------------

## 4. Platform dan Konsistensi Pengalaman

### 4.1 Android

-   Teknologi aplikasi: Flutter.
-   Navigasi utama mengikuti wireframe mobile: Dashboard, Peringatan,
    Peta Risiko, serta Keluarga & Bantuan.
-   Profil dan Pengaturan dapat diakses dari bagian akun/header atau
    menu yang konsisten.
-   Tombol tindakan darurat harus mudah dijangkau, tetapi tidak boleh
    memicu panggilan atau pengiriman lokasi tanpa tindakan sadar
    pengguna.

### 4.2 Website

-   Fokus pada penggunaan desktop dengan sidebar seperti pada wireframe.
-   Dashboard menggunakan panel/kartu untuk peringatan aktif, ringkasan
    risiko, tindakan cepat, keluarga, dan informasi terbaru.
-   Layout harus responsif untuk tablet dan layar yang lebih kecil.
-   Navigasi, istilah, status, dan data harus sama dengan versi mobile.

### 4.3 Prinsip konsistensi

-   Satu akun dapat digunakan pada kedua platform.
-   Perubahan profil, anggota keluarga, dan preferensi tersinkronisasi
    melalui backend.
-   Status peringatan dan sumber datanya konsisten pada semua platform.
-   Komponen visual dapat menyesuaikan ukuran layar, tetapi prioritas
    informasi keselamatan tidak berubah.

------------------------------------------------------------------------

## 5. Struktur Informasi dan Navigasi

### 5.1 Navigasi utama mobile

1.  **Dashboard** --- ringkasan kondisi, peringatan aktif, tindakan
    cepat, status keluarga, dan informasi terbaru.
2.  **Peringatan** --- daftar peringatan aktif dan riwayat.
3.  **Peta Risiko** --- peta wilayah, lokasi kejadian, dan lokasi
    penting.
4.  **Keluarga & Bantuan** --- status anggota keluarga, kontak darurat,
    serta lokasi bantuan.

Profil dan Pengaturan tersedia melalui ikon akun/menu yang terlihat
konsisten.

### 5.2 Navigasi utama website

-   Dashboard
-   Peringatan
-   Peta Risiko
-   Keluarga & Bantuan
-   Pengaturan
-   Profil

Struktur ini mengikuti wireframe website dan dapat dikembangkan tanpa
mengubah istilah utama yang telah dikenal pengguna.

------------------------------------------------------------------------

## 6. Kebutuhan Fungsional

Prioritas: **P0 = wajib untuk MVP**, **P1 = penting setelah fungsi dasar
stabil**, **P2 = pengembangan lanjutan**.

### FR-01 --- Registrasi dan login (P0)

**Deskripsi:** Pengguna dapat membuat akun dan masuk ke SIGAP.

**Kriteria penerimaan** - Form registrasi memvalidasi nama, email, dan
kata sandi. - Email yang telah digunakan tidak dapat didaftarkan
ulang. - Login menampilkan pesan kesalahan yang tidak membocorkan
informasi sensitif. - Pengguna dapat logout. - Pengguna dapat memulai
proses pemulihan kata sandi. - Login Google/Facebook hanya diaktifkan
jika konfigurasi, kebijakan privasi, dan integrasinya telah siap; jika
belum, sediakan autentikasi email. - Akun tidak boleh menampilkan status
verifikasi yang belum benar-benar dilakukan.

### FR-02 --- Dashboard (P0)

**Deskripsi:** Menampilkan ringkasan informasi paling penting untuk Kota
Padang.

**Elemen** - Peringatan aktif paling penting. - Ringkasan informasi
risiko lokasi dengan sumber dan waktu pembaruan. - Tombol tindakan
cepat: lihat peringatan, peta risiko, status aman, dan bantuan. -
Ringkasan status anggota keluarga jika fitur keluarga sudah
diaktifkan. - Daftar berita atau pembaruan terbaru. - Lokasi yang
digunakan untuk personalisasi, dengan pilihan mengubah atau
menonaktifkannya.

**Kriteria penerimaan** - Peringatan darurat ditampilkan lebih menonjol
daripada konten non-darurat. - Dashboard menampilkan waktu pembaruan
data. - Jika data tidak tersedia, tampilkan pesan yang jujur seperti
"Data belum tersedia" atau "Gagal memperbarui data", bukan angka atau
status buatan. - Pengguna dapat membuka detail dari setiap kartu.

### FR-03 --- Peringatan bencana (P0)

**Deskripsi:** Menampilkan peringatan bencana aktif dan riwayat yang
bersumber dari instansi atau penyedia data yang ditetapkan.

**Informasi minimum** - Jenis kejadian. - Judul dan isi peringatan. -
Wilayah terdampak. - Tingkat/status peringatan sesuai istilah sumber. -
Waktu diterbitkan dan diperbarui. - Sumber/penerbit dan tautan rujukan
bila tersedia. - Masa berlaku atau status berakhir jika disediakan
sumber. - Instruksi keselamatan yang berasal dari sumber berwenang atau
konten panduan yang telah ditinjau.

**Kriteria penerimaan** - Pengguna dapat membedakan peringatan aktif dan
riwayat. - Label status tidak hanya dibedakan dengan warna; sertakan
teks dan ikon. - Pengguna dapat membuka sumber asli. - Informasi lama
diberi penanda waktu dan status yang sesuai. - SIGAP tidak membuat
prediksi atau peringatan resmi sendiri.

### FR-04 --- Berita dan pembaruan bencana (P0)

**Deskripsi:** Menyediakan berita yang relevan dengan Kota Padang.

**Informasi minimum** - Judul, ringkasan, isi atau tautan ke sumber. -
Sumber/penerbit. - Tanggal dan waktu publikasi. - Kategori dan wilayah
terkait. - Status verifikasi atau keterangan bahwa konten berasal dari
sumber eksternal.

**Kriteria penerimaan** - Berita tidak dicampur dengan peringatan resmi
tanpa label yang jelas. - Berita yang sama dapat dikenali agar tidak
berulang secara berlebihan. - Pengguna dapat membuka sumber aslinya. -
Konten yang tidak dapat diverifikasi tidak boleh ditampilkan sebagai
fakta resmi.

### FR-05 --- Peta risiko wilayah (P0)

**Deskripsi:** Menampilkan peta Kota Padang dengan layer yang memiliki
makna dan sumber jelas.

**Layer yang disarankan** - Batas wilayah administratif. - Zona risiko
bencana dari sumber resmi yang tersedia. - Lokasi kejadian atau
peringatan yang mempunyai koordinat valid. - Titik evakuasi, posko,
rumah sakit, dan lokasi bantuan yang telah diverifikasi.

**Kriteria penerimaan** - Legenda menjelaskan arti warna, simbol, dan
layer. - Setiap layer memiliki sumber dan tanggal pembaruan. - Pengguna
dapat mencari lokasi atau memilih area jika data mendukung. - Informasi
risiko tidak ditampilkan seolah-olah merupakan kepastian bahwa bencana
akan terjadi. - Jika layer belum memiliki data, tampilkan keterbatasan
secara eksplisit. - Jangan menampilkan jalur evakuasi sebagai rute resmi
jika belum divalidasi pihak berwenang.

### FR-06 --- Lokasi bantuan (P0)

**Deskripsi:** Menampilkan lokasi penting yang dapat membantu pengguna
ketika terjadi bencana.

**Kategori awal** - Titik evakuasi. - Posko atau pusat bantuan. - Rumah
sakit/fasilitas kesehatan. - Kontak darurat. - Dapur umum atau titik
bantuan lain jika data tersedia dan tervalidasi.

**Kriteria penerimaan** - Lokasi memiliki nama, alamat/deskripsi,
kategori, koordinat, sumber, dan waktu verifikasi bila tersedia. -
Tombol "Lihat lokasi" membuka peta. - Tombol "Hubungi" hanya muncul jika
nomor telepon telah diverifikasi. - Data yang sudah tidak berlaku dapat
diperbarui atau diberi penanda.

### FR-07 --- Keluarga & Bantuan (P0)

**Deskripsi:** Membantu pengguna mengelola daftar anggota keluarga dan
membagikan status.

**Fungsi** - Membuat grup keluarga atau bergabung melalui
kode/invitasi. - Menambahkan anggota dan mengelola relasi secara aman. -
Mengirim status "Saya aman" atau "Saya membutuhkan bantuan". -
Menambahkan pesan kondisi secara opsional. - Menampilkan waktu
konfirmasi terakhir. - Menandai anggota yang belum memberikan konfirmasi
sebagai "Belum ada konfirmasi", bukan otomatis "tidak aman". -
Menampilkan kontak dan lokasi bantuan yang relevan.

**Kriteria penerimaan** - Pengguna menyetujui pembagian status dan
informasi yang dibagikan. - Status memiliki waktu pembaruan. - Status
aman tidak dianggap sebagai jaminan keselamatan saat ini jika sudah
lama. - Tidak ada anggota yang dapat melihat grup keluarga tanpa
otorisasi. - Fitur permintaan bantuan harus menjelaskan apakah pesan
hanya dikirim ke keluarga atau juga ke petugas resmi. Jangan menjanjikan
respons petugas jika integrasi belum ada.

### FR-08 --- Kontak darurat (P0)

**Deskripsi:** Menyediakan nomor bantuan yang relevan dan telah
diverifikasi.

**Kriteria penerimaan** - Nomor diberi label layanan dan sumber
verifikasi. - Pengguna harus menekan tombol untuk memulai panggilan;
aplikasi tidak menelepon otomatis. - Nomor ditinjau secara berkala. -
Jika nomor atau layanan belum dapat diverifikasi, jangan tampilkan
sebagai kontak resmi.

### FR-09 --- Profil (P0)

**Deskripsi:** Pengguna dapat melihat dan mengubah data profil.

**Data** - Nama lengkap. - Email. - Nomor telepon bila diperlukan. -
Foto profil opsional. - Alamat atau wilayah utama secara opsional.

**Kriteria penerimaan** - Pengguna dapat menyimpan perubahan dan
menerima konfirmasi. - Validasi diterapkan pada format data. - Informasi
pribadi tidak ditampilkan ke publik secara default. - Lokasi rinci tidak
dikumpulkan jika tidak dibutuhkan.

### FR-10 --- Pengaturan dan notifikasi (P0/P1)

**Deskripsi:** Pengguna mengelola preferensi notifikasi dan keamanan
akun.

**Preferensi** - Peringatan darurat. - Pembaruan berita. - Pembaruan
status keluarga. - Izin lokasi. - Preferensi aksesibilitas. - Perubahan
kata sandi dan keamanan akun.

**Kriteria penerimaan** - Pengguna dapat mengaktifkan atau menonaktifkan
kategori notifikasi yang sesuai kebijakan keselamatan. - Permintaan izin
lokasi disertai penjelasan kegunaan. - Notifikasi menyebutkan jenis,
wilayah, waktu, dan sumber jika relevan. - Hindari notifikasi berulang
yang tidak memberikan informasi baru. - Notifikasi tidak boleh
menggantikan peringatan resmi dari kanal pemerintah.

### FR-11 --- Panduan kesiapsiagaan (P0)

**Deskripsi:** Menyediakan panduan tindakan sebelum, saat, dan setelah
bencana.

**Kategori awal yang dapat diprioritaskan** - Gempa bumi. - Tsunami. -
Banjir. - Longsor atau cuaca ekstrem jika relevan dengan data dan
kebutuhan wilayah.

**Kriteria penerimaan** - Konten ditinjau berdasarkan panduan dari
otoritas yang kompeten. - Instruksi ditulis singkat, berurutan, dan
mudah dipahami. - Tanggal peninjauan dan sumber panduan ditampilkan. -
Panduan dasar dapat disimpan untuk akses offline jika memungkinkan.

### FR-12 --- Pelaporan kejadian oleh warga (P1)

**Deskripsi:** Pengguna dapat mengirim laporan kejadian untuk ditinjau,
bukan langsung menjadi peringatan resmi.

**Data laporan** - Kategori kejadian. - Deskripsi. - Waktu kejadian yang
dilaporkan. - Lokasi atau koordinat dengan izin pengguna. - Foto
opsional. - Status: diterima, sedang ditinjau, terverifikasi, ditolak,
atau ditutup.

**Pengamanan** - Laporan baru diberi label "Belum diverifikasi". -
Lokasi dan foto tidak dipublikasikan otomatis sebelum moderasi. -
Sediakan mekanisme pelaporan penyalahgunaan dan koreksi. - Jangan
mendorong pengguna mendekati bahaya demi mengambil foto. - Fitur ini
memerlukan proses moderasi dan penanggung jawab yang jelas.

### FR-13 --- Panel admin dan moderasi (P1)

**Deskripsi:** Panel khusus untuk pengelola yang berwenang mengelola
konten dan meninjau laporan.

**Fungsi** - Memeriksa laporan masyarakat. - Memperbarui data lokasi
bantuan berdasarkan sumber yang valid. - Mengelola artikel/panduan yang
menjadi tanggung jawab pengelola. - Menyimpan catatan siapa yang
mengubah data dan kapan. - Mengoreksi atau menarik informasi yang
keliru.

**Batasan** - Admin aplikasi tidak boleh mengubah data resmi dari
instansi sumber tanpa kewenangan. - Peran admin harus dibatasi dan
setiap perubahan penting tercatat.

------------------------------------------------------------------------

## 7. Alur Pengguna Utama

### 7.1 Pengguna baru

1.  Pengguna membuka SIGAP.
2.  Pengguna melihat pengenalan singkat dan batas wilayah layanan.
3.  Pengguna mendaftar atau masuk.
4.  Aplikasi meminta izin notifikasi/lokasi hanya saat relevan, disertai
    penjelasan.
5.  Pengguna memilih wilayah utama di Kota Padang jika tidak memberikan
    lokasi perangkat.
6.  Pengguna masuk ke dashboard.

### 7.2 Pengguna melihat peringatan

1.  Pengguna menerima notifikasi atau membuka menu Peringatan.
2.  Pengguna melihat jenis kejadian, tingkat/status, wilayah, dan waktu.
3.  Pengguna membuka detail peringatan.
4.  Pengguna membaca instruksi keselamatan dan sumber asli.
5.  Pengguna dapat membuka peta atau daftar lokasi bantuan jika relevan.

### 7.3 Pengguna mengirim status keluarga

1.  Pengguna membuka Keluarga & Bantuan.
2.  Pengguna memilih "Saya aman" atau "Saya membutuhkan bantuan".
3.  Pengguna menambahkan pesan opsional.
4.  Aplikasi mengirim status ke anggota yang memiliki izin.
5.  Anggota keluarga melihat status beserta waktu konfirmasi terakhir.

### 7.4 Pengguna mencari lokasi evakuasi

1.  Pengguna membuka Peta Risiko atau Bantuan.
2.  Pengguna memilih kategori titik evakuasi.
3.  Aplikasi menampilkan lokasi yang tersedia, sumber, dan status
    verifikasi.
4.  Pengguna membuka detail lokasi.
5.  Pengguna dapat membuka aplikasi peta eksternal jika tersedia.
6.  Aplikasi tidak menyatakan jalur sebagai rute evakuasi resmi kecuali
    sudah divalidasi.

### 7.5 Pengguna membaca berita

1.  Pengguna membuka daftar berita.
2.  Pengguna memilih artikel.
3.  Aplikasi menampilkan sumber, waktu publikasi, wilayah, dan
    isi/ringkasan.
4.  Pengguna dapat membuka sumber asli.

------------------------------------------------------------------------

## 8. Rekomendasi Struktur Layar Berdasarkan Wireframe

Bagian ini mempertahankan arah desain yang sudah ada pada dokumen
wireframe mobile dan website, sekaligus menjelaskan peningkatan yang
dibutuhkan.

### 8.1 Splash screen

**Sudah ada:** Logo SIGAP dan tagline singkat.

**Saran:** Pertahankan layar sederhana. Jangan menahan pengguna terlalu
lama di splash screen. Jika ada peringatan darurat yang perlu
ditampilkan, pastikan pengguna bisa mengaksesnya tanpa proses yang tidak
perlu sejauh aman dan sesuai desain autentikasi.

### 8.2 Registrasi dan login

**Sudah ada:** Form email/kata sandi dan pilihan login sosial.

**Saran:** - Perjelas pesan kesalahan dan validasi input. - Tambahkan
"Lupa kata sandi". - Jelaskan secara ringkas data apa yang
dikumpulkan. - Sediakan akses ke informasi keselamatan dasar tanpa
mengharuskan pembuatan akun, jika tidak membutuhkan data pribadi. -
Login sosial bersifat opsional dan hanya ditampilkan setelah integrasi
siap.

### 8.3 Dashboard

**Sudah ada:** Peringatan terbaru, potensi banjir, tindakan cepat,
status keluarga, lokasi bantuan, dan pembaruan terbaru.

**Saran:** - Urutkan berdasarkan urgensi, bukan hanya kebaruan. -
Tampilkan label "Sumber", "Diperbarui", dan "Wilayah terdampak". -
Tambahkan tombol yang jelas untuk membuka instruksi keselamatan. -
Berikan status koneksi/data terakhir ketika pembaruan gagal. - Hindari
menampilkan nilai risiko yang tidak memiliki metodologi atau sumber.

### 8.4 Peringatan bencana

**Sudah ada:** Kartu peringatan seperti gempa dan banjir serta riwayat.

**Saran:** - Tambahkan halaman detail. - Pisahkan peringatan aktif,
informasi, dan riwayat. - Tampilkan waktu penerbitan dan pembaruan. -
Sediakan filter jenis bencana dan wilayah jika datanya memadai. -
Gunakan warna bersama teks dan ikon; jangan hanya mengandalkan warna.

### 8.5 Peta risiko

**Sudah ada:** Peta, pencarian wilayah, legenda risiko
rendah/sedang/tinggi, dan ringkasan risiko lokasi.

**Saran:** - Jelaskan sumber dan tanggal data risiko. - Bedakan layer
zona risiko, titik kejadian, lokasi evakuasi, dan fasilitas bantuan. -
Sediakan tombol untuk menyalakan/mematikan layer. - Berikan keterangan
bahwa zona risiko bukan prediksi pasti untuk kejadian pada waktu
tertentu. - Tambahkan status lokasi yang sedang dipilih dan alternatif
daftar lokasi jika peta gagal dimuat.

### 8.6 Keluarga & Bantuan

**Sudah ada:** Tombol status aman/butuh bantuan, pesan kondisi, anggota
keluarga, kontak darurat, dan lokasi bantuan.

**Saran:** - Buat alur undangan/bergabung keluarga yang aman. -
Tampilkan kapan status anggota terakhir diperbarui. - Bedakan "belum
terhubung", "belum ada konfirmasi", dan "membutuhkan bantuan". -
Jelaskan siapa yang menerima status dan lokasi. - Tambahkan tindakan
untuk memperbarui status dengan cepat. - Pastikan lokasi bantuan dan
nomor telepon memiliki sumber yang dapat diverifikasi.

### 8.7 Profil dan pengaturan

**Sudah ada:** Data profil, kontak darurat, preferensi notifikasi,
lokasi utama, aksesibilitas, dan keamanan akun.

**Saran:** - Pisahkan data profil dari izin lokasi dan preferensi
notifikasi. - Tambahkan pengelolaan persetujuan privasi. - Tambahkan
pilihan mengunduh atau menghapus akun/data sesuai kebijakan yang
berlaku. - Beri penjelasan singkat untuk setiap izin dan preferensi.

------------------------------------------------------------------------

## 9. Kebutuhan Data dan Sumber Informasi

SIGAP perlu menentukan sumber data sebelum integrasi dikembangkan.
Sumber yang dapat ditinjau antara lain: - **BMKG** untuk informasi dan
peringatan terkait meteorologi, klimatologi, gempa bumi, atau tsunami
sesuai layanan data yang tersedia. - **BPBD Kota Padang/BPBD Sumatera
Barat** untuk informasi kebencanaan daerah, posko, dan informasi
penanganan sesuai kewenangan dan ketersediaan data. - **BNPB** untuk
data dan informasi kebencanaan sesuai layanan yang tersedia. -
**Basarnas dan instansi layanan terkait** untuk informasi layanan
pencarian/pertolongan sesuai kanal resmi. - **Pemerintah daerah atau
pengelola fasilitas** untuk data titik evakuasi, fasilitas kesehatan,
dan lokasi bantuan yang telah divalidasi. - **Peta dasar** dari penyedia
yang lisensi, syarat penggunaan, atribusi, dan batas aksesnya telah
diperiksa.

Daftar di atas adalah kandidat sumber untuk ditinjau, bukan pernyataan
bahwa API tertentu pasti tersedia atau boleh digunakan. Sebelum
implementasi, tim harus memeriksa dokumentasi, izin penggunaan, batas
permintaan, format data, SLA, dan mekanisme pembaruan setiap sumber.

### 9.1 Metadata minimum

Untuk setiap item informasi, simpan jika tersedia: - ID unik. - Jenis
data. - Judul/deskripsi. - Wilayah dan koordinat. - Penerbit/sumber. -
URL sumber. - Waktu kejadian (jika relevan). - Waktu diterbitkan. -
Waktu terakhir diperbarui. - Waktu berakhir atau status aktif. - Status
verifikasi. - Waktu terakhir data berhasil diambil oleh SIGAP.

### 9.2 Jika sumber data tidak tersedia

-   Jangan mengarang informasi untuk mengisi dashboard.
-   Tampilkan waktu pembaruan terakhir dan keterangan data tidak
    tersedia.
-   Sediakan panduan keselamatan dasar yang sudah ditinjau.
-   Arahkan pengguna ke kanal resmi yang relevan.
-   Jangan menyebut data sebagai real-time jika pembaruannya tidak
    real-time.

------------------------------------------------------------------------

## 10. Persyaratan Nonfungsional

### NFR-01 --- Performa

-   Halaman utama menampilkan kerangka konten dengan cepat pada
    perangkat dan jaringan yang wajar.
-   Daftar berita/peringatan menggunakan pagination atau pemuatan
    bertahap jika diperlukan.
-   Peta dan gambar dimuat secara efisien.
-   Target performa kuantitatif ditetapkan dan diuji pada perangkat
    serta jaringan sasaran sebelum rilis.

### NFR-02 --- Ketersediaan dan ketahanan

-   Kegagalan satu sumber data tidak boleh membuat seluruh aplikasi
    tidak dapat dibuka.
-   Kesalahan API ditangani dengan pesan yang mudah dimengerti.
-   Informasi terakhir yang tersimpan dapat ditampilkan dengan cap waktu
    dan label bahwa data mungkin sudah tidak terbaru.
-   Sistem tidak boleh menampilkan data cache seolah-olah data langsung
    terkini.

### NFR-03 --- Keamanan

-   Gunakan HTTPS untuk komunikasi jaringan.
-   Kata sandi tidak disimpan sebagai teks biasa; gunakan mekanisme
    hashing yang aman di backend.
-   Terapkan otorisasi untuk data keluarga dan data pribadi.
-   Validasi input di sisi aplikasi dan server.
-   Terapkan pembatasan percobaan login dan perlindungan terhadap
    penyalahgunaan.
-   Simpan rahasia API di server atau pengelola rahasia, bukan di
    aplikasi mobile.
-   Catat aktivitas admin yang berdampak pada informasi publik.
-   Lakukan pengujian keamanan sebelum rilis.

### NFR-04 --- Privasi

-   Jelaskan tujuan pengumpulan data sebelum meminta persetujuan.
-   Minta izin lokasi hanya ketika diperlukan.
-   Sediakan pilihan memasukkan wilayah secara manual.
-   Jangan membagikan lokasi rinci kepada anggota lain tanpa persetujuan
    yang jelas.
-   Tetapkan masa penyimpanan, mekanisme penghapusan, dan akses terhadap
    data pribadi.
-   Terapkan prinsip minimisasi data serta tinjau kepatuhan terhadap
    peraturan perlindungan data yang berlaku di Indonesia.

### NFR-05 --- Aksesibilitas dan kemudahan penggunaan

-   Kontras teks dan latar harus memadai.
-   Ukuran teks dapat dibaca dan elemen interaktif cukup besar.
-   Status penting memiliki label teks dan ikon selain warna.
-   Dukungan screen reader dan ukuran teks sistem dipertimbangkan.
-   Gunakan bahasa Indonesia yang ringkas, tidak ambigu, dan konsisten.
-   Hindari animasi berlebihan yang memperlambat akses informasi.

### NFR-06 --- Kompatibilitas

-   Android mendukung versi OS yang ditentukan berdasarkan perangkat
    sasaran dan hasil pengujian.
-   Website diuji pada browser desktop modern yang umum digunakan.
-   Website responsif untuk ukuran layar berbeda.
-   Perilaku inti dan status data konsisten antarplatform.

### NFR-07 --- Pemeliharaan

-   Kode dipisah berdasarkan fitur dan tanggung jawab.
-   API dan model data terdokumentasi.
-   Integrasi sumber data memiliki penanganan error, logging, dan
    pengujian.
-   Konfigurasi lingkungan pengembangan, pengujian, dan produksi
    dipisahkan.

------------------------------------------------------------------------

## 11. Rekomendasi Arsitektur Teknis

### 11.1 Gambaran arsitektur

-   **Mobile:** Flutter (Dart).
-   **Website:** aplikasi web terpisah atau frontend web responsif.
-   **Backend/API:** layanan server sebagai pusat autentikasi, data
    pengguna, data keluarga, berita, peringatan, dan lokasi bantuan.
-   **Database:** basis data relasional seperti PostgreSQL atau
    MySQL/MariaDB, dipilih berdasarkan kebutuhan dan kemampuan tim.
-   **Peta:** penyedia peta yang mendukung layer, marker, dan atribusi
    sesuai lisensi.
-   **Notifikasi:** layanan push notification untuk Android dan kanal
    notifikasi website jika diperlukan.
-   **Integrasi eksternal:** konektor server-side ke sumber resmi yang
    telah diperiksa.
-   **Penyimpanan file:** penyimpanan terkontrol untuk foto laporan jika
    fitur pelaporan diaktifkan.

### 11.2 Rekomendasi struktur Flutter

Gunakan pemisahan berdasarkan fitur agar kode tidak menumpuk dalam satu
file.

Contoh struktur awal:

``` text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  core/
    config/
    errors/
    network/
    storage/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    alerts/
      data/
      domain/
      presentation/
    news/
      data/
      domain/
      presentation/
    risk_map/
      data/
      domain/
      presentation/
    family/
      data/
      domain/
      presentation/
    assistance/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    settings/
      data/
      domain/
      presentation/
```

Struktur ini merupakan rekomendasi awal, bukan keharusan. Untuk proyek
mahasiswa, implementasi dapat dimulai lebih sederhana, tetapi pemisahan
API, model, logika, dan UI sebaiknya tetap dijaga.

### 11.3 Prinsip backend

-   Mobile dan website mengakses backend melalui API yang terautentikasi
    sesuai kebutuhan.
-   API menjadi tempat utama validasi dan otorisasi.
-   Integrasi sumber eksternal dilakukan di server agar token/rahasia
    tidak tertanam di aplikasi.
-   Backend menyimpan metadata sumber dan waktu pembaruan.
-   Data keluarga dipisahkan dari data publik.
-   Endpoint admin dilindungi dengan role-based access control.

### 11.4 Contoh kelompok endpoint API

Nama endpoint berikut hanya rancangan awal yang perlu disesuaikan saat
desain backend:

``` text
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/me
PATCH  /api/me

GET    /api/alerts
GET    /api/alerts/{id}
GET    /api/news
GET    /api/news/{id}

GET    /api/risk-zones
GET    /api/map/locations
GET    /api/assistance-points

GET    /api/families
POST   /api/families
POST   /api/families/{id}/invitations
GET    /api/families/{id}/members
POST   /api/families/{id}/status

GET    /api/emergency-contacts
GET    /api/guides
GET    /api/notification-preferences
PATCH  /api/notification-preferences
```

Endpoint pelaporan dan administrasi ditambahkan setelah alur moderasi,
otorisasi, dan tanggung jawab pengelolaan ditetapkan.

------------------------------------------------------------------------

## 12. Model Data Konseptual

Model ini merupakan gambaran awal dan masih perlu disesuaikan dengan
sumber data yang benar-benar digunakan.

  -----------------------------------------------------------------------------
  Entitas                  Data inti                    Keterangan
  ------------------------ ---------------------------- -----------------------
  User                     id, name, email,             Data akun; kata sandi
                           password_hash/provider_id,   hanya disimpan dalam
                           created_at                   bentuk hash aman

  UserProfile              user_id, phone, photo,       Data profil opsional
                           primary_area                 

  Alert                    id, type, title,             Informasi peringatan
                           description,                 
                           severity/status, area,       
                           source_id, published_at,     
                           updated_at, expires_at       

  Source                   id, name, source_url,        Identitas dan metadata
                           source_type, checked_at      sumber

  NewsArticle              id, title,                   Berita/pembaruan
                           summary/content_url,         
                           category, area, source_id,   
                           published_at                 

  RiskZone                 id, name, hazard_type,       Zona risiko dan
                           geometry/reference,          metadata
                           risk_level, source_id,       
                           updated_at                   

  AssistancePoint          id, name, category, address, Titik bantuan
                           latitude, longitude, phone,  
                           verification_status,         
                           source_id                    

  FamilyGroup              id, name, created_by,        Grup keluarga
                           created_at                   

  FamilyMembership         family_id, user_id, role,    Hubungan pengguna dan
                           joined_at                    keluarga

  SafetyStatus             id, family_id, user_id,      Status aman/bantuan dan
                           status, message, created_at  waktunya

  NotificationPreference   user_id, alert_enabled,      Preferensi notifikasi
                           news_enabled, family_enabled 

  IncidentReport (P1)      id, user_id, category,       Laporan masyarakat yang
                           description, location,       dimoderasi
                           media_reference, status,     
                           reviewed_by, timestamps      

  AuditLog (admin)         id, actor_id, action,        Catatan perubahan
                           entity_type, entity_id,      penting
                           created_at                   
  -----------------------------------------------------------------------------

Data lokasi keluarga, laporan, dan media dapat memiliki risiko privasi
tinggi. Akses, retensi, dan penghapusannya harus diatur sejak desain.

------------------------------------------------------------------------

## 13. Metrik Keberhasilan

Metrik harus digunakan untuk menilai kualitas produk, bukan sebagai
klaim bahwa SIGAP menjamin keselamatan.

### Metrik MVP

-   Persentase pengguna uji yang berhasil menemukan detail peringatan
    tanpa bantuan.
-   Waktu yang diperlukan pengguna uji untuk menemukan kontak bantuan.
-   Persentase item informasi yang menampilkan sumber dan waktu
    pembaruan.
-   Tingkat keberhasilan pengguna menyelesaikan alur status aman.
-   Tingkat kegagalan API dan pemuatan halaman.
-   Tingkat notifikasi gagal terkirim jika sistem notifikasi digunakan.
-   Jumlah laporan keliru/duplikat setelah fitur pelaporan diluncurkan.
-   Hasil uji aksesibilitas dan usability.

Target numerik ditentukan setelah pengujian awal bersama calon pengguna
dan pemangku kepentingan. Jangan menetapkan target operasional yang
tidak dapat diukur oleh tim.

------------------------------------------------------------------------

## 14. Rencana Pengujian dan Kriteria Penerimaan

### 14.1 Pengujian fungsional

-   Registrasi, login, logout, dan pemulihan akun.
-   Dashboard saat data tersedia, kosong, terlambat, dan gagal dimuat.
-   Daftar serta detail peringatan.
-   Filter dan navigasi peta.
-   Tampilan detail lokasi bantuan.
-   Pembuatan grup, undangan anggota, dan pengiriman status keluarga.
-   Pengaturan notifikasi dan izin lokasi.
-   Konsistensi data pada mobile dan website.

### 14.2 Pengujian keamanan dan privasi

-   Pengguna tidak dapat membuka data keluarga yang bukan haknya.
-   Pengguna tidak dapat mengubah data pengguna lain.
-   Endpoint admin menolak pengguna tanpa hak.
-   Data sensitif tidak muncul dalam log atau pesan error.
-   Pengiriman lokasi memerlukan persetujuan dan tindakan yang jelas.
-   Token dan rahasia tidak ditanamkan dalam kode klien.

### 14.3 Pengujian kondisi jaringan

-   Jaringan lambat.
-   Koneksi terputus saat membuka detail.
-   Sumber eksternal gagal merespons.
-   Data cache sudah lama.
-   Pengguna membuka panduan yang tersimpan saat offline.

### 14.4 Pengujian usability

Libatkan calon pengguna yang beragam. Minta mereka menyelesaikan
skenario: 1. Menemukan peringatan aktif. 2. Memastikan sumber informasi.
3. Menemukan titik evakuasi. 4. Mengirim status aman. 5. Menemukan
panduan untuk satu jenis bencana.

Catat waktu penyelesaian, kesalahan, bagian yang membingungkan, dan
masukan pengguna.

### 14.5 Syarat minimum rilis MVP

-   Fitur P0 yang disepakati telah diuji.
-   Sumber data, lisensi, dan pembaruan telah diperiksa.
-   Tidak ada data peringatan atau lokasi bantuan contoh yang tertinggal
    seolah-olah nyata.
-   Pesan error dan kondisi data usang ditangani.
-   Privasi, izin lokasi, serta akses keluarga telah diuji.
-   Kontak dan panduan keselamatan telah ditinjau.
-   Ada cara menghubungi pengelola atau melaporkan masalah informasi.

------------------------------------------------------------------------

## 15. Risiko Produk dan Mitigasi

  -----------------------------------------------------------------------
  Risiko                  Dampak                  Mitigasi
  ----------------------- ----------------------- -----------------------
  Sumber informasi tidak  Informasi tidak lengkap Tampilkan sumber dan
  tersedia atau terlambat atau usang              waktu pembaruan;
                                                  gunakan fallback yang
                                                  jujur

  Data contoh dianggap    Pengguna salah          Label data demo dengan
  sebagai data nyata      mengambil keputusan     jelas dan hapus sebelum
                                                  produksi

  Lokasi evakuasi tidak   Pengguna menuju tempat  Validasi dengan
  akurat                  yang salah              pengelola berwenang dan
                                                  catat tanggal
                                                  verifikasi

  Status keluarga lama    Rasa aman yang keliru   Tampilkan waktu status
  dianggap terkini                                dan label "belum ada
                                                  konfirmasi"

  Laporan palsu atau      Kepanikan dan informasi Moderasi, status
  duplikat                menyesatkan             verifikasi, dan audit

  Kebocoran lokasi atau   Risiko privasi dan      Izin granular, kontrol
  data keluarga           keselamatan             akses, minimisasi data,
                                                  dan pengujian keamanan

  Notifikasi terlalu      Pengguna mengabaikan    Prioritaskan
  sering                  peringatan penting      notifikasi,
                                                  deduplikasi, dan
                                                  kontrol preferensi

  Koneksi internet buruk  Fitur tidak bisa        Cache panduan,
  saat bencana            digunakan               informasi dasar
                                                  offline, dan tampilan
                                                  error yang jelas

  Ketergantungan pada     Gangguan informasi      Desain integrasi
  satu penyedia data                              modular dan
                                                  dokumentasikan fallback

  Pengguna mengira SIGAP  Salah persepsi          Jelaskan posisi produk
  adalah otoritas resmi                           dan tampilkan sumber
                                                  resmi secara konsisten
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 16. Prioritas Pengembangan

### Tahap 1 --- Fondasi

-   Validasi kebutuhan calon pengguna dan ruang lingkup Kota Padang.
-   Menentukan sumber data resmi serta izin penggunaannya.
-   Menetapkan desain sistem, model data, dan backend.
-   Menyempurnakan design system dan alur navigasi.

### Tahap 2 --- MVP informasi

-   Autentikasi dan profil.
-   Dashboard.
-   Peringatan dan berita dengan sumber serta waktu pembaruan.
-   Peta dan lokasi bantuan yang datanya sudah tersedia dan tervalidasi.
-   Panduan keselamatan.
-   Pengujian dasar Android dan website.

### Tahap 3 --- Fitur keluarga

-   Grup keluarga dan undangan.
-   Status aman/membutuhkan bantuan.
-   Preferensi notifikasi dan pengujian privasi.
-   Uji coba dengan calon pengguna.

### Tahap 4 --- Penguatan

-   Peningkatan akses offline.
-   Penyempurnaan aksesibilitas.
-   Evaluasi usability.
-   Monitoring performa dan keamanan.

### Tahap 5 --- Fitur lanjutan

-   Pelaporan masyarakat.
-   Panel moderasi/admin.
-   Pemberitahuan berbasis wilayah.
-   Integrasi tambahan setelah sumber dan proses operasional
    terverifikasi.

Urutan ini adalah rekomendasi. Prioritas final harus disesuaikan dengan
waktu pengerjaan, kemampuan tim, dan ketersediaan sumber data.

------------------------------------------------------------------------

## 17. Pertanyaan yang Harus Diputuskan Sebelum Implementasi

1.  Sumber resmi mana yang benar-benar akan digunakan untuk peringatan,
    berita, zona risiko, dan lokasi evakuasi?
2.  Apakah berita hanya ditautkan dari sumber asli, diringkas, atau
    dikelola melalui panel admin?
3.  Siapa yang bertanggung jawab memverifikasi titik evakuasi, posko,
    rumah sakit, dan kontak darurat?
4.  Apakah status keluarga hanya dibagikan kepada anggota keluarga atau
    juga kepada petugas?
5.  Apakah akun wajib untuk membaca peringatan dan panduan dasar?
    Rekomendasi: jangan mewajibkan akun untuk informasi keselamatan
    publik.
6.  Apakah pelaporan warga masuk MVP atau tahap berikutnya? Rekomendasi:
    setelah proses moderasi tersedia.
7.  Apakah peta risiko menggunakan data statis resmi, layanan API, atau
    keduanya?
8.  Bagaimana kebijakan privasi, masa simpan data, penghapusan akun, dan
    pengelolaan lokasi?
9.  Siapa yang mengelola aplikasi dan menangani koreksi informasi
    setelah proyek diluncurkan?
10. Apa batas dukungan operasional jika proyek awalnya merupakan proyek
    akademik?

------------------------------------------------------------------------

## 18. Saran Akhir untuk Pengembangan SIGAP

Prioritas paling penting bukan menambahkan sebanyak mungkin fitur,
melainkan memastikan fitur inti bekerja dengan benar. Untuk versi
pertama, fokus pada peringatan dan berita bersumber jelas, dashboard,
peta yang memiliki legenda dan data valid, lokasi bantuan terverifikasi,
panduan keselamatan, serta status keluarga yang aman dan mudah dipahami.

Dari sisi desain, pertahankan identitas hijau-krem dan pola dashboard
yang sudah dibuat. Perbaiki hierarki informasi darurat, keterbacaan,
status pembaruan, penjelasan sumber, dan alur tindakan. Jangan
menampilkan peta risiko, tingkat bahaya, atau lokasi evakuasi sebagai
data nyata sebelum sumbernya benar-benar tersedia dan divalidasi.

Dari sisi teknis, Flutter cocok untuk aplikasi Android, sementara
website sebaiknya memakai backend/API yang sama agar data dan aturan
bisnis tidak berbeda. Tentukan teknologi website dan backend setelah
mempertimbangkan kemampuan tim. Pisahkan integrasi sumber data dari
antarmuka agar sumber dapat diganti tanpa membangun ulang seluruh
aplikasi.

**Definisi keberhasilan MVP:** pengguna di Kota Padang dapat menemukan
informasi bencana yang sumbernya jelas, memahami tindakan yang perlu
dilakukan, menemukan bantuan yang telah diverifikasi, dan membagikan
status kepada keluarga tanpa aplikasi memberikan klaim keselamatan yang
tidak dapat dijamin.

------------------------------------------------------------------------

## Lampiran A --- Pemetaan Wireframe ke Kebutuhan Produk

  -----------------------------------------------------------------------
  Elemen wireframe        Status dalam PRD        Catatan pengembangan
  ----------------------- ----------------------- -----------------------
  Splash screen SIGAP     Dipertahankan           Ringkas dan tidak
                                                  menghambat akses
                                                  informasi penting

  Registrasi dan login    P0                      Tambahkan pemulihan
                                                  akun dan penjelasan
                                                  privasi

  Dashboard               P0                      Tambahkan sumber, waktu
                                                  pembaruan, serta
                                                  kondisi data gagal

  Peringatan bencana      P0                      Tambahkan detail,
                                                  filter, sumber, dan
                                                  status aktif/riwayat

  Peta risiko             P0                      Perlu data valid,
                                                  legenda, layer, dan
                                                  metadata sumber

  Profil                  P0                      Minimalkan data pribadi
                                                  yang wajib diisi

  Pengaturan notifikasi   P0/P1                   Minta izin dengan
                                                  konteks dan hindari
                                                  notifikasi berulang

  Keluarga & Bantuan      P0                      Perlu undangan aman,
                                                  waktu status, dan
                                                  kontrol privasi

  Kontak darurat          P0                      Verifikasi nomor dan
                                                  sumbernya

  Titik evakuasi/RS/posko P0                      Validasi lokasi dan
                                                  tanggal pembaruan

  Berita kebencanaan      P0                      Bedakan berita, laporan
                                                  warga, dan peringatan
                                                  resmi

  Status aman/butuh       P0                      Status harus memiliki
  bantuan                                         waktu konfirmasi

  Pelaporan kejadian      P1                      Memerlukan moderasi dan
  warga                                           label belum
                                                  terverifikasi

  Panel admin             P1                      Diperlukan jika laporan
                                                  dan konten dikelola
                                                  internal
  -----------------------------------------------------------------------

## Lampiran B --- Glosarium

-   **PRD (Product Requirements Document):** dokumen yang menjelaskan
    kebutuhan produk, fitur, perilaku sistem, prioritas, dan kriteria
    penerimaan.
-   **MVP (Minimum Viable Product):** versi awal dengan fitur minimum
    yang cukup untuk diuji kepada pengguna.
-   **API:** jalur komunikasi terstruktur antara aplikasi, backend, dan
    sumber data.
-   **Backend:** bagian sistem yang mengelola logika, autentikasi,
    penyimpanan, dan integrasi.
-   **Layer peta:** kelompok informasi yang dapat ditampilkan atau
    disembunyikan di atas peta dasar.
-   **Status terverifikasi:** status informasi setelah pemeriksaan
    sesuai proses dan kewenangan yang ditetapkan.
-   **Data usang:** data yang waktu pembaruannya sudah melewati batas
    yang ditentukan atau tidak dapat dipastikan masih berlaku.
