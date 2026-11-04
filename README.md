# Contact Reporter

A separate app from Nursery Manager. The owner keeps a contact book, puts contacts into groups and assigns the groups to callers. A caller taps Call on an assigned contact, the phone dialer opens, and when the caller comes back to the app a short report form opens. The owner sees every call and report in the Call Log, filtered by caller, group and date.

- Web app (iPhone and Android): deployed by `.github/workflows/pages.yml` to GitHub Pages.
- Android APK: built by `.github/workflows/build-apk.yml` (package `com.oxygenplanterium.contactreporter`, so it installs next to Nursery Manager).

## One-time setup
1. Repository Settings, Pages, Source: **GitHub Actions**.
2. Nothing to run in Supabase. The app uses the same Supabase project and sign-in accounts as Nursery Manager but writes only to its own records (paths starting with `cr/`). It never reads or changes Nursery Manager data.

## Data
- `cr/book`: contacts, groups and callers.
- `cr/log/YYYY-MM-DD`: calls and reports for each day.
