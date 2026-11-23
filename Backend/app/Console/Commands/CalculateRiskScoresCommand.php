<?php

namespace App\Console\Commands;

use App\Services\RiskScoringService;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class CalculateRiskScoresCommand extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'risk:score {--date= : The date to calculate risk for (YYYY-MM-DD)}';

    /**
     * The console command description.
     */
    protected $description = 'Calculates daily risk score snapshots for all active supervisions (T-22, F-ANL-02)';

    /**
     * Execute the console command.
     */
    public function handle(RiskScoringService $service): int
    {
        $dateParam = $this->option('date');
        $date = $dateParam ? Carbon::parse($dateParam) : now();

        $this->info("Calculating daily risk scores for date: {$date->toDateString()}...");

        $snapshots = $service->calculateAllActive($date);

        $this->info("Successfully calculated and stored {$snapshots->count()} risk snapshots.");

        return Command::SUCCESS;
    }
}
