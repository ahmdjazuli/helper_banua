import 'package:flutter/material.dart';
import 'transaksi.dart';
import '../navigation/navigasi_utama.dart';

class LayarPesananDibuat extends StatefulWidget {
  final String idPesanan;
  final String jenisJasa;
  final String estimasiWaktu;
  final bool isBerhasil;

  const LayarPesananDibuat({
    super.key,
    required this.idPesanan,
    required this.jenisJasa,
    required this.estimasiWaktu,
    this.isBerhasil = true,
  });

  @override
  State<LayarPesananDibuat> createState() => _LayarPesananDibuatState();
}

class _LayarPesananDibuatState extends State<LayarPesananDibuat> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulasi durasi loading selama 2.5 detik sebelum berganti ke ikon centang
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: SizedBox()),

            // Judul & Deskripsi
            const Text(
              'Pemesanan Dibuat!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Mohon tunggu sebentar, kami sedang mengirimkan order Anda ke mitra-mitra 'Helper Banua'.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Indikator Loading / Centang bertema Helper Banua
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3.5,
                      ),
                    )
                  : Container(
                      key: const ValueKey('success'),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCB05), // Kuning Khas Helper Banua
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black, // Kontras Hitam
                        size: 44,
                      ),
                    ),
            ),

            const SizedBox(height: 36),

            // Informasi ID & Jenis Jasa
            Text(
              'ID Pesanan: #${widget.idPesanan}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jenis Jasa: ${widget.jenisJasa}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // Estimasi Waktu & Tombol Ke Menu Transaksi
            Text(
              'Estimasi waktu tunggu: ${widget.estimasiWaktu}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen(
                      initialIndex: 1,
                      initialFilterTransaksi: 'aktif', // Mengarahkan ke tab Pesanan Aktif
                    ),
                  ),
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCB05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Lihat menu transaksi!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Batal Order
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'BATAL ORDER',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}