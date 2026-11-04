# Contact Reporter

A separate app from Nursery Manager. The owner keeps a contact book, puts contacts into groups and assigns the groups to callers. A caller taps Call on an assigned contact, the phone dialer opens, and when the caller comes back to the app a short report form opens. The owner sees every call and report in the Call Log, filtered by caller, group and date.

- Web app (iPhone and Android): deployed by `.github/workflows/pages.yml` to GitHub Pages.
- Android APK: built by `.github/workflows/build-apk.yml` (package `com.oxygenplanterium.contactreporter`, so it installs next to Nursery Manager).

## One-time setup
1. Repository Settings, Pages, Source: **GitHub Actions**.
2. Follow `docs/SETUP.md` to create the app's own Supabase project (run `supabase.sql`, switch off e-mail confirmation, create the owner login) and put its URL and key in `src/config.js`.

## Sign in
People create their own account with a phone number and password. The owner approves them in the Callers tab and assigns groups to them. Callers see only the groups assigned to them.

## Data
- `cr/users/<id>`: each person's account record (name, phone, pending or approved).
- `cr/g/<id>`: a group, its contacts and who it is assigned to.
- `cr/log/<date>/<id>`: one person's calls and reports for a day.
