<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Riwayat Bimbingan Tugas Akhir</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #1e293b; line-height: 1.4; }
        h1 { font-size: 16px; margin: 0 0 4px 0; color: #312e81; }
        h2 { font-size: 13px; margin: 16px 0 6px 0; color: #1e293b; border-bottom: 1px solid #cbd5e1; padding-bottom: 4px; }
        .meta { width: 100%; border-collapse: collapse; margin-top: 8px; margin-bottom: 12px; }
        .meta td { padding: 3px 6px; vertical-align: top; }
        .meta td.label { width: 150px; font-weight: bold; color: #475569; }
        table.data { width: 100%; border-collapse: collapse; margin-top: 6px; }
        table.data th, table.data td { border: 1px solid #cbd5e1; padding: 5px 6px; text-align: left; }
        table.data th { background-color: #f1f5f9; font-weight: bold; }
        .muted { color: #64748b; font-size: 10px; }
    </style>
</head>
<body>
    <h1>Riwayat Bimbingan Tugas Akhir</h1>
    <div class="muted">Diekspor pada {{ $data['generated_at'] }} (Dokumen informasional — bukan Berita Acara resmi)</div>

    <table class="meta">
        <tr><td class="label">Mahasiswa</td><td>{{ $data['mahasiswa']['nama'] }} ({{ $data['mahasiswa']['nim'] }})</td></tr>
        <tr><td class="label">Program Studi</td><td>{{ $data['mahasiswa']['prodi'] }}</td></tr>
        <tr><td class="label">Dosen Pembimbing</td><td>{{ $data['dosen']['nama'] }} (NID: {{ $data['dosen']['nid'] }})</td></tr>
        <tr><td class="label">Topik / Judul TA</td><td>{{ $data['bimbingan']['topik_ta'] }}</td></tr>
        <tr><td class="label">Status Bimbingan</td><td>{{ ucfirst($data['bimbingan']['status_bimbingan']) }} ({{ $data['bimbingan']['tanggal_mulai'] }} s/d {{ $data['bimbingan']['tanggal_selesai'] }})</td></tr>
        <tr><td class="label">Progres Terkini</td><td>{{ $data['latest_progress']['persentase'] }}% — {{ $data['latest_progress']['status_progress'] }}</td></tr>
    </table>

    <h2>1. Riwayat Pertemuan ({{ count($data['meetings']) }})</h2>
    <table class="data">
        <thead>
            <tr>
                <th>Tanggal</th>
                <th>Waktu</th>
                <th>Mode</th>
                <th>Status</th>
                <th>Catatan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($data['meetings'] as $m)
                <tr>
                    <td>{{ $m['tanggal'] }}</td>
                    <td>{{ $m['waktu_mulai'] }} - {{ $m['waktu_selesai'] }}</td>
                    <td>{{ ucfirst($m['mode']) }}</td>
                    <td>{{ ucfirst($m['status_konfirmasi']) }}</td>
                    <td>{{ $m['catatan'] }}</td>
                </tr>
            @empty
                <tr><td colspan="5">Belum ada data pertemuan.</td></tr>
            @endforelse
        </tbody>
    </table>

    <h2>2. Riwayat Dokumen & Umpan Balik ({{ count($data['documents']) }})</h2>
    <table class="data">
        <thead>
            <tr>
                <th>Dokumen</th>
                <th>Versi</th>
                <th>Status</th>
                <th>Unggah</th>
                <th>Feedback</th>
                <th>Anotasi</th>
            </tr>
        </thead>
        <tbody>
            @forelse($data['documents'] as $d)
                <tr>
                    <td>{{ $d['judul_dokumen'] }} ({{ $d['jenis_dokumen'] }})</td>
                    <td>v{{ $d['nomor_versi'] }}</td>
                    <td>{{ ucfirst($d['status_versi']) }}</td>
                    <td>{{ $d['uploaded_at'] }}</td>
                    <td>{{ $d['feedback_count'] }}</td>
                    <td>{{ $d['anotasi_count'] }}</td>
                </tr>
            @empty
                <tr><td colspan="6">Belum ada dokumen.</td></tr>
            @endforelse
        </tbody>
    </table>

    <h2>3. Checklist Progres ({{ count($data['checklist']) }})</h2>
    <table class="data">
        <thead>
            <tr>
                <th>Item Checklist</th>
                <th>Bobot</th>
                <th>Status</th>
                <th>Tanggal Selesai</th>
                <th>Catatan</th>
            </tr>
        </thead>
        <tbody>
            @forelse($data['checklist'] as $c)
                <tr>
                    <td>{{ $c['nama_item'] }}</td>
                    <td>{{ $c['bobot'] }}</td>
                    <td>{{ $c['is_selesai'] ? 'Selesai' : 'Belum' }}</td>
                    <td>{{ $c['tanggal_selesai'] }}</td>
                    <td>{{ $c['catatan'] }}</td>
                </tr>
            @empty
                <tr><td colspan="5">Belum ada item checklist.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>
