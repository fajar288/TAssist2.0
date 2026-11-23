<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| Scheduled tasks
|--------------------------------------------------------------------------
|
| Laravel 11 has no app/Console/Kernel.php — schedules live here. The host
| must run `* * * * * php artisan schedule:run` (see Docs/OPS_BASELINE.md),
| or `php artisan schedule:work` during local development.
|
*/

// Housekeeping that is valid today. Both commands ship with Laravel/Sanctum.
Schedule::command('sanctum:prune-expired --hours=24')->daily();
Schedule::command('queue:prune-failed --hours=168')->weekly();

/*
|--------------------------------------------------------------------------
| Placeholders — not wired yet
|--------------------------------------------------------------------------
|
| These jobs do not exist. Uncomment each line when its task lands; keep
| `withoutOverlapping()` so a slow run cannot stack up behind the next one.
|
*/

// T-22 — nightly risk scoring snapshot (Wave 3).
Schedule::command('risk:score')->dailyAt('01:00')->withoutOverlapping();

// T-27 — idle-supervision nudge, suppressed inside `periode_libur` windows (Wave 3).
Schedule::command('nudge:idle-supervisions')->dailyAt('08:00')->withoutOverlapping();

// T-33 — chatbot conversation retention/cleanup (Wave 4).
Schedule::command('chatbot:purge-retention')->dailyAt('02:00')->withoutOverlapping();

// T-43 — meeting reminders via FCM (Wave 5).
// Schedule::command('reminders:meetings')->everyFifteenMinutes()->withoutOverlapping();
