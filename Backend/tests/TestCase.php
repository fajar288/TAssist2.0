<?php
// tests/TestCase.php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = require __DIR__.'/../bootstrap/app.php';

        $storagePath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'tassist_testing_storage';
        foreach (['', '/framework', '/framework/cache', '/framework/sessions', '/framework/testing', '/framework/views', '/logs', '/app', '/app/public'] as $sub) {
            $dir = $storagePath . str_replace('/', DIRECTORY_SEPARATOR, $sub);
            if (!is_dir($dir)) {
                @mkdir($dir, 0777, true);
            }
        }
        $app->useStoragePath($storagePath);

        $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

        return $app;
    }
}
