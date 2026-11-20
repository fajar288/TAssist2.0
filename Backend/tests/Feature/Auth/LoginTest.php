<?php
// tests/Feature/Auth/LoginTest.php

use App\Models\User;

it('logs a user in and returns a sanctum token', function () {
    $user = User::factory()->create([
        'email'         => 'aldi.firmansyah@student.ac.id',
        'password_hash' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/v1/login', [
        'email'    => 'aldi.firmansyah@student.ac.id',
        'password' => 'password123',
    ]);

    $response->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Login berhasil')
        ->assertJsonPath('data.user.email', 'aldi.firmansyah@student.ac.id')
        ->assertJsonPath('data.user.role', 'mahasiswa')
        ->assertJsonPath('data.token_type', 'Bearer')
        ->assertJsonStructure([
            'success',
            'message',
            'data' => ['user', 'profile', 'token', 'token_type', 'expires_at'],
        ]);

    expect($response->json('data.token'))->toBeString()->not->toBeEmpty();
    expect($response->json('data.expires_at'))->toBeString();

    expect($user->tokens()->count())->toBe(1);
});

it('rejects a wrong password without issuing a token', function () {
    $user = User::factory()->create([
        'email'         => 'aldi.firmansyah@student.ac.id',
        'password_hash' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/v1/login', [
        'email'    => 'aldi.firmansyah@student.ac.id',
        'password' => 'password-salah',
    ]);

    $response->assertStatus(401)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Email atau password salah.')
        ->assertJsonMissingPath('data');

    expect($user->tokens()->count())->toBe(0);
});

it('rejects a login for an unknown email', function () {
    $response = $this->postJson('/api/v1/login', [
        'email'    => 'tidak-ada@student.ac.id',
        'password' => 'password123',
    ]);

    $response->assertStatus(401)
        ->assertJsonPath('success', false)
        ->assertJsonPath('message', 'Email atau password salah.');
});

it('revokes previously issued tokens on a new login', function () {
    $user = User::factory()->create([
        'email'         => 'aldi.firmansyah@student.ac.id',
        'password_hash' => bcrypt('password123'),
    ]);

    $user->createToken('lama', ['*'], now()->addHour());

    $this->postJson('/api/v1/login', [
        'email'    => 'aldi.firmansyah@student.ac.id',
        'password' => 'password123',
    ])->assertOk();

    expect($user->tokens()->count())->toBe(1)
        ->and($user->tokens()->first()->name)->toBe('auth_token');
});
