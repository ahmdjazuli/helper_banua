import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../order/buat_order.dart';
import '../../widgets/background.dart';
import '../../widgets/home_header.dart';
import '../../widgets/changelog_dialog.dart';
import '../payment/riwayat_transaksi.dart';
import '../payment/topup.dart';
import '../payment/tarik.dart';

class HomeScreen extends StatefulWidget {
  final Function(String title, String icon)? onNavigateToDetail;

  const HomeScreen({super.key, this.onNavigateToDetail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _initialPage = 5001;
  late final PageController _servicePageController;
  final PageController _bannerPageController = PageController(
    viewportFraction: 0.75,
    initialPage: 5000,
  );

  int _currentServicePage = 0;
  int _currentBannerIndex = 0;

  List<Map<String, dynamic>> _cachedBannerServices = [];
  String? _lastUserId;

  static final List<Map<String, dynamic>> allServices = [
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

  final Map<String, List<String>> _subServicesData = {
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
  void initState() {
    super.initState();
    _servicePageController = PageController(initialPage: _initialPage);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChangelogDialog.checkAndShow(context);
    });
  }

  List<Map<String, dynamic>> _getTopOrRandomServices(List<QueryDocumentSnapshot> docs, String currentUid) {
    if (_lastUserId != currentUid) {
      _cachedBannerServices.clear();
      _lastUserId = currentUid;
    }

    if (_cachedBannerServices.isNotEmpty) {
      return _cachedBannerServices;
    }

    if (docs.isEmpty) {
      final List<Map<String, dynamic>> shuffled = List.from(allServices)..shuffle(Random());
      _cachedBannerServices = shuffled.take(5).toList();
      return _cachedBannerServices;
    }

    final Map<String, int> counts = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String? namaJasa = data['kategoriJasa'] ?? data['jenisJasa'];
      if (namaJasa != null && namaJasa.isNotEmpty) {
        counts[namaJasa] = (counts[namaJasa] ?? 0) + 1;
      }
    }

    final sortedNames = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final List<Map<String, dynamic>> result = [];
    for (var name in sortedNames) {
      final match = allServices.firstWhere(
        (s) => s['title'].replaceAll('\n', ' ') == name || s['title'] == name,
        orElse: () => {},
      );
      if (match.isNotEmpty && !result.contains(match)) {
        result.add(match);
      }
    }

    if (result.length < 5) {
      final remaining = allServices.where((s) => !result.contains(s)).toList()..shuffle(Random());
      result.addAll(remaining.take(5 - result.length));
    }

    _cachedBannerServices = result.take(5).toList();
    return _cachedBannerServices;
  }

  @override
  void dispose() {
    _servicePageController.dispose();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int servicePagesCount = (allServices.length / 5).ceil();
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),
                const SizedBox(height: 16),

                // CARD SALDO DOMPET
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
                  builder: (context, snapshot) {
                    num currentBalance = 0;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null && data.containsKey('balance')) {
                        currentBalance = data['balance'] ?? 0;
                      }
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 12,
                                margin: const EdgeInsets.symmetric(vertical: 14),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                              ),
                              Container(
                                width: 12,
                                margin: const EdgeInsets.symmetric(vertical: 14),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CustomPaint(
                              painter: WalletBackgroundPainter(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Saldo Dompet',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const RiwayatTransaksiScreen(),
                                              ),
                                            );
                                          },
                                          child: Image.asset(
                                            'assets/img/icon dompet saldo.png',
                                            width: 36,
                                            height: 36,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${currentBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const TopUpScreen(),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            child: const Text('TOP UP', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const TarikSaldoScreen(),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              side: const BorderSide(color: Colors.black, width: 1.5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            child: const Text('TARIK', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // MENU LAYANAN SLIDER
                SizedBox(
                  height: 110,
                  child: PageView.builder(
                    controller: _servicePageController,
                    itemCount: 10000,
                    onPageChanged: (index) {
                      setState(() {
                        _currentServicePage = index % servicePagesCount;
                      });
                    },
                    itemBuilder: (context, index) {
                      final pageIndex = index % servicePagesCount;
                      final startIndex = pageIndex * 5;
                      final endIndex = (startIndex + 5 < allServices.length) ? startIndex + 5 : allServices.length;
                      final pageItems = allServices.sublist(startIndex, endIndex);

                      final menuWidgets = pageItems.map((service) {
                        final cleanTitle = service['title'].replaceAll('\n', ' ');
                        final listSub = _subServicesData[cleanTitle] ?? [cleanTitle];

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
                          child: SizedBox(
                            width: 70,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(6),
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
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList();

                      if (pageItems.length < 5) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: menuWidgets.map((w) => Padding(padding: const EdgeInsets.only(right: 16.0), child: w)).toList(),
                          ),
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: menuWidgets,
                      );
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _servicePageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: RotatedBox(quarterTurns: 2, child: Image.asset('assets/img/icon panah geser icon.png', width: 16, height: 16)),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: List.generate(
                        servicePagesCount,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: _currentServicePage == index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentServicePage == index ? const Color(0xFFFFCB05) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        _servicePageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
                      child: RotatedBox(quarterTurns: 4, child: Image.asset('assets/img/icon panah geser icon.png', width: 16, height: 16)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SLIDER BANNER PROMOSI
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: currentUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final displayServices = _getTopOrRandomServices(docs, currentUid);

                    if (displayServices.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _bannerPageController,
                            itemCount: 10000,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index % displayServices.length;
                              });
                            },
                            itemBuilder: (context, index) {
                              final serviceIndex = index % displayServices.length;
                              final service = displayServices[serviceIndex];
                              final cleanTitle = service['title'].replaceAll('\n', ' ');
                              final listSub = _subServicesData[cleanTitle] ?? [cleanTitle];

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
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCB05),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          right: -20,
                                          bottom: -20,
                                          child: Container(
                                            width: 140,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.25),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 75,
                                                height: 75,
                                                padding: const EdgeInsets.all(12),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Image.asset(
                                                  service['icon'],
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  service['title'],
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1.15,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            displayServices.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentBannerIndex == index ? 24 : 12,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _currentBannerIndex == index ? Colors.black : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WalletBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint lightYellowPaint = Paint()
      ..color = const Color(0xFFFFCB05)
      ..style = PaintingStyle.fill;

    final Paint darkYellowPaint = Paint()
      ..color = const Color(0xFFFFB800)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightYellowPaint);

    final Path path = Path();
    path.moveTo(size.width * 0.62, 0);
    
    path.cubicTo(
      size.width * 0.45, size.height * 0.30,
      size.width * 0.54, size.height * 0.70,
      size.width * 0.44, size.height,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, darkYellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}