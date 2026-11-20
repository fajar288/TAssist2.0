<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verifikasi Berita Acara Bimbingan | TAssist</title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #4338ca;
            --primary-dark: #3730a3;
            --success: #059669;
            --success-light: #ecfdf5;
            --danger: #dc2626;
            --danger-light: #fef2f2;
            --warning: #d97706;
            --warning-light: #fffbeb;
            --gray-50: #f9fafb;
            --gray-100: #f3f4f6;
            --gray-200: #e5e7eb;
            --gray-500: #6b7280;
            --gray-700: #374151;
            --gray-900: #111827;
        }
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
        }
        body {
            background-color: #f8fafc;
            color: var(--gray-900);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 24px 16px;
        }
        .container {
            width: 100%;
            max-width: 680px;
            background: #ffffff;
            border-radius: 16px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01);
            border: 1px solid var(--gray-200);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
            color: #ffffff;
            padding: 24px;
            text-align: center;
        }
        .header h1 {
            font-size: 1.25rem;
            font-weight: 700;
            letter-spacing: -0.01em;
        }
        .header p {
            font-size: 0.875rem;
            color: #e0e7ff;
            margin-top: 4px;
        }
        .content {
            padding: 24px;
        }
        .status-badge {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 16px;
            border-radius: 12px;
            margin-bottom: 24px;
        }
        .status-badge.verified {
            background-color: var(--success-light);
            border: 1px solid #a7f3d0;
            color: #065f46;
        }
        .status-badge.tampered {
            background-color: var(--danger-light);
            border: 1px solid #fecaca;
            color: #991b1b;
        }
        .status-badge.draft {
            background-color: var(--warning-light);
            border: 1px solid #fde68a;
            color: #92400e;
        }
        .status-badge.not-found {
            background-color: var(--gray-100);
            border: 1px solid var(--gray-200);
            color: var(--gray-700);
        }
        .status-icon {
            font-size: 24px;
            line-height: 1;
        }
        .status-title {
            font-weight: 700;
            font-size: 1rem;
        }
        .status-desc {
            font-size: 0.875rem;
            margin-top: 2px;
            opacity: 0.9;
        }
        .detail-card {
            background: var(--gray-50);
            border: 1px solid var(--gray-200);
            border-radius: 12px;
            padding: 16px;
            margin-bottom: 20px;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid var(--gray-200);
            font-size: 0.9rem;
        }
        .detail-row:last-child {
            border-bottom: none;
            padding-bottom: 0;
        }
        .detail-row:first-child {
            padding-top: 0;
        }
        .detail-label {
            color: var(--gray-500);
            font-weight: 500;
            flex: 1;
        }
        .detail-value {
            color: var(--gray-900);
            font-weight: 600;
            text-align: right;
            flex: 2;
        }
        .hash-box {
            background: #f1f5f9;
            padding: 12px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 0.75rem;
            color: var(--gray-700);
            word-break: break-all;
            margin-top: 8px;
        }
        .footer {
            text-align: center;
            font-size: 0.8rem;
            color: var(--gray-500);
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Sistem Verifikasi Berita Acara</h1>
            <p>TAssist Academic Document Integrity Check</p>
        </div>

        <div class="content">
            @if(!$found)
                <div class="status-badge not-found">
                    <div class="status-icon">⚠️</div>
                    <div>
                        <div class="status-title">Dokumen Tidak Ditemukan</div>
                        <div class="status-desc">Token verifikasi yang Anda masukkan tidak terdaftar dalam sistem akademik kami.</div>
                    </div>
                </div>
            @elseif(!$integrity)
                <div class="status-badge tampered">
                    <div class="status-icon">❌</div>
                    <div>
                        <div class="status-title">Pemeriksaan Integritas Gagal</div>
                        <div class="status-desc">File dokumen tidak cocok dengan catatan hash resmi — file terindikasi telah diubah atau dimodifikasi secara ilegal.</div>
                    </div>
                </div>
            @elseif($ba->isDraft())
                <div class="status-badge draft">
                    <div class="status-icon">⏳</div>
                    <div>
                        <div class="status-title">Dokumen Berstatus Draft</div>
                        <div class="status-desc">Berita Acara ini telah digenerate namun belum disetujui secara resmi oleh dosen pembimbing.</div>
                    </div>
                </div>
            @else
                <div class="status-badge verified">
                    <div class="status-icon">✓</div>
                    <div>
                        <div class="status-title">Keaslian Dokumen Terverifikasi</div>
                        <div class="status-desc">Dokumen ini adalah Berita Acara resmi yang telah disetujui dosen pembimbing dan integritas data valid.</div>
                    </div>
                </div>
            @endif

            @if($found)
                <div class="detail-card">
                    <div class="detail-row">
                        <span class="detail-label">Nomor Dokumen</span>
                        <span class="detail-value">{{ $ba->nomor }}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Nama Mahasiswa</span>
                        <span class="detail-value">{{ $snapshot['mahasiswa']['nama'] ?? '-' }} ({{ $snapshot['mahasiswa']['nim'] ?? '-' }})</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Program Studi</span>
                        <span class="detail-value">{{ $snapshot['mahasiswa']['program_studi'] ?? '-' }}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Dosen Pembimbing</span>
                        <span class="detail-value">{{ $snapshot['dosen']['nama'] ?? '-' }} (NID: {{ $snapshot['dosen']['nid'] ?? '-' }})</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Periode Supervisi</span>
                        <span class="detail-value">{{ \Carbon\Carbon::parse($ba->periode_mulai)->format('d/m/Y') }} — {{ \Carbon\Carbon::parse($ba->periode_selesai)->format('d/m/Y') }}</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Jumlah Sesi Terlaksana</span>
                        <span class="detail-value">{{ $snapshot['total_sesi'] ?? count($snapshot['sesi_bimbingan'] ?? []) }} Sesi Bimbingan</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Status Persetujuan</span>
                        <span class="detail-value">{{ strtoupper($ba->status_persetujuan) }}</span>
                    </div>
                    @if($ba->isDisetujui())
                    <div class="detail-row">
                        <span class="detail-label">Tanggal Disetujui</span>
                        <span class="detail-value">{{ $ba->approved_at ? $ba->approved_at->translatedFormat('d F Y, H:i') : '-' }} WIB</span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Metode Verifikasi</span>
                        <span class="detail-value">{{ strtoupper($ba->metode_persetujuan ?? 'PIN') }}</span>
                    </div>
                    @endif
                </div>

                <div>
                    <label style="font-size: 0.8rem; font-weight: 600; color: var(--gray-500);">KODE HASH SHA-256 DOKUMEN:</label>
                    <div class="hash-box">{{ $ba->approved_hash ?: $ba->file_hash }}</div>
                </div>
            @endif
        </div>
    </div>
    <div class="footer">
        &copy; {{ date('Y') }} TAssist — Academic Supervision & Verification Portal.
    </div>
</body>
</html>
