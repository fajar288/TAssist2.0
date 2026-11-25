<?php

namespace App\Services;

use App\Models\DeviceToken;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Exception\MessagingException;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Throwable;

/**
 * Sends FCM push notifications via kreait/laravel-firebase (T-42 / F-NOT-04).
 *
 * Gracefully no-ops with an info log when FIREBASE_CREDENTIALS is not yet configured
 * so local development and automated tests remain non-blocking.
 */
class FcmDispatcher
{
    public function isConfigured(): bool
    {
        $credentials = config('firebase.credentials.file');

        return is_string($credentials) && trim($credentials) !== '' && file_exists($credentials);
    }

    /**
     * Send push notification to a single device token.
     *
     * @return string 'sent' | 'unregistered' | 'skipped' | 'failed'
     */
    public function sendToToken(DeviceToken $deviceToken, string $title, string $body, array $data = []): string
    {
        if (! $this->isConfigured()) {
            Log::info('FCM skipped: FIREBASE_CREDENTIALS not configured.', [
                'device_token_id' => $deviceToken->device_token_id,
                'user_id'         => $deviceToken->user_id,
                'title'           => $title,
            ]);

            return 'skipped';
        }

        try {
            /** @var Messaging $messaging */
            $messaging = app('firebase.messaging');

            $stringData = array_map(fn ($v) => (string) $v, $data);

            $message = CloudMessage::new()
                ->toToken($deviceToken->token)
                ->withNotification(Notification::create($title, $body))
                ->withData($stringData);

            $messaging->send($message);

            return 'sent';
        } catch (NotFound $e) {
            $this->deactivateUnregistered($deviceToken, $e->getMessage());
            return 'unregistered';
        } catch (MessagingException $e) {
            if ($this->isUnregisteredError($e->getMessage())) {
                $this->deactivateUnregistered($deviceToken, $e->getMessage());
                return 'unregistered';
            }

            Log::warning('FCM MessagingException: ' . $e->getMessage(), [
                'device_token_id' => $deviceToken->device_token_id,
            ]);

            return 'failed';
        } catch (Throwable $e) {
            if ($this->isUnregisteredError($e->getMessage())) {
                $this->deactivateUnregistered($deviceToken, $e->getMessage());
                return 'unregistered';
            }

            Log::warning('FCM dispatch failed: ' . $e->getMessage(), [
                'device_token_id' => $deviceToken->device_token_id,
            ]);

            return 'failed';
        }
    }

    private function isUnregisteredError(string $message): bool
    {
        $upper = strtoupper($message);

        return str_contains($upper, 'UNREGISTERED')
            || str_contains($upper, 'NOT_FOUND')
            || str_contains($upper, 'REQUESTED ENTITY WAS NOT FOUND');
    }

    private function deactivateUnregistered(DeviceToken $deviceToken, string $reason): void
    {
        $deviceToken->update(['is_active' => false]);

        Log::info('FCM token deactivated (UNREGISTERED).', [
            'device_token_id' => $deviceToken->device_token_id,
            'user_id'         => $deviceToken->user_id,
            'reason'          => $reason,
        ]);
    }
}
