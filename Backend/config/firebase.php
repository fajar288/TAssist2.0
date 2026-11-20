<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Firebase (Admin SDK)
    |--------------------------------------------------------------------------
    |
    | `kreait/laravel-firebase` is installed in T-42; this file is the config
    | scaffold so the environment contract is fixed before the package lands.
    | The package reads `firebase.credentials.file` and `firebase.project_id`
    | by default.
    |
    | FIREBASE_CREDENTIALS must be an ABSOLUTE path to the service-account
    | JSON. The JSON is never committed: keep it under
    | storage/app/firebase/ (gitignored) or outside the repo entirely.
    |
    */

    'credentials' => [
        'file' => env('FIREBASE_CREDENTIALS'),
    ],

    'project_id' => env('FIREBASE_PROJECT_ID'),

];
