import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'topup.dart'; // Menggunakan CurrencyInputFormatter yang sudah ada

class TarikService {
  static const double minTarik = 10000;
  static const double maxTarik = 2000000;

  // Daftar Bank untuk Testing & Production Xendit
  static const List<Map<String, String>> bankList = [
    {'code': 'BCA', 'name': 'Bank Central Asia (BCA)'},
    {'code': 'BNI', 'name': 'Bank Negara Indonesia (BNI)'},
    {'code': 'BRI', 'name': 'Bank Rakyat Indonesia (BRI)'},
    {'code': 'MANDIRI', 'name': 'Bank Mandiri'},
    {'code': 'PERMATA', 'name': 'Bank Permata'},
    {'code': 'OVO', 'name': 'OVO'},
    {'code': 'DANA', 'name': 'DANA'},
    {'code': 'GOPAY', 'name': 'GoPay'},
  ];

  static void showTarikDialog(
      BuildContext context, String userId, num currentBalance) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController accountNumController = TextEditingController();
    final TextEditingController holderNameController = TextEditingController();

    String selectedBankCode = bankList.first['code']!;

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
                'Tarik Saldo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informasi Saldo Saat Ini
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCB05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saldo Tersedia:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Rp ${currentBalance.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Pilih Bank
                    DropdownButtonFormField<String>(
                      value: selectedBankCode,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Bank / E-Wallet',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: bankList.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank['code'],
                          child: Text(
                            bank['name']!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedBankCode = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Input Nomor Rekening / E-Wallet
                    TextField(
                      controller: accountNumController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening / HP E-Wallet',
                        hintText: 'Contoh: 1234567890',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Nama Pemilik Rekening
                    TextField(
                      controller: holderNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pemilik Rekening',
                        hintText: 'Sesuai buku tabungan / e-wallet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Nominal Penarikan
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nominal Penarikan (Rp)',
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
                    final String accountNum = accountNumController.text.trim();
                    final String holderName = holderNameController.text.trim();

                    // Validasi Form
                    if (accountNum.isEmpty || holderName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lengkapi nomor rekening dan nama pemilik!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (amount == null || amount < minTarik) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimal penarikan adalah Rp 10.000'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (amount > maxTarik) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maksimal penarikan adalah Rp 2.000.000'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validasi Saldo Cukup
                    if (amount > currentBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saldo Anda tidak mencukupi untuk penarikan ini!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _processXenditDisbursement(
                      context,
                      userId,
                      amount,
                      selectedBankCode,
                      accountNum,
                      holderName,
                    );
                  },
                  child: const Text(
                    'Tarik Saldo',
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

  static Future<void> _processXenditDisbursement(
    BuildContext context,
    String userId,
    double amount,
    String bankCode,
    String accountNum,
    String holderName,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
      ),
    );

    // KETIKA BERALIH KE PRODUCTION ASLI: Cukup ganti Secret Key di bawah ini
    const String xenditSecretKey =
        'xnd_development_20ELPVmtJGJv9cIG58zeVfWJv8WYJkGM6IQmpaYSV5FYnjapyDqqbGM78qUPdYL';
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$xenditSecretKey:'))}';

    try {
      final response = await http.post(
        Uri.parse('https://api.xendit.co/disbursements'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
          'X-IDEMPOTENCY-KEY': 'disb_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'external_id': 'withdraw_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'bank_code': bankCode,
          'account_holder_name': holderName,
          'account_number': accountNum,
          'description': 'Penarikan Saldo Helper Banua',
        }),
      );

      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String disbursementId = data['id'] ?? '';
        final String status = data['status'] ?? 'PENDING';

        // 1. Potong Saldo User di Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'balance': FieldValue.increment(-amount),
        }, SetOptions(merge: true));

        // 2. Catat ke Riwayat Transaksi (tipe: withdraw)
        await FirebaseFirestore.instance.collection('wallet_transactions').add({
          'userId': userId,
          'type': 'withdraw',
          'amount': amount,
          'status': 'success', // atau status.toLowerCase()
          'createdAt': FieldValue.serverTimestamp(),
          'paymentMethod': 'Xendit Disbursement',
          'bankCode': bankCode,
          'accountNumber': accountNum,
          'disbursementId': disbursementId,
        });

        final String formattedAmount = amount.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Penarikan Rp $formattedAmount berhasil diproses! Saldo telah berkurang.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['message'] ?? 'Gagal memproses penarikan via Xendit.';
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan penarikan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}