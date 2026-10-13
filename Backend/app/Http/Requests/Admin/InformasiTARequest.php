<?php
// app/Http/Requests/Admin/InformasiTARequest.php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class InformasiTARequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'kategori'      => 'required|string|max:100',
            'judul'         => 'required|string|max:255',
            'konten_or_file'=> 'required|string',
            'published_at'  => 'nullable|date',
        ];
    }

    public function messages(): array
    {
        return [
            'kategori.required'       => 'Kategori wajib diisi.',
            'judul.required'          => 'Judul wajib diisi.',
            'konten_or_file.required' => 'Konten wajib diisi.',
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