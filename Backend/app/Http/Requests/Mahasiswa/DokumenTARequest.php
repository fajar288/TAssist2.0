<?php
// app/Http/Requests/Mahasiswa/DokumenTARequest.php

namespace App\Http\Requests\Mahasiswa;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class DokumenTARequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'jenis_dokumen'  => 'required|string|max:100',
            'judul_dokumen'  => 'required|string|max:255',
            'deskripsi'      => 'nullable|string|max:1000',
            'catatan_revisi' => 'nullable|string|max:1000',
            'file'           => 'required|file|mimes:pdf,doc,docx,ppt,pptx,zip|max:20480',
        ];
    }

    public function messages(): array
    {
        return [
            'jenis_dokumen.required' => 'Jenis dokumen wajib diisi.',
            'judul_dokumen.required' => 'Judul dokumen wajib diisi.',
            'file.required'          => 'File wajib diunggah.',
            'file.mimes'             => 'File harus berformat pdf, doc, docx, ppt, pptx, atau zip.',
            'file.max'               => 'Ukuran file maksimal 20MB.',
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