<?php
// app/Http/Requests/Mahasiswa/VersiDokumenRequest.php

namespace App\Http\Requests\Mahasiswa;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class VersiDokumenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'catatan_revisi' => 'nullable|string|max:1000',
            'file'           => 'required|file|mimes:pdf,doc,docx,ppt,pptx,zip|max:20480',
        ];
    }

    public function messages(): array
    {
        return [
            'file.required' => 'File wajib diunggah.',
            'file.mimes'    => 'File harus berformat pdf, doc, docx, ppt, pptx, atau zip.',
            'file.max'      => 'Ukuran file maksimal 20MB.',
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