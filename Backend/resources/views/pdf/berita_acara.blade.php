<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Berita Acara Bimbingan - {{ $ba->nomor }}</title>
    <style>
        @page {
            margin: 20mm 15mm 20mm 15mm;
        }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 11pt;
            line-height: 1.4;
            color: #1f2937;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #1e3a8a;
            padding-bottom: 12px;
            margin-bottom: 20px;
        }
        .header h1 {
            font-size: 16pt;
            font-weight: bold;
            margin: 0;
            color: #1e3a8a;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .header h2 {
            font-size: 13pt;
            font-weight: 600;
            margin: 4px 0 0 0;
            color: #374151;
        }
        .header .doc-number {
            font-size: 10.5pt;
            margin-top: 6px;
            color: #4b5563;
            font-weight: 500;
        }
        .draft-badge {
            background-color: #fef3c7;
            color: #92400e;
            border: 1px dashed #d97706;
            padding: 6px 14px;
            text-align: center;
            font-weight: bold;
            margin-bottom: 15px;
            border-radius: 4px;
            font-size: 10.5pt;
        }
        .section-title {
            font-size: 11.5pt;
            font-weight: bold;
            color: #1e3a8a;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 4px;
            margin-top: 16px;
            margin-bottom: 10px;
            text-transform: uppercase;
        }
        table.meta-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 12px;
        }
        table.meta-table td {
            padding: 3px 6px;
            vertical-align: top;
            font-size: 10pt;
        }
        table.meta-table td.label {
            width: 25%;
            font-weight: 600;
            color: #4b5563;
        }
        table.meta-table td.colon {
            width: 2%;
            text-align: center;
        }
        table.meta-table td.value {
            width: 73%;
            color: #111827;
        }
        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            margin-bottom: 15px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #d1d5db;
            padding: 6px 8px;
            font-size: 9.5pt;
        }
        table.data-table th {
            background-color: #f3f4f6;
            color: #1f2937;
            font-weight: bold;
            text-align: left;
        }
        .summary-box {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 4px;
            padding: 8px 12px;
            margin-bottom: 12px;
            font-size: 9.5pt;
        }
        .footer-table {
            width: 100%;
            margin-top: 25px;
            border-collapse: collapse;
        }
        .footer-table td {
            vertical-align: top;
            padding: 0 8px;
        }
        .qr-section {
            width: 45%;
            font-size: 8.5pt;
            color: #4b5563;
        }
        .qr-section .qr-img {
            margin-bottom: 4px;
        }
        .approval-section {
            width: 55%;
            text-align: right;
            font-size: 9.5pt;
        }
        .seal-box {
            display: inline-block;
            text-align: center;
            border: 1px solid #10b981;
            background-color: #ecfdf5;
            color: #065f46;
            padding: 6px 12px;
            border-radius: 4px;
            margin-bottom: 8px;
            font-size: 8.5pt;
        }
        .hash-code {
            font-family: 'Courier New', monospace;
            font-size: 7pt;
            color: #6b7280;
            word-break: break-all;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>TAssist Academic System</h1>
        <h2>Berita Acara Bimbingan Tugas Akhir</h2>
        <div class="doc-number">Nomor: {{ $ba->nomor }}</div>
    </div>

    @if($ba->isDraft())
    <div class="draft-badge">
        DRAFT RESMI — BELUM DISETUJUI DOSEN PEMBIMBING
    </div>
    @endif

    <div class="section-title">I. Identitas Mahasiswa & Pembimbing</div>
    <table class="meta-table">
        <tr>
            <td class="label">Nama Mahasiswa</td>
            <td class="colon">:</td>
            <td class="value"><strong>{{ $snapshot['mahasiswa']['nama'] ?? '-' }}</strong></td>
        </tr>
        <tr>
            <td class="label">NIM</td>
            <td class="colon">:</td>
            <td class="value">{{ $snapshot['mahasiswa']['nim'] ?? '-' }}</td>
        </tr>
        <tr>
            <td class="label">Program Studi</td>
            <td class="colon">:</td>
            <td class="value">{{ $snapshot['mahasiswa']['program_studi'] ?? '-' }}</td>
        </tr>
        <tr>
            <td class="label">Judul Tugas Akhir</td>
            <td class="colon">:</td>
            <td class="value"><em>{{ $snapshot['supervisi']['judul_ta'] ?? '-' }}</em></td>
        </tr>
        <tr>
            <td class="label">Dosen Pembimbing</td>
            <td class="colon">:</td>
            <td class="value"><strong>{{ $snapshot['dosen']['nama'] ?? '-' }}</strong> (NID: {{ $snapshot['dosen']['nid'] ?? '-' }})</td>
        </tr>
        <tr>
            <td class="label">Periode Laporan</td>
            <td class="colon">:</td>
            <td class="value">{{ \Carbon\Carbon::parse($ba->periode_mulai)->translatedFormat('d F Y') }} s/d {{ \Carbon\Carbon::parse($ba->periode_selesai)->translatedFormat('d F Y') }}</td>
        </tr>
    </table>

    <div class="section-title">II. Ringkasan Aktivitas Bimbingan</div>
    <div class="summary-box">
        <strong>Statistik Periode:</strong> 
        Total Pertemuan Terkonfirmasi: <strong>{{ $snapshot['total_sesi'] ?? count($snapshot['sesi_bimbingan'] ?? []) }} sesi</strong> | 
        Revisi/Anotasi Selesai: <strong>{{ $snapshot['anotasi']['resolved'] ?? 0 }} dari {{ $snapshot['anotasi']['total'] ?? 0 }}</strong> | 
        Progres Tugas Akhir: <strong>{{ $snapshot['progres']['persentase'] ?? 0 }}%</strong>
    </div>

    <div class="section-title">III. Log Riwayat Sesi Bimbingan</div>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 5%; text-align: center;">No</th>
                <th style="width: 18%;">Tanggal & Waktu</th>
                <th style="width: 38%;">Materi / Catatan Bimbingan</th>
                <th style="width: 39%;">Catatan Tindak Lanjut / Revisi</th>
            </tr>
        </thead>
        <tbody>
            @forelse($snapshot['sesi_bimbingan'] ?? [] as $index => $sesi)
            <tr>
                <td style="text-align: center;">{{ $index + 1 }}</td>
                <td>
                    <strong>{{ \Carbon\Carbon::parse($sesi['tanggal'])->format('d/m/Y') }}</strong><br>
                    <span style="color: #6b7280; font-size: 8.5pt;">{{ $sesi['waktu_mulai'] ?? '' }} - {{ $sesi['waktu_selesai'] ?? '' }}</span>
                </td>
                <td>{{ $sesi['catatan'] ?? '-' }}</td>
                <td>{{ $sesi['catatan_revisi'] ?? '-' }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="4" style="text-align: center; color: #6b7280; font-style: italic;">
                    Tidak ada sesi bimbingan terkonfirmasi pada rentang periode ini.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="section-title">IV. Pengesahan & Integritas Dokumen</div>
    <table class="footer-table">
        <tr>
            <td class="qr-section">
                @if(!empty($qrCodeBase64))
                <div class="qr-img">
                    <img src="{{ $qrCodeBase64 }}" width="95" height="95" alt="QR Verifikasi" />
                </div>
                @endif
                <div><strong>Verifikasi Keaslian Dokumen:</strong></div>
                <div>Pindai QR code di atas atau kunjungi:</div>
                <div style="color: #1e40af; word-break: break-all; font-size: 8pt;">{{ $verificationUrl }}</div>
                <div style="margin-top: 4px;" class="hash-code">
                    SHA-256: {{ substr($ba->approved_hash ?: $ba->file_hash, 0, 32) }}...
                </div>
            </td>
            <td class="approval-section">
                <div>Tanggal Cetak: {{ now()->translatedFormat('d F Y') }}</div>
                
                @if($ba->isDisetujui())
                <div style="margin-top: 10px;">
                    <div class="seal-box">
                        ✓ DISETUJUI SECARA DIGITAL<br>
                        <span style="font-size: 7.5pt;">
                            Metode: {{ strtoupper($ba->metode_persetujuan ?? 'PIN') }} | 
                            {{ $ba->approved_at ? $ba->approved_at->translatedFormat('d M Y H:i') : '' }} WIB
                        </span>
                    </div>
                </div>

                @if(!empty($signatureBase64))
                <div style="margin: 4px 0;">
                    <img src="{{ $signatureBase64 }}" height="55" alt="Tanda Tangan Dosen" />
                </div>
                @endif

                @else
                <div style="height: 60px; line-height: 60px; color: #9ca3af; font-style: italic;">
                    [ Menunggu Persetujuan Dosen ]
                </div>
                @endif

                <div style="margin-top: 6px;">
                    <strong>{{ $snapshot['dosen']['nama'] ?? 'Dosen Pembimbing' }}</strong><br>
                    <span style="color: #4b5563;">NID. {{ $snapshot['dosen']['nid'] ?? '-' }}</span>
                </div>
            </td>
        </tr>
    </table>
</body>
</html>
