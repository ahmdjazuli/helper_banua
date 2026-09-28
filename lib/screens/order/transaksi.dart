import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/background.dart';
import '../../widgets/home_header.dart';
import 'konfirmasi_pembayaran.dart';

class LayarTransaksi extends StatefulWidget {
  final bool isEmbeddedInNav;
  final String initialFilter;

  const LayarTransaksi({
    super.key,
    this.isEmbeddedInNav = false,
    this.initialFilter = 'aktif',
  });

  @override
  State<LayarTransaksi> createState() => _LayarTransaksiState();
}

class _LayarTransaksiState extends State<LayarTransaksi> {
  late String _kategoriFilter;

  @override
  void initState() {
    super.initState();
    _kategoriFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant LayarTransaksi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _kategoriFilter = widget.initialFilter;
      });
    }
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _kategoriFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _kategoriFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFCB05) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    Widget content = SafeArea(
      child: AppBackground(
        child: Column(
          children: [
            const HomeHeader(),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Pesanan Aktif', 'aktif'),
                  _buildFilterChip('Penawaran Masuk', 'penawaran'),
                  _buildFilterChip('Riwayat Transaksi', 'riwayat'),
                  _buildFilterChip('Dibatalkan', 'dibatalkan'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _kategoriFilter == 'penawaran'
                  ? _buildPenawaranList(user)
                  : _buildFirebaseOrdersList(user),
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbeddedInNav) {
      return Container(
        color: Colors.transparent,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: content,
    );
  }

  // WIDGET KHUSUS DAFTAR PENAWARAN MASUK (TANPA INDEX CONSOLE)
  Widget _buildPenawaranList(User? user) {
    if (user == null) {
      return const Center(
        child: Text(
          'Silakan login untuk melihat penawaran masuk.',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    // Menggunakan collection biasa, BUKAN collectionGroup
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bids')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada penawaran masuk dari mitra',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final Map<String, dynamic> item = {
              'nama': data['mitraNama'] ?? 'Mitra Helper',
              'pekerjaan': (data['pekerjaan'] ?? 'PEMBERSIHAN LAHAN').toString().toUpperCase(),
              'durasi': (data['durasi'] ?? '8 JAM').toString().toUpperCase(),
              'harga': data['harga'] ?? 'Rp0',
              'foto': data['mitraFoto'] ?? 'https://i.pravatar.cc/150?img=11',
              'orderId': data['orderId'],
              'mitraId': data['mitraId'],
              'raw': data,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFFFFCB05),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LayarKonfirmasiPembayaran(itemData: item),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(item['foto']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18),
                                  Text(
                                    item['pekerjaan'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    item['durasi'],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    item['harga'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            item['nama'],
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
              ),
            );
          },
        );
      },
    );
  }

  // STREAMBUILDER FIREBASE UNTUK PESANAN AKTIF, RIWAYAT, DAN DIBATALKAN
  Widget _buildFirebaseOrdersList(User? user) {
    if (user == null) {
      return const Center(
        child: Text(
          'Silakan login terlebih dahulu untuk melihat transaksi.',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Terjadi kesalahan: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada transaksi',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          String currentUserId = user.uid;
          String? orderUserId = data['userId'] ?? data['user_id'] ?? data['uid'];

          if (orderUserId != currentUserId) {
            return false;
          }

          String status = (data['status'] ?? 'Proses Bidding').toString();

          if (_kategoriFilter == 'aktif') {
            return status == 'Proses Bidding' || status == 'Diproses';
          } else if (_kategoriFilter == 'dibatalkan') {
            return status == 'Dibatalkan' || status == 'Kadaluarsa';
          } else if (_kategoriFilter == 'riwayat') {
            return true;
          }

          return false;
        }).toList();

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada transaksi pada kategori ini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final Timestamp? timeA = dataA['createdAt'] as Timestamp?;
          final Timestamp? timeB = dataB['createdAt'] as Timestamp?;

          if (timeA == null) return 1;
          if (timeB == null) return -1;

          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _KartuTransaksiItem(
              key: ValueKey(docId),
              docId: docId,
              item: data,
            );
          },
        );
      },
    );
  }
}

class _KartuTransaksiItem extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;

  const _KartuTransaksiItem({
    super.key,
    required this.docId,
    required this.item,
  });

  @override
  State<_KartuTransaksiItem> createState() => _KartuTransaksiItemState();
}

class _KartuTransaksiItemState extends State<_KartuTransaksiItem> {
  Timer? _timer;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTimer();
  }

  @override
  void didUpdateWidget(covariant _KartuTransaksiItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndStartTimer();
  }

  void _checkAndStartTimer() {
    String status = widget.item['status'] ?? 'Proses Bidding';
    if (status == 'Proses Bidding') {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _markAsExpired() async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    _timer?.cancel();

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.docId)
          .update({'status': 'Kadaluarsa'});
    } catch (e) {
      debugPrint("Gagal mengupdate status kadaluarsa: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getKategoriAsset(String kategori) {
    String kat = kategori.toLowerCase();

    if (kat.contains('kelistrikan') || kat.contains('listrik')) {
      return 'assets/img/icon kelistrikan.png';
    } else if (kat.contains('pindah') || kat.contains('angkutan')) {
      return 'assets/img/icon pindah rumah.png';
    } else if (kat.contains('kebersihan harian') || kat.contains('harian')) {
      return 'assets/img/icon kebersihan harian.png';
    } else if (kat.contains('kebersihan khusus') || kat.contains('kebersihan') || kat.contains('bersih')) {
      return 'assets/img/icon kebersihan khusus.png';
    } else if (kat.contains('tukang') || kat.contains('renovasi')) {
      return 'assets/img/icon layanan tukang.png';
    } else if (kat.contains('ac') || kat.contains('elektronik')) {
      return 'assets/img/icon layanan ac.png';
    } else if (kat.contains('instalasi air') || kat.contains('tandon')) {
      return 'assets/img/icon instalasi air.png';
    } else if (kat.contains('sanitasi')) {
      return 'assets/img/icon sanitasi.png';
    } else if (kat.contains('borongan')) {
      return 'assets/img/icon jasa borongan.png';
    } else if (kat.contains('personal')) {
      return 'assets/img/icon layanan personal.png';
    } else if (kat.contains('insidential')) {
      return 'assets/img/icon insidential.png';
    }

    return 'assets/img/icon layanan tukang.png';
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.item['status'] ?? 'Proses Bidding';
    bool isBidding = status == 'Proses Bidding';

    String idPesanan = widget.item['orderId'] ?? widget.docId.substring(0, 6).toUpperCase();
    String judulJasa = (widget.item['jenisJasa'] ?? 'JASA').toString().toUpperCase();
    String namaKategori = widget.item['kategori'] ?? 'Kategori Jasa';

    dynamic hargaRaw = widget.item['hargaBidding'];
    String teksHargaDisplay = '';

    if (hargaRaw == null || hargaRaw == 0 || hargaRaw == '0' || hargaRaw.toString().isEmpty) {
      teksHargaDisplay = 'menunggu tawaran';
    } else {
      teksHargaDisplay =
          'Rp ${hargaRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    Timestamp? expiredAt = widget.item['expiredAt'] as Timestamp?;
    Timestamp? createdAt = widget.item['createdAt'] as Timestamp?;
    int durasiMenit = widget.item['waktuPenawaran'] is int
        ? widget.item['waktuPenawaran']
        : int.tryParse(widget.item['waktuPenawaran']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 30;

    String sisaWaktuTeks = '';

    if (isBidding) {
      DateTime? waktuKadaluarsa;

      if (expiredAt != null) {
        waktuKadaluarsa = expiredAt.toDate();
      } else if (createdAt != null) {
        waktuKadaluarsa = createdAt.toDate().add(Duration(minutes: durasiMenit));
      }

      if (waktuKadaluarsa != null) {
        Duration sisaDurasi = waktuKadaluarsa.difference(DateTime.now());

        if (sisaDurasi.isNegative) {
          sisaWaktuTeks = '00:00';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markAsExpired();
          });
        } else {
          String menit = sisaDurasi.inMinutes.remainder(60).toString().padLeft(2, '0');
          String detik = sisaDurasi.inSeconds.remainder(60).toString().padLeft(2, '0');
          sisaWaktuTeks = '$menit:$detik';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBidding ? const Color(0xFFFFCB05) : Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFCB05),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID Pesanan: #$idPesanan',
                  style: TextStyle(
                    color: isBidding ? Colors.black : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBidding ? Colors.black : const Color(0xFFFFCB05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isBidding
                        ? 'Proses Bidding ${sisaWaktuTeks.isNotEmpty ? sisaWaktuTeks : "$durasiMenit menit"}'
                        : status,
                    style: TextStyle(
                      color: isBidding ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isBidding ? Colors.black26 : Colors.white24,
          ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    _getKategoriAsset(namaKategori),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.engineering,
                        color: Colors.black,
                        size: 28,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judulJasa,
                        style: TextStyle(
                          color: isBidding ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        namaKategori,
                        style: TextStyle(
                          color: isBidding ? Colors.black87 : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        teksHargaDisplay,
                        style: TextStyle(
                          color: isBidding ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontStyle: teksHargaDisplay == 'menunggu tawaran'
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isBidding)
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(widget.docId)
                          .delete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Batalkan Order',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Ulas',
                          style: TextStyle(
                            color: Color(0xFFFFCB05),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Pesan Lagi',
                          style: TextStyle(
                            color: Color(0xFFFFCB05),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(widget.docId)
                              .delete();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}