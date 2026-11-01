BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

# BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

Oct 24, 2026 · @Vinn 

## 1. Pendahuluan 

SIGAP adalah aplikasi kesiapsiagaan bencana untuk warga Kota Padang, tersedia di Android dan web (PC), dan dokumen ini menetapkan kebutuhan bisnisnya berdasarkan 18 layar mockup yang sudah dibuat (10 layar mobile, 8 layar web). 

**Filosofi.** SIGAP berarti warga harus sigap menghadapi bahaya bencana alam: peduli lingkungan sekitar dan siap sebelum bencana terjadi, bukan hanya bereaksi sesudahnya. 

**Tujuan dokumen.** Menjadi acuan bersama antara pemilik produk, desainer, dan developer tentang apa yang harus dibangun, untuk siapa, dan seberapa penting. 

**Dasar penyusunan.** Dokumen ini disusun dari dua sumber: mockup Mobile dan mockup Web SIGAP, serta penjelasan Anda bahwa aplikasi mencakup Kota Padang saja dan memiliki platform berita kebencanaan seperti BMKG versi Padang. Platform berita itu belum tergambar di mockup, jadi ditandai sebagai kebutuhan baru. 

**Cara membaca status.** Setiap kebutuhan diberi status mockup: _Ada_ (sudah tergambar), _Sebagian_ (tergambar tapi belum lengkap), atau _Belum ada_ (belum tergambar sama sekali). 

## 2. Latar Belakang dan Tujuan Bisnis 

Kota Padang terpapar banyak ancaman sekaligus: gempa bumi, tsunami karena letaknya di pesisir barat Sumatera, banjir sungai, dan longsor di wilayah perbukitan. Informasi bencana saat ini tersebar di banyak kanal (BMKG, BPBD, media sosial) dan tidak terhubung dengan kebutuhan warga: apakah keluarga saya aman, di mana posko terdekat, dan apa yang harus saya lakukan sekarang. 

### **Masalah yang diselesaikan** 

- Peringatan resmi tidak selalu sampai ke warga tepat waktu dan tidak spesifik ke lokasi mereka. 

- Saat bencana, warga sulit mengetahui kondisi anggota keluarga, terutama jika jaringan telepon padat. 

- Warga tidak tahu posko, rumah sakit, atau jalur evakuasi terdekat. 

- Belum ada satu sumber berita kebencanaan yang fokus pada Kota Padang. 

### **Tujuan bisnis** 

Page 1 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Kode|Tujuan|Indikator keberhasilan (usulan, perlu<br>disepakati)|
|---|---|---|
|T1|Warga menerima peringatan bencana<br>yang relevan dengan lokasinya|Persentase pengguna yang<br>mengaktifkan notifikasi darurat|
|T2|Keluarga dapat saling memantau status<br>aman saat bencana|Jumlah pengguna yang menautkan<br>minimal 1 orang terdekat|
|T3|Warga menemukan posko dan layanan<br>bantuan terdekat|Jumlah penggunaan fitur peta evakuasi<br>dan tombol hubungi|
|T4|Menjadi sumber berita kebencanaan<br>Kota Padang|Jumlah pembaca berita per bulan|
|T5|Meningkatkan budaya siaga di<br>masyarakat|Jumlah pengguna aktif bulanan di Kota<br>Padang|



## 3. Ruang Lingkup 

SIGAP hanya melayani wilayah Kota Padang, dalam dua platform: aplikasi Android dan website untuk PC. 

### **Dalam lingkup (in-scope)** 

- Autentikasi pengguna (daftar, masuk, profil, pengaturan akun). 

- Dashboard kondisi terkini dan tindakan cepat. 

- Peringatan bencana beserta riwayatnya. 

- Peta risiko wilayah Kota Padang. 

- Keluarga & Bantuan: status aman, orang terdekat, kontak darurat, posko terdekat. Portal berita dan informasi kebencanaan Kota Padang (setara BMKG versi Padang). Panel admin untuk petugas yang menerbitkan peringatan dan berita. 

### **Di luar lingkup (out-of-scope) untuk rilis awal** 

- Wilayah di luar Kota Padang. 

- Aplikasi iOS. 

- Panggilan darurat otomatis (mockup sudah menegaskan: "tidak ada panggilan otomatis"). 

- Pengiriman bantuan atau donasi. 

- Prediksi bencana buatan sendiri; SIGAP hanya meneruskan data dari sumber resmi. 

### **Jenis bencana yang dicakup (usulan)** 

Page 2 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

Mockup baru menampilkan gempa, banjir, dan longsor. Untuk Kota Padang sebaiknya ditambah tsunami, karena risikonya tinggi dan membutuhkan peringatan serta jalur evakuasi khusus. Keputusan ini perlu Anda konfirmasi. 

## 4. Stakeholder dan Profil Pengguna 

SIGAP melayani empat kelompok pengguna, dan satu kelompok di antaranya (petugas) belum punya layar sama sekali di mockup. 

|Peran|Kebutuhan utama|Platform<br>utama|Ada di<br>mockup?|
|---|---|---|---|
|Warga umum|Menerima peringatan, menandai<br>status aman, melihat peta risiko<br>dan posko|Mobile|Ada|
|Anggota keluarga / orang<br>terdekat|Memantau status orang yang<br>ditautkan, menghubungi mereka|Mobile|Ada|
|Pembaca berita<br>(termasuk tanpa akun)|Membaca berita dan informasi<br>kebencanaan Padang|Web dan<br>mobile|Belum ada|
|Admin / petugas (BPBD,<br>relawan, editor)|Menerbitkan peringatan, berita,<br>data posko; memantau<br>pengguna|Web|Belum ada|



### **Pihak berkepentingan lain (perlu dikonfirmasi keterlibatannya)** 

- BPBD Kota Padang dan BMKG sebagai sumber data resmi dan calon mitra. 

Tim pengembang dan pemilik proyek SIGAP. 

- Penyedia layanan notifikasi, peta, dan SMS. 

## 5. Analisis Mockup Versi Mobile (Android) 

Versi mobile punya 10 layar dengan navigasi bawah empat tab (Dashboard, Peringatan, Peta risiko, Keluarga & Bantuan) dan akses Pengaturan serta Profil lewat ikon di header. Gaya visualnya konsisten: hijau tua dan krem, kartu bersudut membulat, dan label status berwarna. 

Page 3 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Layar|Isi yang tergambar|Catatan analisis|
|---|---|---|
|Splash|Logo SIGAP, tagline "Sistem<br>informasi bencana", indikator<br>"Memuat..."|Cukup. Belum ada onboarding<br>sesudahnya.|
|Register|Daftar via Google, Facebook, atau<br>email; nama, email, sandi; kotak<br>manfaat|Tidak ada persetujuan syarat dan<br>privasi, tidak ada nomor telepon<br>(padahal Profil memakainya).|
|Login|Masuk via Google, Facebook, atau<br>email dan sandi|Tidak ada "Lupa sandi".|
|Dashboard|Waktu "PDG", peringatan paling<br>mendesak, risiko lokasi, 4<br>tindakan cepat (Saya aman, Butuh<br>bantuan, Peta risiko, Hubungi<br>darurat), keluarga, pembaruan<br>terakhir|Inti aplikasi dan sudah kuat. Kartu<br>evakuasi terdekat yang ada di web<br>belum ada di mobile.|
|Peringatan|Daftar aktif (Gempa M5.8 "Siaga",<br>Banjir "Waspada") dan riwayat|Belum ada layar detail, padahal ada<br>tautan "detail".|
|Peta risiko|Pencarian wilayah, filter jenis<br>risiko, peta dengan penanda<br>Banjir, Gempa, Longsor, legenda,<br>kartu risiko lokasi|Peta masih placeholder. Kartu<br>"Risiko sedang" hanya menyebut<br>banjir.|
|Keluarga &<br>Bantuan|Cara pakai 3 langkah, status saya,<br>ringkasan orang terdekat, kontak<br>darurat, bantuan sekitar (RSUD,<br>SAR, dapur umum), nomor 112|Fitur paling berbeda dari aplikasi<br>sejenis dan perlu dijaga. Panjang,<br>perlu dicek keterbacaannya.|
|Pengaturan|Preferensi notifikasi, kontak<br>darurat, orang terdekat, lokasi<br>utama, aksesibilitas, keamanan<br>akun|Belum ada keluar akun, bahasa, atau<br>hapus akun.|
|Profil|Foto, nama, telepon, email, alamat|Alamat berupa teks bebas, belum<br>terhubung ke kelurahan atau<br>kecamatan untuk risiko.|



### **Kekuatan** 

Alur "Saya aman" satu ketukan dan tidak ada panggilan otomatis, jadi aman dari salah pencet. 

Lokasi hanya dibagikan jika pengguna memilih. 

Page 4 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

Catatan kejujuran: "Belum terhubung bukan berarti dalam bahaya" mencegah kepanikan. 

Fitur aksesibilitas (teks besar, pendamping evakuasi) sudah dipikirkan sejak awal. 

## 6. Analisis Mockup Versi Web (PC) 

Versi web punya 8 layar dengan sidebar kiri (Dashboard, Peringatan, Peta risiko, Keluarga & Bantuan; Pengaturan dan Profil di bawah). Layoutnya memanfaatkan lebar layar dengan dua kolom, dan identitas visualnya sama dengan mobile. 

|Layar|Perbedaan dari mobile|Catatan analisis|
|---|---|---|
|Register dan<br>Login|Layar terbagi dua: panel hijau<br>berisi pesan, panel krem berisi<br>formulir|Konsisten dengan mobile. Panel kiri<br>Register punya blok yang<br>terpotong di bagian bawah.|
|Dashboard|Ada kartu**Evakuasi terdekat**<br>(GOR Agus Salim, 1,4 km, tombol<br>Lihat rute) yang tidak ada di<br>mobile|Judul "Keluarga & Bantuan"<br>terpotong. Layar ini lebih informatif<br>dari versi mobile.|
|Peringatan|Sama dengan mobile, ditampilkan<br>lebih luas|Area kosong besar di bawah; belum<br>ada panel detail di samping daftar.|
|Peta risiko|Peta lebar, filter, legenda, kartu<br>lokasi|Masih placeholder, penanda tidak<br>interaktif.|
|Keluarga &<br>Bantuan|Dua kolom: status dan orang<br>terdekat di kiri, kontak, bantuan<br>sekitar, 112 di kanan|Label "BELUM TERHUBUNG" dan<br>"PERLU KONFIRMASI" terpotong di<br>kartu.|
|Pengaturan|Kontak darurat, orang terdekat,<br>lokasi di kiri; notifikasi,<br>aksesibilitas, keamanan di kanan|Ada satu tombol Simpan untuk<br>semua isi halaman.|
|Profil|Formulir ringkas|Halaman paling kosong; sidebar<br>menulis "Peringa tan" terpecah dan<br>"Profile" tidak seragam dengan<br>"Profil".|



### **Ketidakkonsistenan mobile dan web yang perlu diputuskan** 

- Splash screen hanya ada di mobile (wajar), tetapi kartu evakuasi hanya ada di web. 

- Mobile memakai navigasi bawah dan ikon header; web memakai sidebar. Pola ini wajar, selama daftar menu sama persis. 

Page 5 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

Penulisan "Profil" dan "Profile" serta "Peringatan" yang terpecah menunjukkan komponen sidebar perlu dirapikan. 

## 7. Kebutuhan Fungsional 

Terdapat 42 kebutuhan fungsional dalam 8 modul. Prioritas memakai MoSCoW: **M** wajib, **S** sebaiknya, **C** bila memungkinkan. Platform: **A** Android, **W** web. 

### **Modul 1: Akun dan Autentikasi** 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-<br>01|Pengguna dapat mendaftar<br>dengan email dan kata sandi|M|A, W|Ada|
|FR-<br>02|Pengguna dapat mendaftar atau<br>masuk dengan akun Google|M|A, W|Ada|
|FR-<br>03|Pengguna dapat masuk dengan<br>akun Facebook|C|A, W|Ada|
|FR-<br>04|Pengguna dapat mereset kata<br>sandi lewat email|M|A, W|Belum ada|
|FR-<br>05|Pendaftaran menampilkan<br>persetujuan syarat dan<br>kebijakan privasi|M|A, W|Belum ada|
|FR-<br>06|Pengguna dapat keluar dari akun<br>dan menghapus akun|M|A, W|Belum ada|
|FR-|Verifikasi dua langkah lewat|S|A, W|Sebagian (hanya status di|
|07|SMS|||Pengaturan)|



### **Modul 2: Dashboard** 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-|Menampilkan peringatan aktif|M|A, W|Ada|
|08|paling mendesak dan waktu<br>pembaruan terakhir||||
|FR-|Menampilkan tingkat risiko lokasi|M|A, W|Ada|
|09|utama pengguna||||



Page 6 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-|Tombol tindakan cepat: Saya aman,|M|A, W|Ada|
|10|Butuh bantuan, Peta risiko, Hubungi<br>darurat||||
|FR-11|Ringkasan status keluarga dan<br>pembaruan terakhir|M|A, W|Ada|
|FR-<br>12|Kartu evakuasi terdekat dengan<br>jarak dan tombol Lihat rute|S|W (usulan: A<br>juga)|Sebagian (hanya<br>web)|



### **Modul 3: Peringatan Bencana** 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-<br>13|Daftar peringatan aktif dengan<br>tingkat (Waspada, Siaga) dan lokasi|M|A, W|Ada|
|FR-<br>14|Riwayat peringatan|S|A, W|Ada|
|FR-<br>15|Halaman detail peringatan:<br>penjelasan, area terdampak,<br>tindakan yang disarankan, sumber,<br>waktu|M|A, W|Belum ada|
|FR-<br>16|Notifikasi dorong (push)<br>peringatan sesuai wilayah dan<br>preferensi pengguna|M|A|Sebagian (hanya<br>pengaturan)|
|FR-<br>17|Peringatan memuat data dari<br>sumber resmi (BMKG, BPBD) dan<br>menyebut sumbernya|M|A, W|Belum ada|



### **Modul 4: Peta Risiko** 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-|Peta interaktif Kota Padang dengan|M|A, W|Sebagian|
|18|lapisan risiko per jenis bencana|||(placeholder)|
|FR-|Pencarian wilayah dan filter jenis|M|A, W|Ada|
|19|risiko||||
|FR-|Legenda tingkat risiko (rendah,|M|A, W|Ada|
|20|sedang, tinggi)||||



Page 7 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-|Kartu risiko di lokasi pengguna|M|A, W|Ada|
|21|||||
|FR-|Lapisan titik evakuasi, posko, dan|M|A, W|Belum ada|
|22|jalur evakuasi||||



### **Modul 5: Keluarga dan Bantuan** 

|ID|Kebutuhan|Prioritas|Platform|Status mockup|
|---|---|---|---|---|
|FR-<br>23|Pengguna memperbarui status<br>(Aman atau Butuh bantuan)<br>dengan pesan opsional|M|A, W|Ada|
|FR-<br>24|Berbagi lokasi hanya bila<br>pengguna mencentang pilihan itu|M|A, W|Ada|
|FR-<br>25|Menambah orang terdekat melalui<br>undangan dan persetujuan dua<br>arah|M|A, W|Sebagian (tombol ada,<br>alur belum)|
|FR-<br>26|Melihat status orang terdekat<br>(Aman, Belum terhubung, Perlu<br>konfirmasi) dan waktu<br>pembaruannya|M|A, W|Ada|
|FR-<br>27|Tombol detail dan hubungi pada<br>tiap orang terdekat|M|A, W|Sebagian (halaman<br>detail belum ada)|
|FR-<br>28|Daftar bantuan sekitar (RSUD, tim<br>SAR, dapur umum) dengan jarak,<br>tombol hubungi dan lokasi|M|A, W|Ada|
|FR-<br>29|Pintasan nomor darurat 112 dan<br>lokasi evakuasi|M|A, W|Ada|



### **Modul 6: Profil dan Pengaturan** 

|ID|Kebutuhan|Prioritas|Platform|Status|
|---|---|---|---|---|
|||||mockup|
|FR-|Mengubah nama, telepon, email, alamat,|M|A, W|Ada|
|30|dan foto profil||||



Page 8 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Kebutuhan|Prioritas|Platform|Status<br>mockup|
|---|---|---|---|---|
|FR-31|Mengelola kontak darurat (utama dan<br>tambahan) tanpa panggilan otomatis|M|A, W|Ada|
|FR-<br>32|Mengatur notifikasi: peringatan darurat,<br>kabar orang terdekat, pembaruan posko|M|A, W|Ada|
|FR-<br>33|Mengatur lokasi utama (rumah)|M|A, W|Ada|
|FR-|Opsi aksesibilitas: teks besar dan|S|A, W|Ada|
|34|pendamping evakuasi||||



### **Modul 7: Berita dan Informasi Kebencanaan Padang (baru)** 

|ID|Kebutuhan|Prioritas|Platform|Status<br>mockup|
|---|---|---|---|---|
|FR-<br>35|Beranda berita: daftar berita terbaru,<br>kategori (gempa, banjir, longsor, tsunami,<br>cuaca), pencarian|M|A, W|Belum ada|
|FR-<br>36|Halaman detail berita dengan sumber,<br>waktu terbit, dan tombol bagikan|M|A, W|Belum ada|
|FR-|Informasi kejadian terkini (misalnya gempa|S|A, W|Belum ada|
|37|terkini) dan prakiraan cuaca untuk Kota<br>Padang||||
|FR-|Halaman edukasi: panduan sebelum, saat,|S|A, W|Belum ada|
|38|dan sesudah bencana||||



### **Modul 8: Panel Admin (baru, web saja)** 

|ID|Kebutuhan|Prioritas|Platform|Status<br>mockup|
|---|---|---|---|---|
|FR-<br>39|Admin dapat membuat, mengubah, dan<br>menerbitkan berita|M|W|Belum ada|
|FR-|Admin dapat menerbitkan peringatan|M|W|Belum ada|
|40|manual dengan tingkat, wilayah, dan<br>tindakan||||



Page 9 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Kebutuhan|Prioritas|Platform|Status<br>mockup|
|---|---|---|---|---|
|FR-41|Admin dapat mengelola data posko, titik<br>evakuasi, dan kontak bantuan|M|W|Belum ada|
|FR-|Pengaturan peran admin (editor, petugas,|S|W|Belum ada|
|42|super admin) dan jejak audit||||



## 8. Kebutuhan Non-Fungsional 

Aplikasi kebencanaan dipakai saat jaringan padat dan listrik bisa padam, jadi keandalan dan kecepatan lebih penting daripada tampilan. Angka target di bawah adalah usulan awal yang perlu disepakati dan diuji. 

|ID|Kategori|Kebutuhan|Target (usulan)|
|---|---|---|---|
|NFR-<br>01|Kinerja|Dashboard dan peringatan<br>termuat cepat di jaringan<br>seluler biasa|Kurang dari 3 detik pada 4G|
|NFR-<br>02|Kecepatan<br>peringatan|Waktu dari peringatan<br>diterbitkan sampai notifikasi<br>diterima|Kurang dari 1 menit|
|NFR-<br>03|Ketersediaan|Layanan tetap berjalan saat<br>lonjakan pengguna ketika<br>bencana|Ketersediaan 99,5% atau<br>lebih; uji beban sebelum rilis|
|NFR-<br>04|Mode offline|Peringatan terakhir, kontak<br>darurat, dan posko tersimpan<br>di perangkat|Dapat dibuka tanpa internet|
|NFR-<br>05|Cadangan<br>jaringan|Status aman dapat dikirim<br>lewat SMS bila data internet<br>tidak tersedia|Perlu dikaji biaya dan<br>penyedia|
|NFR-<br>06|Privasi|Lokasi dan status keluarga<br>hanya dibagikan atas<br>persetujuan pengguna|Sesuai UU Pelindungan Data<br>Pribadi (UU PDP)|
|NFR-<br>07|Keamanan|Kata sandi di-hash,<br>komunikasi terenkripsi,<br>verifikasi dua langkah|HTTPS wajib; sandi tidak<br>disimpan polos|



Page 10 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Kategori|Kebutuhan|Target (usulan)|
|---|---|---|---|
|NFR-<br>08|Aksesibilitas|Teks besar, kontras warna<br>cukup, tombol mudah<br>ditekan, label status tidak<br>hanya bergantung warna|Mengikuti WCAG 2.1 AA|
|NFR-<br>09|Bahasa|Antarmuka berbahasa<br>Indonesia yang sederhana<br>dan konsisten|Bahasa daerah opsional di<br>tahap berikutnya|
|NFR-<br>10|Kompatibilitas|Android dan browser modern<br>di PC|Android 8 ke atas; Chrome,<br>Edge, Firefox, Safari versi<br>terbaru|
|NFR-<br>11|Konsumsi daya|Pemakaian baterai rendah<br>karena dipakai saat listrik<br>padam|Pelacakan lokasi hanya saat<br>dibutuhkan|
|NFR-<br>12|Akurasi data|Setiap peringatan<br>mencantumkan sumber dan<br>waktu pembaruan|Wajib pada semua<br>peringatan|
|NFR-<br>13|Keterpeliharaan|Komponen antarmuka dipakai<br>ulang antar layar dan platform|Satu design system untuk<br>mobile dan web|



## 9. Aturan Bisnis, Asumsi, dan Ketergantungan 

### **Aturan bisnis** 

|ID|Aturan|
|---|---|
|BR-01|Peringatan resmi hanya berasal dari sumber<br>terverifikasi (BMKG, BPBD, atau admin SIGAP);<br>pengguna tidak dapat menerbitkan peringatan.|
|BR-02|Status "Aman" dan lokasi hanya terlihat oleh orang<br>terdekat yang sudah disetujui kedua pihak.|
|BR-03|Lokasi hanya dibagikan jika pengguna mencentang<br>pilihan berbagi lokasi saat mengirim status.|
|BR-04|SIGAP tidak melakukan panggilan otomatis; kontak<br>darurat hanya dihubungi atas tindakan pengguna.|
|BR-05|Status "Belum terhubung" ditampilkan netral dan<br>tidak boleh diartikan sebagai "dalam bahaya".|



Page 11 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|ID|Aturan|
|---|---|
|BR-06|Tingkat peringatan memakai satu skala baku di<br>seluruh aplikasi (usulan: Waspada, Siaga, Awas,<br>mengikuti istilah kebencanaan di Indonesia).|
|BR-07|Data posko dan layanan bantuan hanya diubah oleh<br>admin dan harus mencantumkan tanggal verifikasi<br>terakhir.|
|BR-08|Berita hanya diterbitkan oleh editor yang<br>berwenang dan wajib mencantumkan sumber.|
|BR-09|Cakupan wilayah terbatas pada Kota Padang;<br>pengguna di luar Padang tetap dapat membaca<br>berita tetapi tidak menerima peringatan lokasi.|



### **Asumsi** 

- Data peringatan dan gempa dapat diambil dari sumber resmi lewat API atau umpan data yang tersedia untuk umum. Izin dan lisensi pemakaian perlu dipastikan. 

- Data posko, titik evakuasi, dan peta risiko Kota Padang tersedia atau dapat dikumpulkan dari BPBD dan sumber terbuka. 

- Pengguna memiliki smartphone Android dan akses internet, setidaknya sebagian waktu. 

Aplikasi dikelola oleh tim kecil, jadi fitur dirilis bertahap. 

### **Ketergantungan** 

- Layanan notifikasi dorong (misalnya Firebase Cloud Messaging) untuk Android. 

- Layanan peta dan data geospasial Kota Padang. 

- Layanan SMS dan email untuk verifikasi dan reset sandi. 

- Kerja sama atau izin dari BPBD Kota Padang untuk data dan verifikasi konten. 

## 10. Kekurangan Mockup dan Saran Perbaikan 

Kekurangan terbesar mockup saat ini adalah tidak adanya platform berita kebencanaan dan panel admin, padahal keduanya adalah inti dari tujuan Anda. Selain itu, mockup sudah kuat di sisi keluarga dan kesiapsiagaan pribadi, tetapi belum menjawab kebutuhan khas Kota Padang, terutama tsunami. 

**Status perbaikan.** Sebagian besar kekurangan di bawah sudah digambar di Mockup v2: 

Page 12 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

- Sudah digambar: A1 (Berita), A2 (Panel admin, bagian peringatan), A4 (Detail peringatan), A5 (Peta evakuasi), A6 (Panduan siaga), B5 (Mode darurat), B6 sebagian (kondisi offline di Mode darurat). 

- Sebagian: A3 (tsunami muncul sebagai kategori berita, panduan, dan zona rawan di peta evakuasi, tetapi layar Peta risiko lama belum diperbarui), B7 (belum ada pusat notifikasi). 

- Belum digambar: A7 (daftar kontak darurat lokal), B1 sampai B4 (onboarding, lupa sandi, persetujuan privasi, alur tambah orang terdekat), B8 (lapor kejadian), dan seluruh temuan C (perbaikan teks terpotong dan kontras pada layar lama). 

### **A. Fitur yang belum ada (prioritas tinggi)** 

|No|Kekurangan|Mengapa penting|Saran|
|---|---|---|---|
|A1|Menu**Berita**belum<br>ada|Ini permintaan utama Anda:<br>platform berita seperti<br>BMKG versi Padang|Tambah tab Berita di<br>navigasi bawah (mobile) dan<br>sidebar (web): daftar,<br>kategori, pencarian, detail<br>berita, sumber, tombol<br>bagikan|
|A2|**Panel admin**belum<br>ada|Tanpa admin, tidak ada yang<br>menerbitkan peringatan,<br>berita, dan data posko|Rancang dashboard admin<br>web: kelola berita,<br>peringatan, posko,<br>pengguna, dan jejak audit|
|A3|**Tsunami**belum ada|Padang berada di pesisir<br>barat Sumatera; peringatan<br>tsunami adalah yang paling<br>kritis|Tambah jenis bencana<br>tsunami di peringatan, peta<br>(zona genangan, jalur dan<br>titik kumpul evakuasi), dan<br>notifikasi prioritas tertinggi|
|A4|**Detail peringatan**<br>belum ada|Tautan "detail" dan "lihat<br>peringatan" tidak mengarah<br>ke layar apa pun|Buat layar detail: magnitudo<br>atau tinggi air, area<br>terdampak, tindakan yang<br>disarankan, sumber, waktu,<br>peta kecil|
|A5|**Peta evakuasi dan**<br>**rute**belum ada|Tombol "Lihat rute" dan<br>"Lihat lokasi evakuasi" tidak<br>punya tujuan|Buat layar peta evakuasi:<br>titik kumpul, shelter, posko,<br>dan rute ke titik terdekat|



Page 13 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|No|Kekurangan|Mengapa penting|Saran|
|---|---|---|---|
|A6|**Panduan mitigasi**<br>belum ada|Tujuan SIGAP adalah siap<br>sebelum bencana, bukan<br>hanya bereaksi|Tambah halaman edukasi:<br>apa yang dilakukan sebelum,<br>saat, dan sesudah gempa,<br>tsunami, banjir, dan longsor;<br>tas siaga; simulasi|
|A7|**Nomor darurat**<br>**Padang**hanya 112|Warga butuh kontak lokal|Tambah daftar kontak:<br>BPBD, Basarnas Padang,<br>PMI, rumah sakit, PLN,<br>dengan tombol telepon<br>langsung|



### **B. Alur yang belum lengkap** 

|No|Kekurangan|Saran|
|---|---|---|
|B1|Tidak ada onboarding setelah splash dan<br>register|Tambah 3 layar singkat: tujuan SIGAP, izin<br>lokasi dan notifikasi dengan alasannya,<br>pilih lokasi rumah|
|B2|Tidak ada "Lupa sandi", verifikasi email,<br>keluar akun, hapus akun|Tambah layar dan tombol tersebut|
|B3|Register tidak meminta persetujuan<br>syarat dan privasi, dan tidak<br>mengumpulkan telepon|Tambah kotak persetujuan UU PDP dan<br>kolom telepon (opsional)|
|B4|Alur "Tambah orang terdekat" belum<br>tergambar|Gambar alur undangan lewat nomor atau<br>kode, persetujuan penerima, dan<br>pencabutan tautan|
|B5|Tidak ada keadaan khusus saat bencana<br>berlangsung|Rancang "mode darurat": layar sederhana<br>berisi tombol Saya aman, Butuh bantuan,<br>kontak, dan rute|
|B6|Tidak ada keadaan kosong, memuat,<br>galat, dan offline|Gambar tiap kondisi, terutama "tidak ada<br>internet" dan "belum ada orang terdekat"|
|B7|Tidak ada tampilan notifikasi (di aplikasi<br>dan layar kunci)|Rancang pusat notifikasi dan contoh<br>push peringatan|
|B8|Tidak ada fitur lapor kejadian dari warga|Pertimbangkan tombol "Lapor kejadian"<br>(foto dan lokasi) yang diverifikasi admin<br>sebelum tampil; masuk tahap berikutnya|



Page 14 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

### **C. Desain dan keterbacaan** 

|No|Temuan|Saran|
|---|---|---|
|C1|Teks terpotong: "Keluarga & Bantuan",<br>"BELUM TERHUBUNG", "PERLU<br>KONFIRMASI", "Peringa tan"|Perbaiki lebar komponen dan<br>perbolehkan label dua baris|
|C2|Teks kecil dan abu-abu muda di banyak<br>tempat|Naikkan ukuran dan kontras; sesuai<br>kebutuhan lansia dan kondisi panik|
|C3|Status hanya dibedakan lewat warna di<br>beberapa label|Tambah ikon atau teks pembeda agar<br>terbaca oleh pengguna buta warna|
|C4|Tombol "Saya aman" dan "Butuh bantuan"<br>setara dengan tombol lain di dashboard|Jadikan lebih besar dan menonjol, karena<br>ini tindakan paling penting saat bencana|
|C5|Halaman Profil web hampir kosong|Gabungkan Profil ke Pengaturan, atau isi<br>dengan data keluarga dan riwayat<br>aktivitas|
|C6|Mobile dashboard tidak memuat kartu<br>evakuasi seperti web|Samakan kemampuan kedua platform|
|C7|Peta masih placeholder dan kartu risiko<br>hanya menyebut banjir|Tampilkan risiko semua jenis bencana di<br>lokasi pengguna|



### **D. Konsistensi istilah dan konten** 

- Tingkat peringatan masih bercampur: "Siaga" untuk gempa dan "Waspada" untuk banjir tanpa skala yang dijelaskan. Tetapkan satu skala (lihat BR-06) dan jelaskan artinya di aplikasi. 

- Seragamkan "Profil" dan "Profile", serta penulisan huruf besar pada nama wilayah seperti "padang, sumbar". 

- Gempa M5.8 berstatus "Siaga" sementara riwayat gempa M4.2 hanya "tidak berdampak": tentukan kriteria tingkat berdasarkan magnitudo, kedalaman, dan jarak. Data contoh (nama, nomor, posko) sudah jelas diberi label contoh; pertahankan, dan ganti dengan data nyata sebelum uji coba. 

### **E. Teknis dan keamanan (perlu dipikirkan sejak desain)** 

- Keluarga & Bantuan membutuhkan internet. Di bencana nyata jaringan sering padat, jadi pertimbangkan cadangan SMS dan antrean kirim ulang otomatis. 

- Peringatan palsu atau salah berbahaya; wajibkan sumber, waktu, dan persetujuan admin sebelum notifikasi massal. 

- Data lokasi dan keluarga sangat sensitif: tentukan masa simpan dan hak hapus data. 

Page 15 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

## 11. Risiko, Kriteria Keberhasilan, dan Tahapan Pengembangan 

Risiko terbesar adalah peringatan yang terlambat atau keliru dan kegagalan jaringan saat bencana, sehingga rilis pertama sebaiknya fokus pada peringatan, status keluarga, dan berita yang andal, bukan semua fitur sekaligus. 

### **Risiko** 

|ID|Risiko|Dampak|Mitigasi|
|---|---|---|---|
|R1|Data resmi tidak dapat<br>diakses atau tidak berizin|Peringatan dan berita<br>kosong|Pastikan izin lebih awal;<br>siapkan input manual lewat<br>panel admin|
|R2|Peringatan palsu atau salah<br>terkirim|Kepanikan dan<br>hilangnya kepercayaan|Persetujuan admin, sumber<br>wajib, batas kecepatan<br>pengiriman|
|R3|Jaringan padat saat<br>bencana|Status keluarga tidak<br>terkirim|Mode offline, antrean kirim<br>ulang, cadangan SMS|
|R4|Kebocoran data lokasi dan<br>keluarga|Pelanggaran privasi,<br>risiko hukum|Enkripsi, persetujuan<br>eksplisit, masa simpan data<br>terbatas|
|R5|Sedikit orang terdekat<br>memakai aplikasi|Fitur keluarga tidak<br>bernilai|Undangan mudah lewat<br>tautan, pengguna yang<br>belum punya akun tetap<br>bisa merespons|
|R6|Lingkup terlalu besar untuk<br>tim kecil|Proyek tidak selesai|Rilis bertahap sesuai<br>prioritas MoSCoW|
|R7|Notifikasi dimatikan oleh<br>pengguna atau sistem<br>Android|Peringatan tidak<br>diterima|Panduan pengaturan<br>baterai, pengingat berkala|



### **Kriteria keberhasilan rilis pertama (usulan)** 

- Semua kebutuhan prioritas M pada modul 1 sampai 5 berjalan di Android dan web. Peringatan dari sumber resmi muncul di aplikasi dalam waktu kurang dari 1 menit. 

- Pengguna dapat menautkan orang terdekat dan mengirim status aman tanpa bantuan. Minimal satu putaran uji coba dengan warga atau relawan di Kota Padang. 

### **Tahapan pengembangan (usulan urutan, belum ada tanggal)** 

Page 16 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

1. **Penyempurnaan desain.** Lengkapi layar yang belum ada (berita, detail peringatan, evakuasi, onboarding, admin, kondisi kosong dan galat) dan satukan design system mobile dan web. 

2. **Fondasi.** Akun, profil, pengaturan, basis data, dan panel admin dasar. 

3. **Peringatan dan peta.** Integrasi sumber data resmi, notifikasi dorong, peta risiko, dan peta evakuasi termasuk tsunami. 

4. **Keluarga dan bantuan.** Status aman, orang terdekat, kontak darurat, dan daftar posko. 

5. **Berita dan edukasi.** Portal berita Padang, halaman edukasi, dan prakiraan. 

6. **Uji dan rilis terbatas.** Uji beban, uji keamanan, uji kegunaan dengan warga, lalu rilis terbatas. 

7. **Pengembangan lanjutan.** Lapor kejadian warga, cadangan SMS, bahasa daerah, dan integrasi lebih dalam dengan BPBD. 

## 12. Inventaris Layar dan Keterlacakan 

Mockup v2 menambah 7 layar; tabel ini menghubungkan tiap layar dengan kebutuhan di Bagian 7, supaya jelas kebutuhan mana yang sudah punya desain. 

|Layar v2|Platform|Kebutuhan yang dipenuhi|Menutup<br>temuan|
|---|---|---|---|
|Berita & Info|Android|FR-35, FR-37|A1|
|Detail Peringatan|Android|FR-15, FR-17|A4|
|Peta Evakuasi|Android|FR-12, FR-22, FR-29|A3 (sebagian),<br>A5|
|Mode Darurat|Android|FR-10, FR-23, FR-24, NFR-04,<br>NFR-05|B5, B6<br>(sebagian)|
|Panduan Siaga|Android|FR-38|A6|
|Berita & Info (web)|Web|FR-35, FR-36, FR-37|A1|
|Panel Admin: Terbitkan<br>Peringatan|Web|FR-40, FR-42 (antrean<br>persetujuan)|A2 (sebagian)|



Navigasi utama mobile berubah dari 4 menjadi 5 tab: Dashboard, Peringatan, Peta, Berita, Keluarga. Sidebar web mengikuti daftar yang sama dan menambah Panduan Siaga. 

### **Layar yang masih perlu digambar** 

Detail berita (mobile dan web) dan editor berita di panel admin (FR-36, FR-39). 

Page 17 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

- Kelola posko dan titik evakuasi, kelola pengguna dan peran, jejak audit (FR-41, FR-42). Onboarding, lupa sandi, hapus akun, dan alur tambah orang terdekat (FR-04 sampai FR-06, FR-25). 

- Pusat notifikasi, daftar kontak darurat Padang, kondisi kosong dan galat. 

- Peta risiko versi baru yang memuat tsunami, dan perbaikan teks terpotong pada layar lama. 

## 13. Peran dan Hak Akses 

Pemisahan antara yang mengajukan dan yang menyetujui peringatan mencegah peringatan keliru terkirim ke warga (lihat risiko R2). Pembagian di bawah adalah usulan. 

|Kemampuan|Pembaca tanpa akun|Warga|Editor|Petugas|Super admin|
|---|---|---|---|---|---|
|Membaca berita dan panduan|Ya|Ya|Ya|Ya|Ya|
|Menerima peringatan sesuai lokasi|Tidak|Ya|Ya|Ya|Ya|
|Status aman dan orang terdekat|Tidak|Ya|Ya|Ya|Ya|
|Menulis dan mengubah berita|Tidak|Tidak|Ya|Tidak|Ya|
|Mengajukan peringatan|Tidak|Tidak|Tidak|Ya|Ya|
|Menyetujui peringatan dan berita|Tidak|Tidak|Tidak|Tidak|Ya|
|Mengelola posko dan titik evakuasi|Tidak|Tidak|Tidak|Ya|Ya|
|Mengelola pengguna dan peran|Tidak|Tidak|Tidak|Tidak|Ya|
|Melihat jejak audit|Tidak|Tidak|Tidak|Tidak|Ya|



Aturan tambahan: pengaju dan penyetuju satu peringatan tidak boleh orang yang sama, kecuali dalam kondisi darurat yang tercatat di jejak audit. 

## 14. Kebutuhan Data 

Sembilan kelompok data utama menopang seluruh fitur; data lokasi dan keluarga paling sensitif (NFR-06). 

|Data|Isi utama|Pengelola|Sensitivitas|
|---|---|---|---|
|Pengguna|Nama, email, telepon, alamat,<br>lokasi utama, preferensi<br>aksesibilitas|Pengguna|Tinggi|
|Tautan orang|Dua pengguna, status persetujuan,|Pengguna|Tinggi|
|terdekat|tanggal|||



Page 18 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Data|Isi utama|Pengelola|Sensitivitas|
|---|---|---|---|
|Status keamanan|Aman atau butuh bantuan, pesan,<br>lokasi (opsional), waktu|Pengguna|Tinggi|
|Peringatan|Jenis, tingkat, wilayah, tindakan,<br>sumber, waktu, pengaju, penyetuju|Petugas dan super<br>admin|Rendah|
|Berita|Judul, isi, kategori, sumber, waktu<br>terbit, penulis, status|Editor|Rendah|
|Posko dan titik<br>evakuasi|Nama, jenis, koordinat, kapasitas,<br>jam buka, kontak, tanggal<br>verifikasi|Petugas|Rendah|
|Zona risiko|Jenis bencana, tingkat, batas<br>wilayah|Petugas|Rendah|
|Perangkat|Token notifikasi, versi aplikasi,<br>wilayah langganan|Sistem|Sedang|
|Jejak audit|Siapa, apa, kapan pada tiap<br>perubahan peringatan, berita, dan<br>data posko|Sistem|Sedang|



### **Masa simpan (usulan, perlu keputusan)** 

- Lokasi dan status keamanan: dihapus otomatis setelah kejadian selesai atau paling lama sesuai kebijakan yang disepakati. 

- Akun yang dihapus: seluruh data pribadi dan tautan keluarga ikut dihapus (FR-06). Jejak audit: disimpan lebih lama karena dibutuhkan untuk akuntabilitas. 

## 15. Integrasi Eksternal 

Integrasi ini belum dipastikan ketersediaan dan izin pemakaiannya; kolom keputusan harus diisi sebelum tahap pengembangan. 

|Integrasi|Fungsi|Keputusan yang dibutuhkan|
|---|---|---|
|Data BMKG (gempa terkini,|Sumber FR-17, FR-37|Cek ketentuan dan format|
|cuaca)||data terbuka, serta|
|||kebutuhan atribusi|
|BPBD Kota Padang|Verifikasi peringatan, data<br>posko dan zona risiko|Siapa narahubung dan<br>bagaimana alur persetujuan|



Page 19 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Integrasi|Fungsi|Keputusan yang dibutuhkan|
|---|---|---|
|Login Google dan Facebook|FR-02, FR-03|Pertahankan Facebook atau<br>cukup Google dan email|
|Notifikasi dorong (misalnya<br>Firebase Cloud Messaging)|FR-16|Prioritas tinggi agar tembus<br>mode hemat daya|
|Layanan peta|FR-18, FR-22|Pilih penyedia peta<br>berdasarkan biaya, data jalan,<br>dan mode offline|
|Gerbang SMS|Verifikasi dua langkah,<br>cadangan status aman|Biaya per pesan dan penyedia|
|Layanan email|Reset sandi, verifikasi akun|Penyedia dan domain<br>pengirim|



## 16. Kriteria Penerimaan Fitur Inti 

Kriteria berikut dipakai penguji untuk menyatakan fitur selesai. Angka waktu adalah usulan. 

|Kebutuhan|Kriteria penerimaan|
|---|---|
|FR-23 Status aman|Saat pengguna menekan Saya aman, semua orang<br>terdekat yang disetujui melihat status baru dalam<br>10 detik pada jaringan normal. Tanpa internet,<br>status masuk antrean dan terkirim otomatis saat<br>jaringan kembali.|
|FR-24 Berbagi lokasi|Lokasi tidak pernah terkirim jika kotak berbagi<br>lokasi tidak dicentang.|
|FR-25 Tambah orang terdekat|Tautan baru hanya aktif setelah penerima<br>menyetujui; pengguna dapat mencabut tautan<br>kapan saja.|
|FR-16 Notifikasi peringatan|Peringatan yang disetujui tiba di perangkat<br>pengguna di wilayah terdampak dalam 1 menit;<br>pengguna di luar wilayah tidak menerimanya.|
|FR-15 Detail peringatan|Setiap detail menampilkan jenis, tingkat, wilayah,<br>tindakan, sumber, dan waktu; peringatan tanpa<br>sumber tidak dapat diterbitkan.|



Page 20 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Kebutuhan|Kriteria penerimaan|
|---|---|
|FR-40 Terbitkan peringatan|Peringatan manual baru terkirim setelah disetujui<br>orang lain selain pengajunya; seluruh langkah<br>tercatat di jejak audit.|
|FR-35 Berita|Berita hanya tampil bila berstatus terbit, memuat<br>sumber dan waktu, dan dapat dicari berdasarkan<br>kategori.|
|NFR-04 Offline|Tanpa internet, pengguna tetap dapat membuka<br>peringatan terakhir, kontak darurat, dan titik<br>kumpul yang sudah tersimpan.|



## 17. Glosarium dan Skala Tingkat Peringatan 

SIGAP perlu satu skala tingkat yang sama di aplikasi, notifikasi, dan panel admin. Usulan berikut mengikuti istilah umum kebencanaan di Indonesia; arti persisnya perlu disepakati bersama BPBD. 

|Tingkat|Arti (usulan)|Contoh tindakan|
|---|---|---|
|Waspada|Ada potensi bahaya; pantau informasi|Periksa kondisi sekitar dan siapkan<br>tas siaga|
|Siaga|Bahaya makin dekat atau sudah terjadi;<br>bersiap bertindak|Jauhi area rawan, ikuti arahan<br>resmi|
|Awas|Bahaya langsung mengancam; evakuasi<br>segera|Menuju titik kumpul sekarang|



|Istilah|Arti di SIGAP|
|---|---|
|Orang terdekat|Pengguna lain yang sudah menyetujui saling<br>memantau status|
|Kontak darurat|Nomor yang dihubungi pengguna atas tindakannya<br>sendiri; tidak ada panggilan otomatis|
|Titik kumpul|Lokasi aman tempat warga berkumpul saat<br>evakuasi|
|Posko|Pos layanan bantuan sementara (kesehatan, SAR,<br>dapur umum)|



Page 21 of 22 

BRD Aplikasi SIGAP (Siaga Bencana Kota Padang) 

|Istilah|Arti di SIGAP|
|---|---|
|Mode darurat|Tampilan sederhana yang muncul saat peringatan|
||Siaga atau Awas aktif di wilayah pengguna|



## 18. Keputusan yang Dibutuhkan dari Pemilik Proyek 

- Setuju menambah tsunami sebagai jenis bencana? (Bagian 3) 

- Skala tingkat peringatan: Waspada, Siaga, Awas, atau skala lain? (Bagian 17) 

- Siapa yang menjadi mitra data resmi (BMKG, BPBD) dan apakah sudah ada kontak? (Bagian 15) 

- Login Facebook dipertahankan atau diganti Google dan email saja? (FR-03) 

- Siapa yang menjadi editor berita dan petugas yang mengajukan peringatan? (Bagian 13) 

- Apakah cadangan SMS masuk rilis pertama atau tahap lanjutan? (NFR-05) 

- Apakah proyek ini rilis publik di Play Store atau uji coba terbatas? (Bagian 11) 

Page 22 of 22 

