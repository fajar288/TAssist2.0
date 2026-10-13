<?php
// app/Http/Requests/Auth/RegisterMahasiswaRequest.php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class RegisterMahasiswaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'nim'      => 'required|string|unique:mahasiswa,nim',
            'prodi'    => 'required|string|max:255',
            'angkatan' => 'required|integer|min:2000|max:' . date('Y'),
            'topik_ta' => 'nullable|string|max:500',
            'judul_ta' => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'nama.required'      => 'Nama wajib diisi.',
            'email.required'     => 'Email wajib diisi.',
            'email.email'        => 'Format email tidak valid.',
            'email.unique'       => 'Email sudah terdaftar.',
            'password.required'  => 'Password wajib diisi.',
            'password.min'       => 'Password minimal 8 karakter.',
            'password.confirmed' => 'Konfirmasi password tidak cocok.',
            'nim.required'       => 'NIM wajib diisi.',
            'nim.unique'         => 'NIM sudah terdaftar.',
            'prodi.required'     => 'Program studi wajib diisi.',
            'angkatan.required'  => 'Angkatan wajib diisi.',
            'angkatan.integer'   => 'Angkatan harus berupa angka tahun.',
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