<?php
// app/Http/Requests/Auth/RegisterDosenRequest.php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class RegisterDosenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nama'            => 'required|string|max:255',
            'email'           => 'required|email|unique:users,email',
            'password'        => 'required|string|min:8|confirmed',
            'nid'             => 'required|string|unique:dosen,nid',
            'bidang_keahlian' => 'nullable|string|max:255',
            'kuota_bimbingan' => 'required|integer|min:0',
            'profil_singkat'  => 'nullable|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'nama.required'            => 'Nama wajib diisi.',
            'email.required'           => 'Email wajib diisi.',
            'email.email'              => 'Format email tidak valid.',
            'email.unique'             => 'Email sudah terdaftar.',
            'password.required'        => 'Password wajib diisi.',
            'password.min'             => 'Password minimal 8 karakter.',
            'password.confirmed'       => 'Konfirmasi password tidak cocok.',
            'nid.required'             => 'NID wajib diisi.',
            'nid.unique'               => 'NID sudah terdaftar.',
            'kuota_bimbingan.required' => 'Kuota bimbingan wajib diisi.',
            'kuota_bimbingan.min'      => 'Kuota bimbingan tidak boleh negatif.',
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