<?php
// app/Http/Requests/Dosen/ChecklistProgressRequest.php

namespace App\Http\Requests\Dosen;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class ChecklistProgressRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama_item'       => 'required|string|max:255',
            'tgl_selesai'     => 'sometimes|boolean',
            'tanggal_selesai' => 'nullable|date',
            'catatan'         => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'nama_item.required' => 'Nama item checklist wajib diisi.',
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