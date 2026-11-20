<?php
// app/Http/Requests/Dosen/StoreAnotasiRequest.php

namespace App\Http\Requests\Dosen;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreAnotasiRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'versi_id'     => ['required', 'integer', 'exists:versi_dokumen,versi_id'],
            'halaman'      => ['required', 'integer', 'min:1'],
            'x'            => ['required', 'numeric', 'between:0,1'],
            'y'            => ['required', 'numeric', 'between:0,1'],
            'lebar'        => ['nullable', 'numeric', 'between:0,1'],
            'tinggi'       => ['nullable', 'numeric', 'between:0,1'],
            'tipe'         => ['required', 'in:highlight,komentar,coretan'],
            'konten'       => ['nullable', 'string', 'max:2000'],
            'data_coretan' => ['nullable', 'array'],
        ];
    }

    public function messages(): array
    {
        return [
            'versi_id.required' => 'ID versi dokumen wajib diisi.',
            'versi_id.exists'   => 'Versi dokumen tidak ditemukan.',
            'halaman.required'  => 'Halaman wajib diisi.',
            'halaman.min'       => 'Halaman minimal bernilai 1.',
            'x.required'        => 'Koordinat x wajib diisi.',
            'x.between'         => 'Koordinat x harus dinormalisasi antara 0.0 dan 1.0.',
            'y.required'        => 'Koordinat y wajib diisi.',
            'y.between'         => 'Koordinat y harus dinormalisasi antara 0.0 dan 1.0.',
            'lebar.between'     => 'Lebar harus bernilai antara 0.0 dan 1.0.',
            'tinggi.between'    => 'Tinggi harus bernilai antara 0.0 dan 1.0.',
            'tipe.required'     => 'Tipe anotasi wajib diisi.',
            'tipe.in'           => 'Tipe anotasi harus salah satu dari: highlight, komentar, coretan.',
            'konten.max'        => 'Konten anotasi maksimal 2000 karakter.',
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
