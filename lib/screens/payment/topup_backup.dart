import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'payment_webview.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String cleanText = newValue.text.replaceAll('.', '');
    final int? value = int.tryParse(cleanText);

    if (value == null) return oldValue;

    final String formatted = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TopUpService {
  static const double minTopUp = 10000;
  static const double maxTopUp = 2000000;
  static const String xenditSecretKey =
      'xnd_development_20ELPVmtJGJv9cIG58zeVfWJv8WYJkGM6IQmpaYSV5FYnjapyDqqbGM78qUPdYL';

  static void showTopUpDialog(BuildContext context, String userId) {
    final TextEditingController amountController = TextEditingController();
    final List<int> quickAmounts = [10000, 20000, 50000, 100000];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Top Up Saldo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nominal Top Up (Rp)',
                        hintText: 'Contoh: 50.000',
                        prefixText: 'Rp ',
                        border: const OutlineInputBorder(),
                        suffixIcon: amountController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    amountController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih Nominal Cepat:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickAmounts.map((nominal) {
                        final String formattedNominal =
                            nominal.toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]}.',
                                );
                        final bool isSelected =
                            amountController.text == formattedNominal;

                        return ChoiceChip(
                          label: Text(
                            'Rp $formattedNominal',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.black87,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFFCB05),
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (selected) {
                            setDialogState(() {
                              amountController.text = formattedNominal;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final String rawText =
                        amountController.text.replaceAll('.', '').trim();
                    final double? amount = double.tryParse(rawText);

                    if (amount == null || amount < minTopUp) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimal top up adalah Rp 10.000'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (amount > maxTopUp) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maksimal top up adalah Rp 2.000.000'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _processXenditPayment(context, userId, amount);
                  },
                  child: const Text(
                    'Lanjutkan Pembayaran',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _processXenditPayment(
      BuildContext context, String userId, double amount) async {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
      ),
    );

    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$xenditSecretKey:'))}';

    bool isSuccess = false;
    String? generatedInvoiceUrl;
    String? invoiceId;
    String errorMessage = 'Terjadi kesalahan tidak diketahui.';

    try {
      final response = await http.post(
        Uri.parse('https://api.xendit.co/v2/invoices'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id':
              'topup_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'description': 'Top Up Saldo Helper Banua',
          'invoice_duration': 86400,
          'currency': 'IDR',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        generatedInvoiceUrl = data['invoice_url'];
        invoiceId = data['id'];
        isSuccess = true;
      } else {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? 'Gagal membuat invoice Xendit.';
      }
    } catch (e) {
      errorMessage = 'Koneksi Error/Timeout: $e';
    } finally {
      navigator.pop();
    }

    if (isSuccess && generatedInvoiceUrl != null && invoiceId != null) {
      // 1. BUAT DOKUMEN RIWAYAT PENDING TERLEBIH DAHULU
      await FirebaseFirestore.instance.collection('wallet_transactions').add({
        'userId': userId,
        'type': 'topup',
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'Xendit',
        'invoiceId': invoiceId,
      });

      // 2. BUKA WEBVIEW
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => XenditWebviewScreen(
            invoiceUrl: generatedInvoiceUrl!,
            invoiceId: invoiceId!,
            basicAuth: basicAuth,
          ),
        ),
      );

      // 3. CEK DAN APLIKASIKAN STATUS PEMBAYARAN SETELAH WEBVIEW DITUTUP
      if (context.mounted) {
        checkManualPaymentStatus(context, invoiceId, userId, amount, showProgress: true);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Fungsi terpisah untuk mengecek & mengaplikasikan pembayaran (Bisa dipanggil dari WebView / Riwayat Transaksi)
  static Future<bool> checkManualPaymentStatus(
    BuildContext context,
    String invoiceId,
    String userId,
    double amount, {
    bool showProgress = false,
  }) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$xenditSecretKey:'))}';

    if (showProgress) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
        ),
      );
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.xendit.co/v2/invoices/$invoiceId'),
        headers: {'Authorization': basicAuth},
      ).timeout(const Duration(seconds: 10));

      if (showProgress && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        final statusData = jsonDecode(response.body);
        final String status = statusData['status'];

        if (status == 'PAID' || status == 'SETTLED') {
          // Cari transaksi di Firestore dengan invoiceId tersebut
          final transQuery = await FirebaseFirestore.instance
              .collection('wallet_transactions')
              .where('userId', isEqualTo: userId)
              .where('invoiceId', isEqualTo: invoiceId)
              .get();

          bool alreadySuccess = false;

          if (transQuery.docs.isNotEmpty) {
            final transDoc = transQuery.docs.first;
            final currentStatus = transDoc.data()['status'];

            if (currentStatus == 'success') {
              alreadySuccess = true;
            } else {
              // Update status transaksi menjadi success
              await transDoc.reference.update({'status': 'success'});
            }
          }

          // Jika belum pernah diproses, tambahkan saldo pengguna
          if (!alreadySuccess) {
            final userDocRef =
                FirebaseFirestore.instance.collection('users').doc(userId);
            await userDocRef.set({
              'balance': FieldValue.increment(amount),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          final String formattedAmount = amount.toInt().toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]}.',
              );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Top up Rp $formattedAmount berhasil! Saldo telah bertambah.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        } else {
          if (showProgress && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pembayaran belum selesai (Status: $status)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (showProgress && context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }
}