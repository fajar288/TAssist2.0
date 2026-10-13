<?php
// app/Http/Requests/Admin/UpdateMahasiswaRequest.php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

class UpdateMahasiswaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $mahasiswaId = $this->route('id');
        return [
            'nama'     => 'sometimes|string|max:255',
            'email'    => [
                'sometimes', 'email',
                Rule::unique('users', 'email'),
            ],
            'nim'      => [
                'sometimes', 'string',
                Rule::unique('mahasiswa', 'nim')->ignore($mahasiswaId, 'mahasiswa_id'),
            ],
            'prodi'    => 'sometimes|string|max:255',
            'angkatan' => 'sometimes|integer|min:2000|max:' . date('Y'),
            'topik_ta' => 'nullable|string|max:500',
            'judul_ta' => 'nullable|string|max:500',
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