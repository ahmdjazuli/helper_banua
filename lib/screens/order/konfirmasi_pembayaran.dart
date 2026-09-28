import 'package:flutter/material.dart';
import '../../widgets/background.dart';

class LayarKonfirmasiPembayaran extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const LayarKonfirmasiPembayaran({
    super.key,
    required this.itemData,
  });

  @override
  State<LayarKonfirmasiPembayaran> createState() => _LayarKonfirmasiPembayaranState();
}

class _LayarKonfirmasiPembayaranState extends State<LayarKonfirmasiPembayaran> {
  // Pilihan Metode Pembayaran: 'saldo' atau 'lain'
  String _metodePembayaran = 'saldo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Diubah menjadi transparan agar watermark home terlihat
      appBar: AppBar(
        title: const Text(
          'Konfirmasi & Pembayaran',
          style: TextStyle(
            color: Colors.black, // Disesuaikan menjadi hitam
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white, // Diubah menjadi transparan
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KARTU PENAWARAN TERPILIH
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCB05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(widget.itemData['foto'] ?? ''),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    (widget.itemData['pekerjaan'] ?? '').toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    widget.itemData['durasi'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    widget.itemData['harga'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // BADGE NAMA MITRA
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.itemData['nama'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. KARTU RINGKASAN BIAYA
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan',
                        style: TextStyle(
                          color: Color(0xFFFFCB05),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRowRingkasan('Pekerjaan', widget.itemData['pekerjaan'] ?? '-'),
                      _buildRowRingkasan('Estimasi Selesai', widget.itemData['durasi'] ?? '-'),
                      _buildRowRingkasan('Pekerja', widget.itemData['nama'] ?? '-'),
                      _buildRowRingkasan('Harga', widget.itemData['harga'] ?? '-'),
                      _buildRowRingkasan('Biaya Admin', 'Rp 5.000'),
                      _buildRowRingkasan('Diskon', 'Rp 0'),
                      const Divider(color: Colors.white24, height: 20),
                      _buildRowRingkasan('Total Pembayaran', 'Rp 405.000', isTotal: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. METODE PEMBAYARAN
                const Text(
                  'Metode Pembayaran :',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor: Colors.black,
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text(
                          'Potong Saldo',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        value: 'saldo',
                        groupValue: _metodePembayaran,
                        activeColor: Colors.black,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (val) {
                          setState(() {
                            _metodePembayaran = val!;
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'Metode Pembayaran Lain',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        value: 'lain',
                        groupValue: _metodePembayaran,
                        activeColor: Colors.black,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (val) {
                          setState(() {
                            _metodePembayaran = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 4. ID PESANAN
                const Text(
                  'ID Pesanan',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '#123456',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. TOMBOL KONFIRMASI ORDER & BAYAR
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aksi konfirmasi order
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCB05),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'KONFIRMASI ORDER & BAYAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowRingkasan(String label, String value, {bool isRed = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFFFFCB05) : Colors.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 13 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isRed
                  ? Colors.redAccent
                  : (isTotal ? const Color(0xFFFFCB05) : Colors.white),
              fontWeight: (isTotal || isRed) ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 13 : 12,
            ),
          ),
        ],
      ),
    );
  }
}