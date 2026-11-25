<?php

namespace App\Jobs;

use App\Models\DeviceToken;
use App\Services\FcmDispatcher;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendFcmNotificationJob implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(
        public int $userId,
        public string $judul,
        public string $pesan,
        public array $data = []
    ) {
    }

    public function handle(FcmDispatcher $dispatcher): void
    {
        $tokens = DeviceToken::where('user_id', $this->userId)
            ->where('is_active', true)
            ->get();

        if ($tokens->isEmpty()) {
            return;
        }

        foreach ($tokens as $deviceToken) {
            $dispatcher->sendToToken($deviceToken, $this->judul, $this->pesan, $this->data);
        }
    }
}
