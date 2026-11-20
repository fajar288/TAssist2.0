<?php
// app/Http/Requests/Anotasi/ReplyAnotasiRequest.php

namespace App\Http\Requests\Anotasi;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class ReplyAnotasiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'konten' => ['required', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'konten.required' => 'Konten balasan wajib diisi.',
            'konten.max'      => 'Konten balasan maksimal 2000 karakter.',
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
