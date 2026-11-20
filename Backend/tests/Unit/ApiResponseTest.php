<?php
// tests/Unit/ApiResponseTest.php

use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

/**
 * Minimal consumer of the ApiResponse trait so the envelope can be asserted
 * without booting a controller.
 */
function apiResponder(): object
{
    return new class
    {
        use ApiResponse;

        public function success(string $message, mixed $data = null, int $code = 200): JsonResponse
        {
            return $this->successResponse($message, $data, $code);
        }

        public function error(string $message, mixed $errors = null, int $code = 400): JsonResponse
        {
            return $this->errorResponse($message, $errors, $code);
        }
    };
}

it('builds the success envelope with data', function () {
    $response = apiResponder()->success('Berhasil', ['id' => 1], 201);

    expect($response->getStatusCode())->toBe(201)
        ->and($response->getData(true))->toBe([
            'success' => true,
            'message' => 'Berhasil',
            'data'    => ['id' => 1],
        ]);
});

it('omits the data key when no payload is given', function () {
    $payload = apiResponder()->success('Berhasil')->getData(true);

    expect($payload)->toBe(['success' => true, 'message' => 'Berhasil'])
        ->and($payload)->not->toHaveKey('data');
});

it('builds the error envelope with errors', function () {
    $response = apiResponder()->error('Validasi gagal', ['email' => ['wajib diisi']], 422);

    expect($response->getStatusCode())->toBe(422)
        ->and($response->getData(true))->toBe([
            'success' => false,
            'message' => 'Validasi gagal',
            'errors'  => ['email' => ['wajib diisi']],
        ]);
});

it('omits the errors key when none are given', function () {
    $payload = apiResponder()->error('Gagal')->getData(true);

    expect($payload)->toBe(['success' => false, 'message' => 'Gagal'])
        ->and($payload)->not->toHaveKey('errors');
});
