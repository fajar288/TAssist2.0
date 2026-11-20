<?php
// tests/Feature/Auth/LogoutTest.php

use App\Models\User;

it('revokes the current access token on logout', function () {
    $user = User::factory()->create();

    $token = $user->createToken('auth_token', ['*'], now()->addHour());
    $plain = $token->plainTextToken;

    expect($user->tokens()->count())->toBe(1);

    $this->withHeader('Authorization', 'Bearer '.$plain)
        ->postJson('/api/v1/logout')
        ->assertOk()
        ->assertJsonPath('success', true)
        ->assertJsonPath('message', 'Logout berhasil.');

    expect($user->tokens()->count())->toBe(0);
    $this->assertDatabaseCount('personal_access_tokens', 0);

    // The revoked token must no longer authenticate. The Sanctum guard caches
    // the resolved user for the lifetime of the application instance, and the
    // instance survives between requests inside a single test, so the guards
    // have to be forgotten before the token is re-resolved from the database.
    $this->app['auth']->forgetGuards();

    $this->withHeader('Authorization', 'Bearer '.$plain)
        ->getJson('/api/v1/profile')
        ->assertStatus(401)
        ->assertJsonPath('success', false);
});

it('only revokes the token used for the logout call', function () {
    $user = User::factory()->create();

    $first  = $user->createToken('perangkat-a', ['*'], now()->addHour());
    $second = $user->createToken('perangkat-b', ['*'], now()->addHour());

    $this->withHeader('Authorization', 'Bearer '.$first->plainTextToken)
        ->postJson('/api/v1/logout')
        ->assertOk();

    expect($user->tokens()->count())->toBe(1)
        ->and($user->tokens()->first()->name)->toBe('perangkat-b');

    $this->app['auth']->forgetGuards();

    $this->withHeader('Authorization', 'Bearer '.$second->plainTextToken)
        ->getJson('/api/v1/profile')
        ->assertOk();
});
