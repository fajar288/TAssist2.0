<?php
// app/Http/Requests/JadwalBimbinganRequest.php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class JadwalBimbinganRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'bimbingan_id'  => 'required|integer|exists:bimbingan,bimbingan_id',
            'tanggal'       => 'required|date|after_or_equal:today',
            'waktu_mulai'   => 'required|date_format:H:i',
            'waktu_selesai' => 'required|date_format:H:i|after:waktu_mulai',
            'mode'          => 'required|in:online,offline',
            'catatan'       => 'nullable|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'bimbingan_id.required'  => 'ID bimbingan wajib diisi.',
            'bimbingan_id.exists'    => 'Data bimbingan tidak ditemukan.',
            'tanggal.required'       => 'Tanggal wajib diisi.',
            'tanggal.after_or_equal' => 'Tanggal tidak boleh di masa lampau.',
            'waktu_mulai.required'   => 'Waktu mulai wajib diisi.',
            'waktu_selesai.required' => 'Waktu selesai wajib diisi.',
            'waktu_selesai.after'    => 'Waktu selesai harus setelah waktu mulai.',
            'mode.required'          => 'Mode bimbingan wajib dipilih.',
            'mode.in'                => 'Mode harus online atau offline.',
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