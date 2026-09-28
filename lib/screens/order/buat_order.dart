import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'maps.dart';
import 'buat_order_dibuat.dart';
import '../../widgets/background.dart';
import '../../widgets/home_header.dart';

class BuatOrderScreen extends StatefulWidget {
  final String namaKategori;
  final String iconKategori;
  final String namaLayanan;
  final List<String> listSubServices;

  const BuatOrderScreen({
    super.key,
    required this.namaKategori,
    required this.iconKategori,
    required this.namaLayanan,
    this.listSubServices = const [],
  });

  @override
  State<BuatOrderScreen> createState() => _BuatOrderScreenState();
}

class _BuatOrderScreenState extends State<BuatOrderScreen> {
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _selesaiController = TextEditingController();
  final TextEditingController _waktuPenawaranController = TextEditingController(text: '30');

  String _satuanJumlah = 'pcs';
  String _satuanSelesai = 'Jam';
  
  String? _selectedSubJasa;
  String _currentKategori = '';

  // Master Data Seluruh Kategori & Jasa
  final Map<String, List<String>> _masterJasa = {
    'Kebersihan Harian': [
      'Bersih Rumah Standar',
      'Cuci Piring',
      'Cuci Baju',
      'Setrika Baju',
      'Bersihkan Dapur',
      'Paket 1. Standar ART Harian',
      'Paket 2. Premium ART Harian',
    ],
    'Kebersihan Khusus': [
      'Bersihkan Sofa',
      'Bersihkan Tungau',
      'Cuci Mobil',
      'Cuci Motor',
      'Cuci Kamar Mandi/WC',
      'Bersihkan Tandon',
      'Bersihkan Rumput Halaman',
      'Bersihkan Gudang',
      'Bersihkan Kolam',
      'Pembersihan Taman',
      'Pekerjaan lainnya Kebersihan Khusus',
    ],
    'Jasa Borongan': [
      'Bersihkan Lahan',
      'Bersihkan Rumah Kosong',
      'Bersihkan Rumah Pasca Renovasi',
      'Bersihkan Setelah Acara',
      'Rumah Pasca Banjir',
      'Tebang Pohon',
      'Bersihkan Kolam Renang',
      'Bersihkan Drainase/Parit',
      'Pekerjaan Lainnya',
    ],
    'Layanan Tukang': [
      'Perbaikan Ringan Bangunan',
      'Perbaikan Atap',
      'Perbaikan Plafon',
      'Perbaikan Keramik',
      'Pengecatan Ruangan',
      'Pekerjaan Konstruksi Ringan Lainnya',
      'Layanan Tukang Lainnya',
    ],
    'Layanan Personal': [
      'Driver Harian',
      'Jasa Fotografi',
      'Layanan Personal Lainnya',
    ],
    'Insidentil': [
      'Bocor Ban',
      'Aki Drop',
      'Mogok Perjalanan',
      'Jasa Towing',
    ],
    'Kelistrikan': [
      'Instalasi Listrik Baru',
      'Penambahan Titik Listrik',
      'Pergantian MCB/Sekring',
      'Pemeriksaan Instalasi Kelistrikan',
      'Pekerjaan Instalasi Layanan Listrik Lainnya',
    ],
    'Layanan AC': [
      'Pasang Baru',
      'Pembersihan Berkala',
      'Service Kerusakan',
      'Tambah Freon',
      'Bongkar Pasang AC',
      'Layanan AC Lainnya',
    ],
    'Pindah Rumah': [
      'Jasa Pindah Barang',
      'Mobil Angkutan Barang',
      'Paket Pindah',
    ],
    'Sanitasi': [
      'Sedot WC',
      'Layanan Sanitasi Lainnya',
    ],
    'Instalasi Air': [
      'Pasang Instalasi Air',
      'Perbaikan Saluran Instalasi',
      'Gali Sumur',
      'Layanan Instalasi Air Lainnya',
    ],
  };

  final List<File?> _fotoFiles = [null, null];
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentKategori = widget.namaKategori;
    _selectedSubJasa = widget.namaLayanan;
  }

  String _findKategoriByJasa(String itemJasa) {
    for (var entry in _masterJasa.entries) {
      if (entry.value.contains(itemJasa)) {
        return entry.key;
      }
    }
    return widget.namaKategori;
  }

  List<DropdownMenuItem<String>> _buildGroupedDropdownItems() {
    List<DropdownMenuItem<String>> items = [];

    _masterJasa.forEach((kategori, listJasa) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: 'HEADER_$kategori',
          child: Text(
            kategori,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

      for (var jasa in listJasa) {
        items.add(
          DropdownMenuItem<String>(
            value: jasa,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                jasa,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }
    });

    return items;
  }

  Future<List<String>> _uploadPhotos(String orderId) async {
    List<String> imageUrls = [];
    for (int i = 0; i < _fotoFiles.length; i++) {
      if (_fotoFiles[i] != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('order_photos')
              .child('${orderId}_photo_$i.jpg');
          
          await ref.putFile(_fotoFiles[i]!);
          String url = await ref.getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          debugPrint('Gagal upload foto: $e');
        }
      }
    }
    return imageUrls;
  }

  Future<void> _submitOrder() async {
    if (_alamatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan lengkapi alamat order!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String orderId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();
      orderId = orderRef.id.substring(0, 6).toUpperCase();

      List<String> photoUrls = await _uploadPhotos(orderRef.id);

      int durasiMenit = int.tryParse(_waktuPenawaranController.text) ?? 30;
      DateTime now = DateTime.now();
      DateTime expiredAt = now.add(Duration(minutes: durasiMenit));

      await orderRef.set({
        'orderId': orderId,
        'userId': user?.uid ?? 'guest',
        'userName': user?.displayName ?? 'Thalia Firdaus',
        'kategori': _currentKategori,
        'jenisJasa': _selectedSubJasa ?? widget.namaLayanan,
        'alamat': _alamatController.text,
        'deskripsi': _deskripsiController.text,
        'waktuPenawaran': durasiMenit, // Simpan sebagai angka menit
        'fotoUrls': photoUrls,
        'status': 'Proses Bidding', // STATUS MENJADI PROSES BIDDING
        'hargaBidding': null, // null / 0 untuk menandakan belum ada tawaran dari mitra
        'createdAt': FieldValue.serverTimestamp(),
        'expiredAt': Timestamp.fromDate(expiredAt),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LayarPesananDibuat(
            idPesanan: orderId,
            jenisJasa: _selectedSubJasa ?? widget.namaLayanan,
            estimasiWaktu: '$durasiMenit menit',
            isBerhasil: true,
          ),
        ),
      );
    } catch (e) {
      // Fallback jika offline/error
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LayarPesananDibuat(
            idPesanan: orderId,
            jenisJasa: _selectedSubJasa ?? widget.namaLayanan,
            estimasiWaktu: '${_waktuPenawaranController.text} menit',
            isBerhasil: true,
          ),
        ),
      );
    }
  }

  void _showImageSourceDialog(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFFCB05)),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, index);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFFCB05)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, index);
                },
              ),
              if (_fotoFiles[index] != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _fotoFiles[index] = null);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _fotoFiles[index] = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  void _pilihMetodeAlamat() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Metode Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person_pin_circle, color: Color(0xFFFFCB05)),
                title: const Text('Gunakan Alamat di Akun'),
                subtitle: const Text('Jl. Ahmad Yani No. 12, Banjarbaru'),
                onTap: () {
                  setState(() => _alamatController.text = 'Jl. Ahmad Yani No. 12, Banjarbaru (Alamat Akun)');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.map, color: Color(0xFFFFCB05)),
                title: const Text('Pilih Alamat Manual via Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  final selectedLocation = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectLocationScreen()),
                  );
                  if (selectedLocation != null) {
                    setState(() => _alamatController.text = selectedLocation.toString());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            AppBackground(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. TOP HEADER
                    const HomeHeader(),
                    const SizedBox(height: 12),
              
                    // 2. HEADER BANNER
                    SizedBox(
                      width: double.infinity,
                      height: 90,
                      child: Stack(
                        children: [
                          // Gambar Background Header
                          Image.asset(
                            'assets/img/banner_header.png', // Sesuaikan nama file gambar kamu
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.fill,
                          ),
              
                          // Label Teks "Jasa" (Posisi top: 4 sesuai keinginan)
                          const Positioned(
                            left: 16,
                            top: 4,
                            child: Text(
                              'Jasa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
              
                          // Nama Kategori Jasa (Misal: Kebersihan Harian)
                          Positioned(
                            left: 16,
                            bottom: 8,
                            child: Text(
                              _currentKategori,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
              
                          // Icon Kategori di Pojok Kanan Banner
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  widget.iconKategori,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.build, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              
                    const SizedBox(height: 16),
              
                    // 3. FORM INPUT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCB05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Isi Detail Pemesanan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 12),
              
                          // Alamat Order
                          const Text('Alamat Order :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pilihMetodeAlamat,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Image.asset('assets/img/icon maps.png', width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.location_on, color: Colors.red, size: 20)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _alamatController.text.isEmpty ? 'Isi Detail Alamat' : _alamatController.text,
                                      style: TextStyle(
                                        color: _alamatController.text.isEmpty ? Colors.grey : Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
              
                          // Pilih Jasa Dropdown
                          const Text('Pilih Jasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubJasa,
                                isExpanded: true,
                                menuMaxHeight: 300,
                                dropdownColor: Colors.grey.shade100,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                                style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                                items: _buildGroupedDropdownItems(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSubJasa = val;
                                      _currentKategori = _findKategoriByJasa(val);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
              
                          // Deskripsi Pekerjaan
                          const Text('Deskripsi Pekerjaan :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _deskripsiController,
                            maxLines: 4,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Deskripsikan masalah Anda (misal: "Utk Acara Pernikahan Nanti")...',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
              
                          // Unggah Foto
                          const Text('Unggah Foto (Maks. 2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(2, (index) {
                              final file = _fotoFiles[index];
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _showImageSourceDialog(index),
                                  child: Container(
                                    height: 80,
                                    margin: EdgeInsets.only(right: index == 0 ? 12.0 : 0.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9D2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                                    ),
                                    child: file == null
                                        ? const Center(
                                            child: Icon(Icons.camera_alt, color: Color(0xFFFFCB05), size: 36),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(
                                              file,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
              
                          // Est. Jumlah / Luas
                          _buildRowInput(
                            label: 'Est. Jumlah / Luas',
                            controller: _jumlahController,
                            selectedValue: _satuanJumlah,
                            options: ['pcs', 'm2', 'unit', 'meter'],
                            onChanged: (val) => setState(() => _satuanJumlah = val!),
                          ),
                          const SizedBox(height: 10),
              
                          // Est. Selesai
                          _buildRowInput(
                            label: 'Est. Selesai',
                            controller: _selesaiController,
                            selectedValue: _satuanSelesai,
                            options: ['Jam', 'Hari'],
                            onChanged: (val) => setState(() => _satuanSelesai = val!),
                          ),
                          const SizedBox(height: 10),
              
                          // Waktu Penawaran
                          Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text('Waktu Penawaran (Menit)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _waktuPenawaranController.text,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                      items: ['5', '10', '15', '30', '60'].map((opt) {
                                        return DropdownMenuItem(value: opt, child: Text(opt));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _waktuPenawaranController.text = val);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
              
                          // Tombol Submit Order
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFCB05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Buat Pesanan',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowInput({
    required String label,
    required TextEditingController controller,
    required String selectedValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Nilai',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                items: options.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}