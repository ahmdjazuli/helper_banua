import 'package:flutter/material.dart';
import '../../widgets/background.dart';

class LayarBantuan extends StatefulWidget {
  const LayarBantuan({super.key});

  @override
  State<LayarBantuan> createState() => _LayarBantuanState();
}

class _LayarBantuanState extends State<LayarBantuan> {
  final List<Map<String, String>> _faqList = [
    {
      'question': 'Bagaimana cara melakukan pemesanan jasa?',
      'answer': 'Pilih menu "Pesan" di bagian tengah navigation bar, pilih kategori jasa yang Anda butuhkan, isi formulir pemesanan, dan konfirmasi pesanan Anda.',
    },
    {
      'question': 'Bagaimana sistem pembayaran di Helper Banua?',
      'answer': 'Pembayaran dapat dilakukan melalui Potong Saldo Dompet Aplikasi atau menggunakan metode pembayaran digital lainnya pada saat konfirmasi order.',
    },
    {
      'question': 'Apakah saya bisa membatalkan pesanan?',
      'answer': 'Pembatalan pesanan dapat dilakukan melalui menu Transaksi sebelum pekerja mengonfirmasi perjalanan ke lokasi Anda.',
    },
    {
      'question': 'Bagaimana jika hasil pekerjaan tidak sesuai?',
      'answer': 'Anda dapat mengajukan komplain melalui Pusat Bantuan atau menghubungi WhatsApp CS kami maksimal 1x24 jam setelah pekerjaan selesai.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD HUBUNGI CS / LOKAL SUPPORT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCB05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic, color: Color(0xFFFFCB05), size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Butuh Bantuan Cepat?',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tim Costumer Service kami siap membantu Anda 24/7.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL CS WHATSAPP
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Integrasi ke WhatsApp CS
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                  label: const Text(
                    'HUBUNGI CS VIA WHATSAPP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. JUDUL FAQ
              const Text(
                'Pertanyaan Sering Diajukan (FAQ)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // LIST ACCORDION FAQ
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Material( // ADD MATERIAL HERE
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        collapsedShape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        shape: const RoundedRectangleBorder(
                          side: BorderSide.none,
                        ),
                        title: Text(
                          _faqList[index]['question']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              _faqList[index]['answer']!,
                              style: const TextStyle(
                                fontSize: 12, 
                                color: Colors.black87, 
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}