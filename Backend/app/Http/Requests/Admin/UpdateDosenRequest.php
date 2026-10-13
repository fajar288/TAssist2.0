<?php
// app/Http/Requests/Admin/UpdateDosenRequest.php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class UpdateDosenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $dosenId = $this->route('id');
        return [
            'nama'            => 'sometimes|string|max:255',
            'email'           => [
                'sometimes', 'email',
                Rule::unique('users', 'email'),
            ],
            'nid'             => [
                'sometimes', 'string',
                Rule::unique('dosen', 'nid')->ignore($dosenId, 'dosen_id'),
            ],
            'bidang_keahlian' => 'sometimes|string|max:255',
            'kuota_bimbingan' => 'sometimes|integer|min:0',
            'profil_singkat'  => 'sometimes|string|max:1000',
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