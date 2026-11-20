# Ops Baseline — TAssist backend

> Task **T-79**. Everything here is a deployment requirement, not an optional
> extra: the scheduler and the queue worker are load-bearing for T-22, T-27,
> T-33, T-42 and T-43.
>
> Nothing in this file is a secret. Values live in the server's `.env`, which is
> gitignored.

---

## 1. Runtime requirements

| Component | Command | Notes |
|---|---|---|
| Web (PHP-FPM / nginx) | — | Serves `public/`. |
| Queue worker | `php artisan queue:work --tries=3 --timeout=90` | Must run under a supervisor (systemd, Supervisor, Laravel Horizon, or the host's equivalent) and be restarted on deploy. |
| Scheduler | `* * * * * php artisan schedule:run` | One cron entry. The schedule itself is defined in `Backend/routes/console.php` (Laravel 11 has no `app/Console/Kernel.php`). |

### Queue

`QUEUE_CONNECTION=database` is already the default in `.env.example` — jobs are
stored in the `jobs` table, so the worker needs no extra infrastructure. Run at
least one worker; `--tries=3 --timeout=90` means a job gets three attempts and
must finish inside 90 seconds, which comfortably covers every current job
(FCM push, PDF generation) and will need revisiting only if T-31's LLM calls
are dispatched as jobs.

Restart the worker after every deploy:

```bash
php artisan queue:restart
```

### Scheduler

Production: a single cron entry, owned by the web user.

```cron
* * * * * cd /path/to/TAssist/Backend && php artisan schedule:run >> /dev/null 2>&1
```

Local development: do **not** use cron. Run the scheduler in the foreground:

```bash
php artisan schedule:work
```

Inspect what is wired without running it:

```bash
php artisan schedule:list
```

Currently scheduled (valid today):

| Command | Frequency | Purpose |
|---|---|---|
| `sanctum:prune-expired --hours=24` | daily | Drops expired API tokens. |
| `queue:prune-failed --hours=168` | weekly | Drops failed jobs older than 7 days. |

Commented placeholders in `routes/console.php` are labelled with their task IDs
(T-22, T-27, T-33, T-43). They use `->withoutOverlapping()` deliberately: a
slow run must not stack behind the next one.

### Failed jobs

```bash
php artisan queue:failed          # list
php artisan queue:retry <id|all>  # retry
php artisan queue:forget <id>     # drop one
php artisan queue:flush           # drop all
```

Failed jobs survive in the `failed_jobs` table; the weekly
`queue:prune-failed --hours=168` entry is what keeps that table bounded. Any
recurring failure is a bug — check `storage/logs/laravel.log` before flushing.

---

## 2. Firebase (T-42)

### Ownership

- **Project owner:** the team account (decision **C6**), not a personal
  account. Losing access to the owner account loses FCM and the Admin SDK.
- The project must exist before T-42 starts; the Flutter side additionally
  needs `google-services.json` (Android) and `GoogleService-Info.plist` (iOS),
  which are also **not** committed.

### Service-account JSON (backend)

1. Firebase console → Project settings → Service accounts → *Generate new
   private key*.
2. Store the downloaded JSON **outside version control**. The supported in-repo
   location is:

   ```
   Backend/storage/app/firebase/service-account.json
   ```

   That directory is gitignored (`storage/app/firebase/.gitignore` ignores
   everything but itself). An absolute path outside the repo works too.
3. Point the environment at it with an **absolute** path:

   ```dotenv
   FIREBASE_CREDENTIALS=/var/www/TAssist/Backend/storage/app/firebase/service-account.json
   FIREBASE_PROJECT_ID=your-project-id
   ```

4. Rotate immediately if the file is ever pasted into a chat, issue or commit.
   Deleting the key in the Firebase console revokes it.

`Backend/config/firebase.php` already reads both variables (null defaults).
The `kreait/laravel-firebase` package itself is installed in **T-42**; it
consumes `firebase.credentials.file` and `firebase.project_id` from that file,
so no further wiring is needed when it lands.

### Client config

`google-services.json` / `GoogleService-Info.plist` are per-environment and
gitignored. The build must fail loudly rather than fall back to a shared
project — a debug build talking to production FCM is not a useful default.

---

## 3. Google AI Studio / Gemini (T-06)

Blocks T-31 (chatbot).

1. Create the project at <https://aistudio.google.com/app/apikey> using the
   same **team** account that owns Firebase, and generate an API key there.
2. The key is **per environment**. Local, staging and production each get their
   own key so one leaked key or exhausted quota cannot take down the others.
3. Put it in `.env` only:

   ```dotenv
   GEMINI_API_KEY=...
   GEMINI_MODEL=gemini-2.0-flash
   GEMINI_DAILY_REQUEST_LIMIT=
   ```

   `Backend/config/services.php` → `services.gemini` reads all three. The limit
   defaults to `null` (unset) until the figure below is recorded.
4. **Record the free-tier requests/day figure here once the project is
   created.** Google changes it per model and per region, so it must be read
   from the AI Studio quota page at provisioning time, not copied from a blog
   post.

   | Model | Free-tier requests/day | Recorded on | By |
   |---|---|---|---|
   | _pending — fill in at T-06 provisioning_ | | | |

The chatbot must enforce this limit server-side (T-31); the config value exists
so the cap is data, not a constant.

---

## 4. Pre-deploy checklist

- [ ] `.env` present on the host, `APP_KEY` set, `APP_DEBUG=false`.
- [ ] `php artisan migrate --force` run.
- [ ] `php artisan config:cache` + `php artisan route:cache` run.
- [ ] Queue worker supervised and started; `php artisan queue:restart` after deploy.
- [ ] Cron entry installed; `php artisan schedule:list` shows the entries above.
- [ ] `FIREBASE_CREDENTIALS` points at an existing, readable JSON file.
- [ ] `storage/` and `bootstrap/cache/` writable by the web user.
