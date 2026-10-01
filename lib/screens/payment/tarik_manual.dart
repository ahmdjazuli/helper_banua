import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/background.dart';
import '../../widgets/format_angka.dart';

class TarikSaldoScreen extends StatefulWidget {
  const TarikSaldoScreen({super.key});

  @override
  State<TarikSaldoScreen> createState() => _TarikSaldoScreenState();
}

class _TarikSaldoScreenState extends State<TarikSaldoScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  
  String _selectedBank = 'Bank BCA';
  int? _selectedNominal;
  bool _isLoading = false;

  final List<String> _bankList = [
    'Bank BCA',
    'Bank Mandiri',
    'Bank BRI',
    'Bank BNI',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
  ];

  final List<int> _quickNominals = [
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      // Hilangkan pemisah titik untuk membaca nilai int
      final String cleanText = _amountController.text.replaceAll('.', '').trim();
      final val = int.tryParse(cleanText);
      if (val != _selectedNominal) {
        setState(() {
          _selectedNominal = val;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _selectQuickNominal(int nominal) {
    setState(() {
      _selectedNominal = nominal;
      // Format manual saat tombol cepat ditekan
      _amountController.text = _formatCurrency(nominal);
    });
  }

  void _processTarikSaldo(num currentBalance) async {
    // Hapus tanda titik sebelum dikonversi ke angka
    final String rawAmountText = _amountController.text.replaceAll('.', '').trim();
    final String accountNumber = _accountNumberController.text.trim();

    if (rawAmountText.isEmpty || accountNumber.isEmpty) {
      _showSnackBar('Harap isi nomor rekening/E-Wallet dan nominal penarikan', isError: true);
      return;
    }

    final num? amount = num.tryParse(rawAmountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Masukkan nominal penarikan yang valid', isError: true);
      return;
    }

    if (amount < 10000) {
      _showSnackBar('Minimal penarikan saldo adalah Rp 10.000', isError: true);
      return;
    }

    if (amount > currentBalance) {
      _showSnackBar('Saldo Anda tidak mencukupi untuk melakukan penarikan ini', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Sesi pengguna tidak ditemukan, silakan login kembali', isError: true);
        return;
      }

      final String currentUid = user.uid;
      final String transactionId = 'WD-${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance.collection('transactions').doc(transactionId).set({
        'transactionId': transactionId,
        'userId': currentUid,
        'type': 'WITHDRAW',
        'amount': amount,
        'status': 'PENDING',
        'bankName': _selectedBank,
        'accountNumber': accountNumber,
        'description': 'Penarikan Saldo ke $_selectedBank ($accountNumber)',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnackBar('Permintaan penarikan saldo berhasil diajukan!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Gagal mengajukan penarikan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
              // HEADER CUSTOM
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tarik Saldo Dompet',
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
                  builder: (context, snapshot) {
                    num currentBalance = 0;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null && data.containsKey('balance')) {
                        currentBalance = data['balance'] ?? 0;
                      }
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CARD INFO SALDO
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCB05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Saldo Tersedia',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${_formatCurrency(currentBalance)}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                                    ),
                                  ],
                                ),
                                if (currentBalance > 0)
                                  GestureDetector(
                                    onTap: () {
                                      _selectQuickNominal(currentBalance.toInt());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Tarik Semua',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // PILIH BANK / E-WALLET
                          const Text(
                            'Pilih Bank / E-Wallet Tujuan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _bankList.map((String bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontSize: 14, color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedBank = value;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // NOMOR REKENING / NO HP
                          const Text(
                            'Nomor Rekening / Nomor HP',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor rekening / HP tujuan',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // PILIH NOMINAL CEPAT
                          const Text(
                            'Pilih Nominal Cepat',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _quickNominals.length,
                            itemBuilder: (context, index) {
                              final amount = _quickNominals[index];
                              final isSelected = _selectedNominal == amount;

                              return InkWell(
                                onTap: () => _selectQuickNominal(amount),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFFFCB05) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.grey.shade300,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Rp ${_formatCurrency(amount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // INPUT MANUAL NOMINAL PENARIKAN (BERFORMAT)
                          const Text(
                            'Atau Masukkan Nominal Lain (Rp)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(), // Terapkan Formatter Angka di sini
                            ],
                            decoration: InputDecoration(
                              hintText: 'Contoh: 50.000',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // TOMBOL TARIK
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _processTarikSaldo(currentBalance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'AJUKAN PENARIKAN',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
}