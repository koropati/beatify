# Beatify — Claude Rules (Root)

> Aturan spesifik ada di `backend/CLAUDE.md` dan `flutter_app/CLAUDE.md`.

## Unit Test (WAJIB)

- **Setiap** kali membuat fitur baru atau mengubah kode di backend atau Flutter, **WAJIB** jalankan unit test dan **update/ tambah** test sesuai perubahan kode tersebut. Jangan anggap tugas selesai sebelum test hijau.
  - Backend: `cd backend && venv\Scripts\python.exe -m pytest --cov --cov-report=term-missing -q`
  - Flutter: `cd flutter_app && flutter test --coverage`
- Backend: target coverage **100%** (sudah tercapai — jaga jangan turun).
- Flutter: target coverage **100% untuk layer logika** (`domain/`, `data/`, `presentation/providers/`, `core/network/`). UI murni (`pages/`, `widgets/`, `main.dart`) dan pembungkus plugin platform (`secure_storage`, `music_local_data_source`, `AudioPlayerController`) dikecualikan karena butuh widget/integration test.
- Kalau menambah kode di layer logika tanpa test, itu dianggap belum selesai.

## Flow Setelah Perubahan / Fitur Baru (WAJIB)

Urutan baku setiap selesai mengubah kode atau membuat fitur — **JANGAN** commit/push sebelum langkah ini lulus:

1. **Update/tambah unit test** sesuai perubahan kode (backend dan/atau Flutter).
2. **Cek coverage kedua sistem:**
   - Backend: `cd backend && venv\Scripts\python.exe -m pytest --cov --cov-report=term-missing -q`
   - Flutter: `cd flutter_app && flutter test --coverage`
3. **Gate lulus** jika:
   - Backend: coverage **100%**.
   - Flutter: coverage **100% untuk layer logika** (lihat pengecualian di atas).
4. Kalau coverage **belum 100%** → tambah/perbaiki test dulu, ulangi langkah 2. **Dilarang commit/push** selama gate belum lulus.
5. Kalau gate **lulus** → **commit dan push** sesuai aturan di bawah (tanpa atribusi Claude/AI).

> Kalau perubahan hanya menyentuh sistem tertentu, tetap jalankan test sistem yang tersentuh; sistem yang tidak tersentuh tidak boleh turun coverage-nya.

## Git / Commit (WAJIB)

- **JANGAN PERNAH** menambahkan trailer `Co-Authored-By: Claude` (atau atribusi Claude/AI apa pun) di pesan commit. Pemilik repo tidak ingin Claude muncul sebagai contributor di GitHub.
- Commit selalu atas nama user (pakai `git config user.name`/`user.email` yang sudah ada). Jangan ubah identitas git tanpa diminta.
- Claude **BOLEH commit dan push** atas nama user — tidak perlu minta izin tiap kali. Syarat mutlak: tanpa atribusi Claude/AI apa pun (lihat poin pertama).
- Remote pakai alias SSH `github-koropati` (`git@github-koropati:koropati/beatify.git`). Push: `git push origin main`.
- `.claude/` jangan ikut di-commit.
