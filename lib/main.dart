import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

const String inisialNamaDepan = 'A';
const String nim = '20240801192';

final String duaDigitNim = nim.substring(nim.length - 2);
final bool nimGenap = int.parse(nim.substring(nim.length - 1)) % 2 == 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stok Barang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const StokBarangPage(),
    );
  }
}

class StokBarangPage extends StatefulWidget {
  const StokBarangPage({super.key});

  @override
  State<StokBarangPage> createState() => _StokBarangPageState();
}

class _StokBarangPageState extends State<StokBarangPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _masukCtrl = TextEditingController();
  final _keluarCtrl = TextEditingController();
  final _kodeCtrl = TextEditingController();
  final _stokCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _masukCtrl.dispose();
    _keluarCtrl.dispose();
    _kodeCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  // ---------------- VALIDATOR ----------------
  String? _wajibIsi(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  String? _validasiNama(String? v) {
    final wajib = _wajibIsi(v, 'Nama Barang');
    if (wajib != null) return wajib;
    if (!v!.trim().toUpperCase().startsWith(inisialNamaDepan.toUpperCase())) {
      return 'Nama Barang harus diawali inisial nama depan ($inisialNamaDepan)';
    }
    return null;
  }

  String? _validasiKode(String? v) {
    final wajib = _wajibIsi(v, 'Kode Barang');
    if (wajib != null) return wajib;

    final teks = v!.trim().replaceAll(',', '.');
    final digitSaja = teks.replaceAll('.', '');

    if (nimGenap) {
      // NIM genap -> wajib bilangan bulat
      if (int.tryParse(teks) == null) {
        return 'Kode Barang harus bilangan bulat';
      }
    } else {
      // NIM ganjil -> wajib bilangan desimal (mengandung titik)
      if (!teks.contains('.') || double.tryParse(teks) == null) {
        return 'Kode Barang harus bilangan desimal (contoh: 1234.56)';
      }
    }

    if (!RegExp(r'^\d+$').hasMatch(digitSaja)) {
      return 'Kode Barang hanya boleh berisi angka';
    }
    if (digitSaja.length < 6) {
      return 'Kode Barang minimal 6 angka';
    }
    if (!digitSaja.endsWith(duaDigitNim)) {
      return 'Kode Barang harus berakhir dengan $duaDigitNim (2 angka terakhir NIM)';
    }
    return null;
  }

  String? _validasiStok(String? v) {
    final wajib = _wajibIsi(v, 'Jumlah Stok');
    if (wajib != null) return wajib;
    final angka = int.tryParse(v!.trim());
    if (angka == null) return 'Jumlah Stok harus bilangan bulat';
    if (angka < 0) return 'Jumlah Stok tidak boleh negatif';
    return null;
  }

  // ---------------- SIMPAN ----------------
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final teksKode = _kodeCtrl.text.trim().replaceAll(',', '.');

      // Konversi String -> number sebelum dikirim ke Firestore
      final num kode =
      nimGenap ? int.parse(teksKode) : double.parse(teksKode);
      final int stok = int.parse(_stokCtrl.text.trim());

      await FirebaseFirestore.instance.collection('stok_barang').add({
        'nama_barang': _namaCtrl.text.trim(),
        'tanggal_masuk': _masukCtrl.text.trim(),
        'tanggal_keluar': _keluarCtrl.text.trim(),
        'kode_barang': kode,
        'jumlah_stok': stok,
        'waktu': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data barang berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      // Kosongkan seluruh field
      _formKey.currentState!.reset();
      _namaCtrl.clear();
      _masukCtrl.clear();
      _keluarCtrl.clear();
      _kodeCtrl.clear();
      _stokCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencatatan Stok Barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  hintText: 'Diawali inisial "$inisialNamaDepan"',
                  border: const OutlineInputBorder(),
                ),
                validator: _validasiNama,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _masukCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Masuk Barang',
                  hintText: 'contoh: 16-10-2026',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _wajibIsi(v, 'Tanggal Masuk Barang'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keluarCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Keluar Barang',
                  hintText: 'contoh: 20-10-2026',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _wajibIsi(v, 'Tanggal Keluar Barang'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kodeCtrl,
                keyboardType: nimGenap
                    ? TextInputType.number
                    : const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Kode Barang',
                  hintText: nimGenap
                      ? 'Bilangan bulat, min 6 angka, akhiran $duaDigitNim'
                      : 'Bilangan desimal, min 6 angka, akhiran $duaDigitNim',
                  border: const OutlineInputBorder(),
                ),
                validator: _validasiKode,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stokCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jumlah Stok',
                  border: OutlineInputBorder(),
                ),
                validator: _validasiStok,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _simpan,
                  child: _loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Simpan Barang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}