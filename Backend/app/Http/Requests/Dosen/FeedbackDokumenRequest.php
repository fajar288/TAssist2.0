<?php
// app/Http/Requests/Dosen/FeedbackDokumenRequest.php

namespace App\Http\Requests\Dosen;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class FeedbackDokumenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'versi_id'        => 'required|integer|exists:versi_dokumen,versi_id',
            'komentar'        => 'required|string|max:2000',
            'halaman'         => 'nullable|integer|min:1',
            'posisi_anotasi'  => 'nullable|string|max:255',
        ];
    }

    public function messages(): array
    {
        return [
            'versi_id.required' => 'ID versi dokumen wajib diisi.',
            'versi_id.exists'   => 'Versi dokumen tidak ditemukan.',
            'komentar.required' => 'Komentar wajib diisi.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Validasi gagal',
            'errors'  => $validator->errors(),
        ], 422));
    }
}