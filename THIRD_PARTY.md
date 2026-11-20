# Third-party licences

> Keep this file current: it is the audit trail for anything the app ships that
> is not plain BSD/MIT, and for any package that needed a manual decision.

---

## Syncfusion Flutter PDF Viewer â€” T-05

| Field | Value |
|---|---|
| Package | `syncfusion_flutter_pdfviewer` |
| Pinned version | `^33.2.13` (resolved **33.2.13**) |
| Licence tier | **Syncfusion Community Licence** |
| Owner action | Register the licence at <https://www.syncfusion.com/products/communitylicense> with the team account and record the key |

### Terms summary (from the package `LICENSE`)

Eligibility for the Community Licence requires **both**:

- gross annual revenue below **USD 1,000,000**, and
- fewer than **five developers** in the organisation,

and acceptance of Syncfusion's terms. Commercial use above those thresholds
requires a paid licence. The package cannot be used without either licence.

Syncfusion also asks for a small acknowledgement ("Powered by Syncfusion") in
the about screen / documentation; it is not a hard technical requirement but is
part of the programme's expectations.

### Registering the key

The key is a **build-time** value, never committed:

```bash
flutter run   --dart-define=SYNCFUSION_LICENSE_KEY=<key>
flutter build apk --dart-define=SYNCFUSION_LICENSE_KEY=<key>
```

`Frontend/lib/core/syncfusion_license.dart` exposes
`SyncfusionLicense.register()`, called from `main()` before `runApp`. It reads
the define via `String.fromEnvironment` and **does nothing when the key is
absent** â€” the app must build and run without it (CI has no key).

**Runtime registration API:** none exists in the installed version. The
Syncfusion Flutter 33.2.x sources in the pub cache
(`syncfusion_flutter_core-33.2.15`, `syncfusion_flutter_pdfviewer-33.2.13`)
contain no `SyncfusionLicense`, `SyncfusionLicenseRegistry` or
`registerLicense` symbol at all â€” earlier 2x releases exposed
`SyncfusionLicense.registerLicense()` from `syncfusion_flutter_core`, and it
was removed. So `register()` is deliberately a no-op today: calling a
non-existent symbol would not compile. The call site is kept so that if a
future version reintroduces a registry, only that one file changes.

### Decision note (T-05)

`syncfusion_flutter_pdfviewer` was chosen over `pdfrx`.
`pdfrx` was rejected because it has **no built-in annotation callbacks** â€” the
annotation MVP (T-13, T-09â€“T-12) needs hit-testing, selection and edit events
for highlights/sticky notes, which would have meant building a gesture and
coordinate layer on top of the viewer. Syncfusion ships
`HighlightAnnotation`, `UnderlineAnnotation`, `StrikethroughAnnotation`,
`SquigglyAnnotation`, `StickyNoteAnnotation` and the matching settings objects
directly.

Cost accepted: a commercial licence obligation and a heavier dependency
(`syncfusion_flutter_pdf`, `syncfusion_flutter_signaturepad`, per-platform
`syncfusion_pdfviewer_*` plugins).

---

## Other notable dependencies

| Package | Licence | Notes |
|---|---|---|
| `google_sign_in`, `google_fonts`, `http`, `shared_preferences`, `flutter_secure_storage`, `image_picker`, `file_picker` | BSD-3 / MIT / Apache-2.0 | Standard pub.dev licences, no action. |
| `kreait/laravel-firebase` (T-42) | MIT | Not installed yet; see `OPS_BASELINE.md`. |
