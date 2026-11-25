<?php

namespace App\Http\Requests\Dosen;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class DosenKetersediaanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $isUpdate = $this->isMethod('PUT') || $this->isMethod('PATCH');
        $req = $isUpdate ? 'sometimes' : 'required';

        return [
            'tipe'          => [$req, 'in:mingguan,khusus'],
            'hari'          => ['nullable', 'required_if:tipe,mingguan', 'in:senin,selasa,rabu,kamis,jumat,sabtu'],
            'tanggal'       => ['nullable', 'required_if:tipe,khusus', 'date'],
            'waktu_mulai'   => [$req, 'date_format:H:i'],
            'waktu_selesai' => [$req, 'date_format:H:i', 'after:waktu_mulai'],
            'is_available'  => ['sometimes', 'boolean'],
            'catatan'       => ['nullable', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'tipe.required'          => 'Tipe slot wajib dipilih (mingguan atau khusus).',
            'tipe.in'                => 'Tipe slot harus mingguan atau khusus.',
            'hari.required_if'       => 'Hari wajib diisi untuk slot mingguan.',
            'hari.in'                => 'Hari harus salah satu dari senin sampai sabtu.',
            'tanggal.required_if'    => 'Tanggal wajib diisi untuk slot khusus.',
            'waktu_mulai.required'   => 'Waktu mulai wajib diisi.',
            'waktu_mulai.date_format'=> 'Format waktu mulai harus HH:MM (contoh 09:00).',
            'waktu_selesai.required' => 'Waktu selesai wajib diisi.',
            'waktu_selesai.date_format' => 'Format waktu selesai harus HH:MM (contoh 11:00).',
            'waktu_selesai.after'    => 'Waktu selesai harus setelah waktu mulai.',
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
