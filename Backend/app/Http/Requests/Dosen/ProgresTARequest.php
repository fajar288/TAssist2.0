<?php
// app/Http/Requests/Dosen/ProgresTARequest.php

namespace App\Http\Requests\Dosen;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class ProgresTARequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'persentase'      => 'required|numeric|min:0|max:100',
            'status_progress' => 'required|string|max:100',
            'catatan'         => 'nullable|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'persentase.required'      => 'Persentase wajib diisi.',
            'persentase.numeric'       => 'Persentase harus berupa angka.',
            'persentase.min'           => 'Persentase minimal 0.',
            'persentase.max'           => 'Persentase maksimal 100.',
            'status_progress.required' => 'Status progress wajib diisi.',
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