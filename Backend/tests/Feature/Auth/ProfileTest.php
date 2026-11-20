<?php
// tests/Feature/Auth/ProfileTest.php

use App\Models\Dosen;
use App\Models\Mahasiswa;

it('returns the authenticated user profile', function () {
    $mahasiswa = Mahasiswa::factory()->create();

    $response = $this->withHeaders(authHeaders($mahasiswa->user))
        ->getJson('/api/v1/profile');

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Data profil berhasil diambil')
        ->assertJsonPath('data.user.user_id', $mahasiswa->user_id)
        ->assertJsonPath('data.user.email', $mahasiswa->user->email)
        ->assertJsonPath('data.user.role', 'mahasiswa')
        ->assertJsonPath('data.profile.mahasiswa_id', $mahasiswa->mahasiswa_id)
        ->assertJsonPath('data.profile.nim', $mahasiswa->nim)
        ->assertJsonStructure([
            'success',
            'message',
            'data' => [
                'user' => ['user_id', 'nama', 'email', 'role', 'status_akun', 'created_at'],
                'profile' => ['mahasiswa_id', 'nim', 'prodi', 'angkatan', 'topik_ta', 'judul_ta'],
            ],
        ]);
});

it('rejects an unauthenticated profile request', function () {
    $this->getJson('/api/v1/profile')
        ->assertStatus(401)
        ->assertJsonPath('success', false);
});

it('rejects a profile request with an invalid token', function () {
    $this->withHeader('Authorization', 'Bearer token-palsu')
        ->getJson('/api/v1/profile')
        ->assertStatus(401)
        ->assertJsonPath('success', false);
});

/*
 * NOTE (found while writing T-01, not fixed — application behaviour was left
 * untouched): `status_akun` is only enforced at login and inside RoleMiddleware,
 * so a deactivated account holding a still-valid token can still read
 * `/profile`, `/logout` and `/notifikasi`. Role-scoped endpoints do reject it,
 * which is what the test below pins down.
 */
it('rejects a deactivated account on role-scoped endpoints', function () {
    $dosen = Dosen::factory()->create();
    $dosen->user->update(['status_akun' => 'nonaktif']);

    $this->withHeaders(authHeaders($dosen->user->fresh()))
        ->getJson('/api/v1/dosen/permohonan')
        ->assertForbidden()
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Akun Anda tidak aktif. Hubungi administrator.');
});
