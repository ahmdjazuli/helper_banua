import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/background.dart';
import 'payment_webview.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  
  // Opsi nominal cepat
  final List<int> _quickNominals = [10000, 20000, 50000, 100000, 200000, 500000];
  int? _selectedNominal;
  bool _isLoading = false;

  // CATATAN: Untuk kebutuhan production, pindahkan pembentukan invoice ke Backend/Firebase Cloud Functions!
  final String _xenditSecretKey =
      'xnd_development_20ELPVmtJGJv9cIG58zeVfWJv8WYJkGM6IQmpaYSV5FYnjapyDqqbGM78qUPdYL';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectNominal(int nominal) {
    setState(() {
      _selectedNominal = nominal;
      _amountController.text = nominal.toString();
    });
  }

  Future<void> _processTopUp() async {
    final String amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnackBar('Masukkan nominal top up terlebih dahulu');
      return;
    }

    final int? amount = int.tryParse(amountText);
    if (amount == null || amount < 10000) {
      _showSnackBar('Minimal top up adalah Rp 10.000');
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Pengguna belum terautentikasi');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String externalId = 'TOPUP-${user.uid}-${DateTime.now().millisecondsSinceEpoch}';

      // Basic Auth Header untuk Xendit (Secret Key + :) di-encode ke Base64
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('$_xenditSecretKey:'))}';

      final response = await http.post(
        Uri.parse('https://api.xendit.co/v2/invoices'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id': externalId,
          'amount': amount,
          'payer_email': user.email ?? 'user@helperbanua.com',
          'description': 'Top Up Saldo Helper Banua',
          'customer': {
            'email': user.email ?? 'user@helperbanua.com',
          },
        }),
      );
      
      // Contoh URL Lewat Backend/Firebase
      // final response = await http.post(
      //   Uri.parse('https://us-central1-helperbanua.cloudfunctions.net/createInvoice'), 
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'userId': user.uid,
      //     'amount': amount,
      //     'email': user.email ?? 'user@helperbanua.com',
      //   }),
      // );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String invoiceUrl = data['invoice_url'];
        final String invoiceId = data['id'];

        // Simpan catatan transaksi awal berstatus PENDING ke Firestore
        await FirebaseFirestore.instance.collection('transactions').doc(invoiceId).set({
          'transactionId': invoiceId,
          'externalId': externalId,
          'userId': user.uid,
          'type': 'TOPUP',
          'amount': amount,
          'status': 'PENDING',
          'description': 'Top Up Saldo via Xendit',
          'paymentUrl': invoiceUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          // Buka Invoice URL di dalam WebView aplikasi (tanpa keluar ke browser)
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                url: invoiceUrl,
                title: 'Top Up Pembayaran',
              ),
            ),
          );

          // Setelah pengguna menutup WebView, kembali ke halaman utama/sebelumnya
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal membuat tagihan Xendit');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Top Up Saldo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INPUT NOMINAL
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nominal Top Up',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rp ',
                                prefixStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                                hintText: '0',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedNominal = int.tryParse(value);
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PILIHAN NOMINAL CEPAT
                      const Text(
                        'Pilih Nominal Cepat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _quickNominals.length,
                        itemBuilder: (context, index) {
                          final nominal = _quickNominals[index];
                          final isSelected = _selectedNominal == nominal;

                          return InkWell(
                            onTap: () => _selectNominal(nominal),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFCB05) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                'Rp ${_formatCurrency(nominal)}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // TOMBOL BAYAR
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _processTopUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCB05),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Lanjutkan Pembayaran',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
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
}