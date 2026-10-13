<?php
// app/Http/Requests/Mahasiswa/UpdateMahasiswaProfileRequest.php

namespace App\Http\Requests\Mahasiswa;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateMahasiswaProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $user = $this->user();
        $mahasiswaId = $user->mahasiswa?->mahasiswa_id;

        return [
            'topik_ta' => 'nullable|string|max:500',
            'judul_ta' => 'nullable|string|max:500',
            // Nim, prodi, angkatan tidak bisa diubah setelah complete-profile (sesuai kebijakan akademik)
        ];
    }

    public function messages(): array
    {
        return [
            'topik_ta.string' => 'Topik TA harus berupa teks.',
            'topik_ta.max'    => 'Topik TA maksimal 500 karakter.',
            'judul_ta.string' => 'Judul TA harus berupa teks.',
            'judul_ta.max'    => 'Judul TA maksimal 500 karakter.',
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