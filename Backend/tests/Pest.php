<?php
// tests/Pest.php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| Feature tests boot the whole Laravel application and run against a fresh
| in-memory SQLite database (see phpunit.xml).
|
*/

uses(TestCase::class, RefreshDatabase::class)->in('Feature');
uses(TestCase::class)->in('Unit');

/*
|--------------------------------------------------------------------------
| Helpers
|--------------------------------------------------------------------------
|
| The API is guarded by `auth:sanctum` plus the `check.token.expiry`
| middleware, which reads `currentAccessToken()->expires_at`. Sanctum's
| `TransientToken` (used by `Sanctum::actingAs()`) has no `expires_at`
| property, so every authenticated request in these tests uses a real
| personal access token instead.
|
*/

/**
 * Issue a real Sanctum token for the given user and return its plain value.
 */
function apiToken(User $user): string
{
    return $user->createToken('test-token', ['*'], now()->addHour())->plainTextToken;
}

/**
 * Ready-to-use headers for an authenticated JSON request.
 *
 * @return array<string, string>
 */
function authHeaders(User $user): array
{
    return [
        'Authorization' => 'Bearer '.apiToken($user),
        'Accept' => 'application/json',
    ];
}
