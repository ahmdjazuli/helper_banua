import 'package:flutter/material.dart';
import 'buat_order.dart';
import '../../widgets/background.dart';
import '../../widgets/home_header.dart';

class PilihJasaScreen extends StatelessWidget {
  final Function(String title, String icon)? onSelectCategory;

  const PilihJasaScreen({super.key, this.onSelectCategory});

  static final List<Map<String, dynamic>> services = [
    {'title': 'Kebersihan\nHarian', 'icon': 'assets/img/icon kebersihan harian.png'},
    {'title': 'Kebersihan\nKhusus', 'icon': 'assets/img/icon kebersihan khusus.png'},
    {'title': 'Jasa\nBorongan', 'icon': 'assets/img/icon jasa borongan.png'},
    {'title': 'Layanan\nTukang', 'icon': 'assets/img/icon layanan tukang.png'},
    {'title': 'Layanan\nPersonal', 'icon': 'assets/img/icon layanan personal.png'},
    {'title': 'Insidentil', 'icon': 'assets/img/icon insidential.png'},
    {'title': 'Kelistrikan', 'icon': 'assets/img/icon kelistrikan.png'},
    {'title': 'Layanan AC', 'icon': 'assets/img/icon layanan ac.png'},
    {'title': 'Pindah\nRumah', 'icon': 'assets/img/icon pindah rumah.png'},
    {'title': 'Sanitasi', 'icon': 'assets/img/icon sanitasi.png'},
    {'title': 'Instalasi\nAir', 'icon': 'assets/img/icon instalasi air.png'},
  ];

  static final Map<String, List<String>> subServicesData = {
    'Kebersihan Harian': ['Bersih Rumah Standar', 'Cuci Piring', 'Cuci Baju', 'Setrika Baju', 'Bersihkan Dapur'],
    'Kebersihan Khusus': ['Bersihkan Sofa', 'Bersihkan Tungau', 'Cuci Mobil', 'Cuci Motor', 'Cuci Kamar Mandi/WC', 'Bersihkan Tandon'],
    'Jasa Borongan': ['Bersihkan Lahan', 'Bersihkan Rumah Kosong', 'Bersihkan Rumah Pasca Renovasi', 'Kebersihan Setelah Acara'],
    'Layanan Tukang': ['Perbaikan Ringan Bangunan', 'Perbaikan Atap', 'Perbaikan Plafon', 'Perbaikan Keramik', 'Pengecatan Ruangan'],
    'Layanan Personal': ['Driver Harian', 'Jasa Fotografi', 'Layanan Personal Lainnya'],
    'Insidentil': ['Bocor Ban', 'Aki Drop', 'Mogok Perjalanan', 'Jasa Towing'],
    'Kelistrikan': ['Instalasi Listrik Baru', 'Penambahan Titik Listrik', 'Pergantian MCB/Sekring', 'Pemeriksaan Instalasi Kelistrikan'],
    'Layanan AC': ['Pasang Baru', 'Pembersihan Berkala', 'Service Kerusakan', 'Tambah Freon', 'Bongkar Pasang AC'],
    'Pindah Rumah': ['Jasa Pindah Barang', 'Mobil Angkutan Barang', 'Paket Pindah'],
    'Sanitasi': ['Sedot WC', 'Layanan Sanitasi Lainnya'],
    'Instalasi Air': ['Pasang Instalasi Air', 'Perbaikan Saluran Instalasi', 'Gali Sumur'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              // 1. HEADER LOGO & PROFIL (MENGGUNAKAN WIDGET HOME_HEADER)
              const HomeHeader(),
              const SizedBox(height: 12),

              // 2. BANNER HEADER MENGGUNAKAN GAMBAR
              SizedBox(
                width: double.infinity,
                height: 90,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/img/banner_header.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.fill,
                    ),
                    const Positioned(
                      left: 16,
                      top: 4,
                      child: Text(
                        'Pilih Jasa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      bottom: 8,
                      child: Text(
                        'yang anda perlukan',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. GRID KATALOG JASA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    itemCount: services.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final cleanTitle = service['title'].replaceAll('\n', ' ');
                      final listSub = subServicesData[cleanTitle] ?? [cleanTitle];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuatOrderScreen(
                                namaKategori: cleanTitle,
                                iconKategori: service['icon'],
                                namaLayanan: listSub.first,
                                listSubServices: listSub,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFCB05),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(service['icon'], fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              service['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.1, color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}