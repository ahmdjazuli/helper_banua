import 'package:flutter/material.dart';
import '../home/home.dart';
import '../order/transaksi.dart';
import '../order/pilih_jasa.dart';
import '../../models/order_model.dart';
import '../profile/akun.dart'; 
import '../profile/bantuan.dart';
import '../../services/fcm_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String initialFilterTransaksi; // Parameter filter transaksi
  final OrderModel? orderData;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialFilterTransaksi = 'penawaran', // Default 'penawaran'
    this.orderData,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Inisialisasi FCM & simpan token user ke Firestore begitu masuk navigasi utama
    FCMService.initFCM();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // Index 0: Beranda
      const HomeScreen(),

      // Index 1: Transaksi (Meneruskan initialFilter)
      LayarTransaksi(
        isEmbeddedInNav: true,
        initialFilter: widget.initialFilterTransaksi,
      ),

      // Index 2: Pesan (Pilih Jasa)
      const PilihJasaScreen(),

      // Index 3: Bantuan
      const LayarBantuan(),

      // Index 4: Akun
      const AkunScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, 'icon beranda 1.png', 'icon beranda 2.png', "Beranda"),
                  _buildNavItem(1, 'icon transaksi 1.png', 'icon transaksi 2.png', "Transaksi"),
                  const SizedBox(width: 48),
                  _buildNavItem(3, 'icon bantuan 1.png', 'icon bantuan 2.png', "Bantuan"),
                  _buildNavItem(4, 'icon akun 1.png', 'icon akun 2.png', "Akun"),
                ],
              ),
              Positioned(
                top: -16,
                child: _buildCenterNavItem(2, 'icon pesan.png', "Pesan"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconInactive, String iconActive, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFCB05) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/img/${isSelected ? iconActive : iconInactive}',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(int index, String iconFile, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFCB05) : Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/img/$iconFile',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}