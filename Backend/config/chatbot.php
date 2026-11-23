<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Default Chatbot Driver
    |--------------------------------------------------------------------------
    | Supported: "gemini", "claude", "fake"
    */
    'driver' => env('CHATBOT_DRIVER', 'gemini'),

    /*
    |--------------------------------------------------------------------------
    | Rate Limits & System Ceiling
    |--------------------------------------------------------------------------
    | Per PRD v2 F-BOT-04 & F-BOT-07.
    */
    'per_user_daily_limit' => env('CHATBOT_PER_USER_DAILY_LIMIT', 50),
    'system_daily_limit' => env('CHATBOT_SYSTEM_DAILY_LIMIT', 1000),

    /*
    |--------------------------------------------------------------------------
    | Retention Period
    |--------------------------------------------------------------------------
    | Months to keep conversations after student's supervision completes (F-BOT-03).
    */
    'retention_months_after_completion' => 6,
];
