import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/background.dart';

class RiwayatTransaksiScreen extends StatelessWidget {
  const RiwayatTransaksiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              // HEADER APP BAR CUSTOM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // LIST RIWAYAT TRANSAKSI
              Expanded(
                child: currentUid.isEmpty
                    ? const Center(
                        child: Text(
                          'Pengguna tidak ditemukan',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('transactions') // Pastikan namanya 'transactions'
                            .where('userId', isEqualTo: currentUid)
                            // HAPUS ATAU HILANGKAN .orderBy('createdAt') DARI QUERY AGAR TIDAK BUTUH INDEX
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.black),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              // Widget tampilan belum ada riwayat...
                            );
                          }

                          // Trik dari file lama: Urutkan data di memori Flutter (Terbaru ke Terlama)
                          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                          docs.sort((a, b) {
                            final dataA = a.data() as Map<String, dynamic>;
                            final dataB = b.data() as Map<String, dynamic>;
                            final Timestamp? timeA = dataA['createdAt'] as Timestamp?;
                            final Timestamp? timeB = dataB['createdAt'] as Timestamp?;

                            if (timeA == null || timeB == null) return 0;
                            return timeB.compareTo(timeA); // Terbalik (descending)
                          });

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data() as Map<String, dynamic>;
                              final String type = data['type'] ?? 'TOPUP';
                              final num amount = data['amount'] ?? 0;
                              final String status = data['status'] ?? 'PENDING';
                              final String title = data['description'] ??
                                  (type == 'TOPUP' ? 'Top Up Saldo' : 'Penarikan Saldo');

                              final Timestamp? timestamp = data['createdAt'] as Timestamp?;
                              final DateTime date = timestamp != null ? timestamp.toDate() : DateTime.now();
                              final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                              bool isMasuk = type.toUpperCase() == 'TOPUP';

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Ikon Status/Tipe
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isMasuk ? Colors.green.shade50 : Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isMasuk ? Icons.add_card_rounded : Icons.outbox_rounded,
                                        color: isMasuk ? Colors.green.shade700 : Colors.red.shade700,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Detail Transaksi
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Nominal dan Status
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isMasuk ? "+" : "-"} Rp ${_formatCurrency(amount)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: isMasuk ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();

    switch (label) {
      case 'SUCCESS':
      case 'BERHASIL':
      case 'PAID':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Berhasil';
        break;
      case 'PENDING':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        break;
      default:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Gagal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}