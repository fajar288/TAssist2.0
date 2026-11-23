<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatbotPercakapan;
use App\Services\Chatbot\ChatbotService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChatbotController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected ChatbotService $chatbotService
    ) {}

    /**
     * Send a chatbot message (T-31, T-33, T-34, T-35).
     * POST /api/v1/chatbot/pesan
     */
    public function sendMessage(Request $request): JsonResponse
    {
        $request->validate([
            'pesan' => ['required', 'string', 'max:2000'],
            'percakapan_id' => ['nullable', 'integer', 'exists:chatbot_percakapan,id'],
        ], [
            'pesan.required' => 'Pesan tidak boleh kosong.',
            'pesan.max' => 'Pesan maksimal 2000 karakter.',
        ]);

        $user = $request->user();
        $result = $this->chatbotService->sendMessage(
            $user,
            $request->input('pesan'),
            $request->input('percakapan_id')
        );

        return $this->successResponse('Pesan berhasil diproses.', [
            'percakapan_id' => $result['percakapan']->id,
            'judul_percakapan' => $result['percakapan']->judul,
            'pesan_user' => [
                'id' => $result['pesan_user']->id,
                'role' => $result['pesan_user']->role,
                'pesan' => $result['pesan_user']->pesan,
                'created_at' => $result['pesan_user']->created_at,
            ],
            'pesan_asisten' => [
                'id' => $result['pesan_asisten']->id,
                'role' => $result['pesan_asisten']->role,
                'pesan' => $result['pesan_asisten']->pesan,
                'sumber' => $result['pesan_asisten']->sumber,
                'is_refused' => $result['pesan_asisten']->is_refused,
                'tokens_used' => $result['pesan_asisten']->tokens_used,
                'created_at' => $result['pesan_asisten']->created_at,
            ],
        ], 200);
    }

    /**
     * List user conversations (T-33, F-BOT-03).
     * GET /api/v1/chatbot/percakapan
     */
    public function listConversations(Request $request): JsonResponse
    {
        $user = $request->user();
        $conversations = ChatbotPercakapan::query()
            ->where('user_id', $user->user_id)
            ->with(['pesanTerakhir'])
            ->orderBy('updated_at', 'desc')
            ->get()
            ->map(function ($c) {
                return [
                    'id' => $c->id,
                    'judul' => $c->judul,
                    'created_at' => $c->created_at,
                    'updated_at' => $c->updated_at,
                    'pesan_terakhir' => $c->pesanTerakhir ? [
                        'role' => $c->pesanTerakhir->role,
                        'pesan' => $c->pesanTerakhir->pesan,
                        'is_refused' => $c->pesanTerakhir->is_refused,
                        'created_at' => $c->pesanTerakhir->created_at,
                    ] : null,
                ];
            });

        return $this->successResponse('Daftar percakapan berhasil diambil.', $conversations);
    }

    /**
     * Get specific conversation messages (T-33, F-BOT-03).
     * GET /api/v1/chatbot/percakapan/{id}
     */
    public function getConversation(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $conversation = ChatbotPercakapan::query()
            ->where('id', $id)
            ->where('user_id', $user->user_id)
            ->with(['pesan'])
            ->first();

        if (!$conversation) {
            return $this->notFoundResponse('Percakapan tidak ditemukan.');
        }

        return $this->successResponse('Detail percakapan berhasil diambil.', [
            'id' => $conversation->id,
            'judul' => $conversation->judul,
            'created_at' => $conversation->created_at,
            'updated_at' => $conversation->updated_at,
            'pesan' => $conversation->pesan->map(function ($m) {
                return [
                    'id' => $m->id,
                    'role' => $m->role,
                    'pesan' => $m->pesan,
                    'sumber' => $m->sumber,
                    'is_refused' => $m->is_refused,
                    'tokens_used' => $m->tokens_used,
                    'created_at' => $m->created_at,
                ];
            }),
        ]);
    }

    /**
     * Delete a conversation (T-33, F-BOT-03).
     * DELETE /api/v1/chatbot/percakapan/{id}
     */
    public function deleteConversation(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $conversation = ChatbotPercakapan::query()
            ->where('id', $id)
            ->where('user_id', $user->user_id)
            ->first();

        if (!$conversation) {
            return $this->notFoundResponse('Percakapan tidak ditemukan.');
        }

        $conversation->delete();

        return $this->successResponse('Percakapan berhasil dihapus.');
    }
}
