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
            'is_selesai'      => 'sometimes|boolean',
            'tgl_selesai'     => 'sometimes|boolean', // Temporary alias during T-44 transition
            'tanggal_selesai' => 'nullable|date',
            'catatan'         => 'nullable|string|max:500',
            'bobot'           => 'sometimes|numeric|min:0.1|max:100',
        ];
    }

    public function messages(): array
    {
        return [
            'nama_item.required' => 'Nama item checklist wajib diisi.',
            'bobot.numeric'      => 'Bobot harus berupa angka.',
            'bobot.min'          => 'Bobot minimal 0.1.',
            'bobot.max'          => 'Bobot maksimal 100.',
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