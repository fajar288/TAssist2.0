<?php

namespace App\Policies;

use App\Models\DosenKetersediaan;
use App\Models\User;

/**
 * Authorization policy for supervisor availability slots (T-39).
 */
class DosenKetersediaanPolicy
{
    public function update(User $user, DosenKetersediaan $slot): bool
    {
        if (! $user->isDosen() || ! $user->dosen) {
            return false;
        }

        return (int) $slot->dosen_id === (int) $user->dosen->dosen_id;
    }

    public function delete(User $user, DosenKetersediaan $slot): bool
    {
        return $this->update($user, $slot);
    }
}
