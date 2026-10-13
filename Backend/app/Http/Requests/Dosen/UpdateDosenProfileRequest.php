<?php
// app/Http/Requests/Dosen/UpdateDosenProfileRequest.php

namespace App\Http\Requests\Dosen;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class UpdateDosenProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama'            => 'sometimes|string|max:255',
            'bidang_keahlian' => 'sometimes|string|max:255',
            'kuota_bimbingan' => 'sometimes|integer|min:0',
            'profil_singkat'  => 'sometimes|string|max:1000',
            'password'        => 'nullable|string|min:8|confirmed', 
            // Key disesuaikan dengan nama kolom di tabel users
            'avatar'          => 'nullable|image|mimes:jpeg,png,jpg|max:2048', 
        ];
    }

    public function messages(): array
    {
        return [
            'kuota_bimbingan.min' => 'Kuota bimbingan tidak boleh negatif.',
            'password.min'        => 'Password minimal harus 8 karakter.',
            'password.confirmed'  => 'Konfirmasi password tidak cocok.',
            'avatar.image'        => 'File harus berupa gambar.',
            'avatar.mimes'        => 'Format avatar harus jpeg, png, atau jpg.',
            'avatar.max'          => 'Ukuran avatar maksimal adalah 2MB.',
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