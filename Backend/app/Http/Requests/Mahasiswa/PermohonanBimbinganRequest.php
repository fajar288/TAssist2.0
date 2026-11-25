<?php
// app/Http/Requests/Mahasiswa/PermohonanBimbinganRequest.php

namespace App\Http\Requests\Mahasiswa;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class PermohonanBimbinganRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'dosen_id'      => 'required|integer|exists:dosen,dosen_id',
            'topik_ta'      => 'required|string|max:500',
            'file_proposal' => 'nullable|file|mimes:pdf|max:10240',
        ];
    }

    public function messages(): array
    {
        return [
            'dosen_id.required'   => 'Dosen wajib dipilih.',
            'dosen_id.exists'     => 'Dosen tidak ditemukan.',
            'topik_ta.required'   => 'Topik TA wajib diisi.',
            'file_proposal.file'  => 'Lampiran proposal harus berupa file.',
            'file_proposal.mimes' => 'File proposal harus berformat PDF.',
            'file_proposal.max'   => 'Ukuran file proposal maksimal 10MB.',
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