"""Seed data awal Kota Padang. Idempotent: aman dijalankan berulang.

Data posko & kontak ditandai BELUM TERVERIFIKASI karena sumber resmi
(BPBD Kota Padang) belum mengonfirmasi. Jangan tampilkan sebagai data resmi.
"""

from datetime import date

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.alerts.models import Source
from apps.guides.models import EmergencyContact, Guide
from apps.map.models import AssistancePoint

SOURCES = [
    {
        "name": "BMKG",
        "source_url": "https://data.bmkg.go.id",
        "source_type": Source.SourceType.GOVERNMENT_API,
        "description": "Badan Meteorologi, Klimatologi, dan Geofisika",
    },
    {
        "name": "BPBD Kota Padang",
        "source_url": "https://bpbd.padang.go.id",
        "source_type": Source.SourceType.GOVERNMENT_MANUAL,
        "description": "Badan Penanggulangan Bencana Daerah Kota Padang",
    },
]

CONTACTS = [
    ("BPBD Kota Padang", "bpbd", "(0751) 892929", "Pusat pengendalian bencana kota"),
    ("Basarnas Pos SAR Padang", "sar", "115", "Pencarian dan pertolongan"),
    ("Polresta Padang", "police", "110", "Kepolisian Resor Kota Padang"),
    ("Pemadam Kebakaran Padang", "fire", "113", "Dinas Pemadam Kebakaran"),
    ("Ambulans Gawat Darurat", "ambulance", "118", "Layanan ambulans"),
    ("RSUP Dr. M. Djamil", "hospital", "(0751) 32371", "Rumah sakit rujukan utama"),
]

POINTS = [
    ("Lapangan Imam Bonjol", "evacuation_point", "Jl. Imam Bonjol, Padang Barat", -0.9481, 100.3529, 5000),
    ("Gedung Youth Center", "evacuation_point", "Jl. Bagindo Aziz Chan, Padang Barat", -0.9432, 100.3617, 2000),
    ("Taman Budaya Sumatera Barat", "evacuation_point", "Jl. Diponegoro, Padang Selatan", -0.9560, 100.3620, 1500),
    ("Lapangan Tungkuih", "evacuation_point", "Kec. Kuranji, Padang", -0.9145, 100.3935, 800),
    ("RSUP Dr. M. Djamil", "hospital", "Jl. Perintis Kemerdekaan, Padang Timur", -0.9440, 100.3740, None),
    ("RSUD Dr. Rasidin", "hospital", "Jl. Air Paku, Padang Barat", -0.9210, 100.3540, None),
    ("RS Yos Sudarso", "hospital", "Jl. Situjuh No. 1, Padang Barat", -0.9510, 100.3560, None),
    ("Puskesmas Andalas", "health_center", "Jl. Andalas, Padang Timur", -0.9407, 100.3810, None),
    ("Kantor BPBD Kota Padang", "emergency_post", "Jl. Khatib Sulaiman, Padang Utara", -0.9145, 100.3545, None),
    ("Posko Banjir Alai", "emergency_post", "Jl. Alai Parak Kopi, Padang Utara", -0.8935, 100.3612, 200),
    ("Pos Bantuan Pantai Padang", "relief_point", "Jl. Samudera, Padang Barat", -0.9505, 100.3468, None),
    ("GOR Prayoga Padang", "evacuation_point", "Jl. Khatib Sulaiman, Padang Utara", -0.9150, 100.3560, 3000),
]

GUIDES = [
    ("earthquake", "before", "Persiapan Sebelum Gempa", "1. Kenali jalur evakuasi dan titik kumpul terdekat.\n2. Simpan tas darurat: air, senter, obat pribadi, dokumen penting.\n3. Perbaiki perabot yang mudah jatuh.\n4. Sepakati titik temu keluarga.", "earthquake_before"),
    ("earthquake", "during", "Langkah Saat Gempa Berlangsung", "1. Jangan panik dan jangan berlari keluar saat guncangan.\n2. Berlindung di bawah meja kokoh, lindungi kepala.\n3. Jauhi kaca dan benda yang mudah jatuh.\n4. Jika di luar ruangan, cari area terbuka.", "earthquake_during"),
    ("earthquake", "after", "Setelah Gempa Berhenti", "1. Keluar dengan tenang, hindari lift.\n2. Periksa luka dan cek kondisi sekitar.\n3. Jangan masuk bangunan yang retak.\n4. Ikuti informasi resmi BMKG dan BPBD.", "earthquake_after"),
    ("tsunami", "before", "Persiapan Menghadapi Tsunami", "1. Ketahui jarak rumah ke pantai dan jalur evakuasi vertikal.\n2. Siapkan tas darurat dan dokumen penting.\n3. Ikuti pelatihan evakuasi.\n4. Catat lokasi titik evakuasi terdekat.", "tsunami_before"),
    ("tsunami", "during", "Langkah Saat Peringatan Tsunami", "1. Segera menuju tempat tinggi atau bangunan bertingkat.\n2. Jangan menuju pantai untuk menonton.\n3. Jauh dari sungai dan muara.\n4. Tetap tenang dan ikuti arahan petugas.", "tsunami_during"),
    ("tsunami", "after", "Setelah Tsunami", "1. Tetap di tempat tinggi sampai dinyatakan aman.\n2. Jangan menyentuh air rendaman dan kabel listrik.\n3. Ikuti informasi resmi BMKG/BPBD.\n4. Laporkan kondisi kepada keluarga.", "tsunami_after"),
    ("flood", "before", "Persiapan Sebelum Banjir", "1. Bersihkan saluran air dan got.\n2. Simpan dokumen penting di tempat kedap air.\n3. Siapkan penerangan darurat.\n4. Pantau prakiraan cuaca BMKG.", "flood_before"),
    ("flood", "during", "Langkah Saat Banjir", "1. Matikan listrik dan gas.\n2. Pindahkan barang berharga ke tempat lebih tinggi.\n3. Hindari berjalan di arus air.\n4. Evakuasi ke posko terdekat bila air naik.", "flood_during"),
    ("flood", "after", "Setelah Banjir Surut", "1. Bersihkan lumpur dan lakukan desinfeksi.\n2. Jangan gunakan air sumur tanpa pengujian.\n3. Waspadai penyakit kulit dan diare.\n4. Catat kerusakan untuk pelaporan.", "flood_after"),
]


class Command(BaseCommand):
    help = "Isi data awal: sumber, kontak darurat, titik bantuan, panduan"

    def handle(self, *args, **options):
        for row in SOURCES:
            Source.objects.get_or_create(name=row["name"], defaults=row)
        self.stdout.write(self.style.SUCCESS(f"Sumber: {Source.objects.count()}"))

        contacts = 0
        for order, (name, category, phone, description) in enumerate(CONTACTS):
            _, created = EmergencyContact.objects.get_or_create(
                name=name,
                defaults={
                    "category": category,
                    "phone_number": phone,
                    "description": description,
                    "is_verified": False,
                    "sort_order": order,
                },
            )
            contacts += int(created)
        self.stdout.write(
            self.style.SUCCESS(f"Kontak darurat: +{contacts} (belum terverifikasi)")
        )

        bpbd = Source.objects.filter(name="BPBD Kota Padang").first()
        points = 0
        for name, category, address, lat, lon, capacity in POINTS:
            _, created = AssistancePoint.objects.get_or_create(
                name=name,
                defaults={
                    "category": category,
                    "address": address,
                    "latitude": lat,
                    "longitude": lon,
                    "capacity": capacity,
                    "source": bpbd,
                    "verification_status": AssistancePoint.Verification.UNVERIFIED,
                    "notes": "Data contoh. Wajib diverifikasi BPBD sebelum dianggap resmi.",
                },
            )
            points += int(created)
        self.stdout.write(
            self.style.SUCCESS(f"Titik bantuan: +{points} (status belum terverifikasi)")
        )

        guides = 0
        for order, (dtype, phase, title, content, icon) in enumerate(GUIDES):
            _, created = Guide.objects.get_or_create(
                title=title,
                defaults={
                    "disaster_type": dtype,
                    "phase": phase,
                    "content": content,
                    "icon_name": icon,
                    "reviewed_source": "BMKG & BPBD (ringkasan umum)",
                    "reviewed_at": date(2026, 1, 1),
                    "sort_order": order,
                },
            )
            guides += int(created)
        self.stdout.write(self.style.SUCCESS(f"Panduan: +{guides}"))
        self.stdout.write(
            self.style.WARNING(
                "Seed selesai. Data posko/kontak berstatus belum terverifikasi "
                f"({timezone.now():%Y-%m-%d %H:%M})."
            )
        )
