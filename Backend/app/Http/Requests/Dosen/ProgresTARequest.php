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
            'persentase'      => 'nullable|required_if:is_override,true,1|numeric|min:0|max:100',
            'status_progress' => 'required|string|max:100',
            'is_override'     => 'sometimes|boolean',
            'catatan'         => 'nullable|required_if:is_override,true,1|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'persentase.required_if'   => 'Persentase wajib diisi saat override manual diaktifkan.',
            'persentase.numeric'       => 'Persentase harus berupa angka.',
            'persentase.min'           => 'Persentase minimal 0.',
            'persentase.max'           => 'Persentase maksimal 100.',
            'status_progress.required' => 'Status progress wajib diisi.',
            'catatan.required_if'      => 'Alasan override pada catatan wajib diisi saat override diaktifkan.',
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