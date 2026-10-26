// Tugas Rutin 4: Sistem Parkir (versi 2: Parkir Mall, enum + static)
// Nama: ................  NIM: ................
import 'dart:async';

enum Jenis {
  motor('Motor', 3000),
  mobil('Mobil', 6000),
  suv('SUV', 8000);

  const Jenis(this.label, this.tarif);
  final String label;
  final int tarif;
}

abstract class Kendaraan {
  static int jumlahDibuat = 0; // milik kelas

  final String plat;
  Kendaraan(this.plat) {
    jumlahDibuat++;
  }

  Jenis get jenis;
  int get tarifPerJam => jenis.tarif;
  String get namaTampil => jenis.label;

  int biaya(int jam) => tarifPerJam * (jam < 1 ? 1 : jam);
}

class Motor extends Kendaraan {
  Motor(super.plat);
  @override
  Jenis get jenis => Jenis.motor;
}

class Mobil extends Kendaraan {
  Mobil(super.plat);
  @override
  Jenis get jenis => Jenis.mobil;
}

class Suv extends Kendaraan {
  Suv(super.plat);
  @override
  Jenis get jenis => Jenis.suv;
}

mixin DiskonMember on Kendaraan {
  int get persenDiskon => 20;

  @override
  String get namaTampil => '${super.namaTampil} (member)';

  @override
  int biaya(int jam) => super.biaya(jam) * (100 - persenDiskon) ~/ 100;
}

class SuvMember extends Suv with DiskonMember {
  SuvMember(super.plat);
}

class ParkirPenuh implements Exception {
  final int kapasitas;
  ParkirPenuh(this.kapasitas);
  @override
  String toString() => 'Parkiran penuh (kapasitas $kapasitas)';
}

class KendaraanTidakAda implements Exception {
  final String plat;
  KendaraanTidakAda(this.plat);
  @override
  String toString() => 'Kendaraan $plat tidak ditemukan';
}

class PlatSudahAda implements Exception {
  final String plat;
  PlatSudahAda(this.plat);
  @override
  String toString() => 'Plat $plat sudah terparkir';
}

class Parkiran {
  final int kapasitas;
  final _aktif = <String, Kendaraan>{};
  final _keluarPerJenis = <Jenis, int>{};
  int _pendapatan = 0;
  final _log = StreamController<String>.broadcast();

  Parkiran(this.kapasitas);

  int get sisa => kapasitas - _aktif.length;
  int get pendapatan => _pendapatan;
  Map<Jenis, int> get keluarPerJenis => Map.unmodifiable(_keluarPerJenis);
  Stream<String> get layarPos => _log.stream;

  Future<void> masuk(Kendaraan k) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_aktif.containsKey(k.plat)) throw PlatSudahAda(k.plat);
    if (sisa == 0) throw ParkirPenuh(kapasitas);
    _aktif[k.plat] = k;
    _log.add('MASUK  ${k.namaTampil} ${k.plat} (sisa $sisa)');
  }

  Future<int> keluar(String plat, {required int jam}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final k = _aktif.remove(plat);
    if (k == null) throw KendaraanTidakAda(plat);
    final bayar = k.biaya(jam);
    _pendapatan += bayar;
    _keluarPerJenis[k.jenis] = (_keluarPerJenis[k.jenis] ?? 0) + 1;
    _log.add('KELUAR ${k.namaTampil} ${k.plat} bayar Rp$bayar ($jam jam)');
    return bayar;
  }

  Future<void> tutup() => _log.close();
}

Future<void> main() async {
  final parkir = Parkiran(4);

  // Broadcast stream: dua pelanggan sekaligus.
  parkir.layarPos.listen((e) => print('[POS] $e'));
  var hitungMasuk = 0;
  parkir.layarPos.where((e) => e.startsWith('MASUK')).listen((_) => hitungMasuk++);

  Future<void> coba(Future<void> Function() aksi) async {
    try {
      await aksi();
    } on ParkirPenuh catch (e) {
      print('Ditolak: $e');
    } on Exception catch (e) {
      print('Gagal: $e');
    }
  }

  await coba(() => parkir.masuk(Motor('BK 111 A')));
  await coba(() => parkir.masuk(Mobil('BK 222 B')));
  await coba(() => parkir.masuk(SuvMember('BK 333 C')));
  await coba(() => parkir.masuk(Motor('BK 444 D')));
  await coba(() => parkir.masuk(Mobil('BK 555 E'))); // penuh
  await coba(() => parkir.keluar('BK 111 A', jam: 2));
  await coba(() => parkir.keluar('BK 222 B', jam: 4));
  await coba(() => parkir.keluar('BK 333 C', jam: 3));
  await coba(() => parkir.keluar('BK 999 Z', jam: 1)); // tidak ada

  await parkir.tutup();
  print('\nPendapatan      : Rp${parkir.pendapatan}');
  print('Slot kosong     : ${parkir.sisa}');
  print('Kendaraan masuk : $hitungMasuk');
  print('Objek dibuat    : ${Kendaraan.jumlahDibuat}');
  parkir.keluarPerJenis
      .forEach((j, n) => print('  ${j.label}: $n kendaraan keluar'));
}
