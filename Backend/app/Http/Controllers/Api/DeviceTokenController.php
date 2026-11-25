<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/device-token
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'token'    => 'required|string|max:255',
            'platform' => 'required|in:android,ios,web',
        ], [
            'token.required'    => 'Device token wajib diisi.',
            'platform.required' => 'Platform wajib diisi.',
            'platform.in'       => 'Platform harus android, ios, atau web.',
        ]);

        $deviceToken = DeviceToken::updateOrCreate(
            ['token' => $validated['token']],
            [
                'user_id'   => $request->user()->user_id,
                'platform'  => $validated['platform'],
                'is_active' => true,
            ]
        );

        return $this->successResponse('Device token berhasil didaftarkan', [
            'device_token_id' => $deviceToken->device_token_id,
            'platform'        => $deviceToken->platform,
            'is_active'       => (bool) $deviceToken->is_active,
        ], 201);
    }

    /**
     * DELETE /api/v1/device-token
     */
    public function destroy(Request $request): JsonResponse
    {
        $request->validate([
            'token' => 'nullable|string|max:255',
        ]);

        $query = DeviceToken::where('user_id', $request->user()->user_id)
            ->where('is_active', true);

        if ($request->filled('token')) {
            $query->where('token', $request->token);
        }

        $deactivated = $query->update(['is_active' => false]);

        return $this->successResponse('Device token berhasil dinonaktifkan', [
            'deactivated_count' => $deactivated,
        ]);
    }
}
