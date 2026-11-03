# Localization: evaluation

Part of #62 (U10). The app has no localization: every user-facing string is
an English literal in the widget that shows it. This note records the
evaluation the issue asked for and a recommendation; it does not migrate
anything yet.

## Where things stand

- No `flutter_localizations`, no `intl`, no ARB files.
- Roughly 80 `Text('…')` literals in `lib/features`, plus strings built in
  view models (error messages via `describeFailure` / `describeUnexpected`,
  feedback text passed to `showFeedback`) and tooltips/semantics labels.
- Plurals are handled by `pluralize()` in `lib/core/utils/formatters.dart`,
  which only knows English ("1 track", "2 tracks").
- Dates use `formatRelativeTime()`, also English-only ("3h ago").

## Recommendation

Adopt `flutter_localizations` + `gen_l10n` with a single `app_en.arb` now,
before the string count grows further:

1. Add `flutter_localizations` and `intl` to `pubspec.yaml`, `generate: true`
   under `flutter:`, and an `l10n.yaml` pointing at `lib/l10n/app_en.arb`.
2. Wire `localizationsDelegates` / `supportedLocales` in `MaterialApp.router`.
3. Migrate in this order, each a reviewable PR:
   - the shared components (`MediaCard`, `TrackRow`, `showTrackActions`,
     dialogs, `showFeedback`, `InlineBanner` defaults) — highest reuse;
   - `pluralize` and `formatRelativeTime` → ICU plural/select messages and
     `intl`'s `DateFormat`/`RelativeDateTime`;
   - `describeFailure` / `describeUnexpected` → messages with an `{action}`
     placeholder (the action phrases become their own keys);
   - page copy, one page per change.
4. Add a test that fails on new `Text('…')` literals in `lib/features`,
   like the design-token guardrail, once the migration is far enough along.

English-only ARB still pays off on its own: one place to review copy, and
plural forms that are correct by construction rather than by `pluralize`.

## Not recommended

- A hand-rolled `Strings` class of constants: it centralises copy but gives
  no plural/gender handling and has to be replaced again for a second
  language.
- Translating before the shared components are migrated: most strings live
  in them, and translating page copy first would duplicate the work.
