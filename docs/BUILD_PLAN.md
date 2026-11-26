# Store Quote App — Build Plan

Flutter app for MediSupply BD purchase stores: sign in, quote price + qty for the day's products, see approvals, follow sales / payments / due.

- **Design source:** `docs/Store Quote App – Screens.pdf` (8 screens)
- **API source:** `docs/store-quote-app-api.md`
- **Base URL:** `https://medisupplybd.softwhile.com/api/store-app`

We build one phase at a time. Each phase ends with something you can run and check on a phone.

---

## Design direction

The PDF uses navy blue. We keep its **layout** and switch the colors to a **green** theme. The style stays minimal: light background, white rounded cards, one strong accent color.

| Token | Color | Use |
|---|---|---|
| Primary | `#1B7A4B` (deep green) | Hero card, main buttons, active tab, links |
| Primary dark | `#145C38` | Pressed states, app bar on the quote screen |
| Primary light | `#E3F3EA` | Chips, "Done"/"Approved" badges, selected segment |
| Background | `#F4F6F5` | Screen background |
| Surface | `#FFFFFF` | Cards, inputs |
| Border | `#E1E5E3` | Card and input borders |
| Text | `#17201B` / muted `#5F6B65` | Titles / secondary text |
| Received (positive) | `#2E7D32` | Received amounts, zero due |
| Due (negative) | `#C62828` | Due amounts, Log out |
| Warning | `#FCEBD0` bg / `#8A5A00` text | "Needs price", "Pending", "Awaiting approval" |

- Font: Inter (via `google_fonts`), matching the PDF.
- Cards: 16 px radius, 1 px border, no heavy shadows.
- Money shown as `৳63,925` (Taka sign + thousands commas).
- Bottom navigation: Home · Quote · History · Reports · Profile, with a green bar on the active tab.

---

## Tech stack

| Need | Package |
|---|---|
| State management | `flutter_riverpod` |
| Navigation | `go_router` (bottom tabs with `StatefulShellRoute`, redirect to sign-in on logout / 401) |
| HTTP | `dio` (interceptor adds `X-Store-Key`, handles 401/422/423/429) |
| Save `store_key` | `flutter_secure_storage` |
| Money & dates | `intl` |
| Open / download PDFs | `url_launcher` (open `pdf_url` in the phone's viewer); optionally `dio` download + `open_filex` |
| Font | `google_fonts` |
| Product images | `cached_network_image` |

## Folder structure

```
lib/
  main.dart
  app.dart                  # MaterialApp.router + theme
  core/
    theme/                  # colors, text styles, ThemeData
    network/                # dio client, interceptors, ApiResponse, ApiException
    storage/                # secure storage for store_key
    utils/                  # money/date formatters, countdown helper
    widgets/                # shared: AppCard, StatusBadge, MoneyTile, PrimaryButton,
                            #         LoadingView, ErrorView, EmptyView
  features/
    auth/                   # Screen 1  — login, logout, session state
    home/                   # Screen 2  — /home
    quote/                  # Screens 3, 4 — /quote GET + POST
    approved/               # Screen 5  — /approved, /approved/list, PDF
    history/                # Screen 6  — /history
    reports/                # Screen 7  — /reports, image download
    profile/                # Screen 8  — /profile, /change-pin, logout
  router/                   # go_router config + shell with bottom nav
```

Each feature folder has `data/` (models + repository), `providers/` and `presentation/` (screens + widgets).

---

## Phase 1 — Foundation ✅ Done

> Notes: `google_fonts` is pinned to `^8.0.0` (v9 targets the new `material_ui` package and does not work with this Flutter SDK). `android/gradle.properties` has `kotlin.incremental=false` because the project (D:) and pub cache (C:) are on different drives. The sign-in screen has a debug-only "Preview app" button, which is removed in Phase 2.

**Goal:** the app runs with the green theme, empty tab screens and a working API layer.

- Add the packages above to `pubspec.yaml`.
- Set app name to "Store Quote", add the MediSupply BD logo to `assets/images/`.
- Build the theme: colors, Inter font, input, button, card and chip styles.
- Shared widgets: `AppCard`, `StatusBadge`, `MoneyTile`, `PrimaryButton`, loading / error / empty views.
- Formatters: `৳` money with commas, `Y-m-d` dates, `HH:MM:SS` countdown.
- Network layer:
  - `dio` client with base URL and `Accept: application/json`.
  - Interceptor adds `X-Store-Key` from secure storage.
  - Parse `{ status, message, data }`; turn errors into `ApiException` (with field `errors` for 422).
  - On `401` → clear the key and send the user to Sign in.
  - Friendly messages for no internet, 423 and 429.
- Router with bottom-nav shell (Home, Quote, History, Reports, Profile) holding placeholder screens.
- Android: internet permission.

**Check:** app launches in green, tabs switch.

## Phase 2 — Sign in & session (Screen 1) ✅ Done

> Notes: the debug "Preview app" button is gone. The last phone/email used is remembered (never the PIN). Profile has a temporary Log out button until Phase 7.

- Sign-in screen: logo, "Store Quote", phone/email field, 6-digit PIN field (hidden, show/hide toggle), Sign in button, info card "Quotes are accepted only during your daily quote window."
- `POST /login` → save `store_key` + store info.
- Field validation, loading state on the button, error text for 401 / 429.
- On app start: key saved → go to Home; no key → Sign in.
- Logout logic (`POST /logout`, then delete key) — the button itself comes in Phase 7.

**Check:** sign in with a real store, close and reopen the app and stay signed in.

## Phase 3 — Home (Screen 2) ✅ Done

> Notes: the "Last quote" card opens History for now; Phase 5 points it at Approved quotes for that date.

- `GET /home`, pull-to-refresh.
- Header: "Store name · date_label", title "Home".
- Green hero card: window chip (`window.label`), "N products to quote", "X priced · 02:14:08 left" with a live countdown from `seconds_left`; reload `/home` at 0.
- "Quote now" button → Quote tab; disabled when `can_quote` is false.
- Today tiles: Sales / Received (green) / Due (red).
- Total outstanding due card with "View report" → Reports tab.
- Last quote card ("19 Nov · 5 of 8 approved · ৳63,925"), tap → Approved quotes for that date; hidden when `null`.

**Check:** numbers match the admin panel; countdown ticks.

## Phase 4 — Products to quote (Screens 3 & 4) ✅ Done

> Notes: search filters today's list on the phone (instant, and typed prices are never lost) instead of calling `?q=`. Typed prices survive tab switches. Each Send sends every filled line; emptied lines are sent as 0/0 to remove them.

The main screen of the app.

- `GET /quote`, with a search box (`?q=`, debounced).
- **Window open (Screen 3):**
  - Green header: store name, title, window chip, countdown, progress bar "3 of 8 priced".
  - Product cards: name, brand / pack, optional image, `needed_qty` hint and `request_note`, status badge (Needs price / Done / Approved / Rejected), Price (৳) and Qty number inputs pre-filled from `my_price` / `my_qty`.
  - Read-only cards when `editable` is false.
  - Optional note field ("Delivery after 3 PM").
  - Sticky bottom button "Send N quotes" (N = lines with both price and qty filled).
  - `POST /quote` → success snackbar, reload the list. Clearing a line sends `0/0` to remove it.
  - Handle 423 (window closed while typing → switch to closed view) and 422.
  - Warn before leaving with unsent changes.
- **Window closed (Screen 4):**
  - Lock card: "Quoting is closed · Your window is 10:00 – 14:00 daily. Next window opens …"
  - "Today's quotes" card from `todays_quote` with its status badge ("Awaiting approval").
  - Disabled "Send quotes" button.
- When the countdown hits 0, reload so the screen flips between open and closed.

**Check:** send quotes, see badges flip to Done, edit and resend, see the closed view outside the window.

## Phase 5 — Approved quotes & History (Screens 5 & 6) ✅ Done

> Notes: routes `/history/approved?date=` and `/history/approved-range`. PDFs open in the phone's browser / PDF viewer via a link that includes `store_key` (as the API is designed). Home's "Last quote" card now opens Approved quotes for that date.

- **History (tab):** `GET /history` with infinite scroll (page / last_page), pull-to-refresh. Each card: date, "5 of 8 approved · ৳63,925" (`৳—` when 0), status badge (Pending / Approved / Partly approved / Rejected), "PDF" link → open `pdf_url`. Tap a card → Approved quotes for that date.
- **Approved quotes:** `GET /approved?date=`. "5 of 8 approved" chip, item rows (name, `৳620 × 40`, line total), Total row, "3 quotes were not approved today.", `bill_no` when present, "Download PDF" button.
- **Date-range filter:** a "From – To" picker on the Approved screen using `GET /approved/list` — range summary (days, lines, amount) and day-by-day expandable sections with their own PDF link; paginated.
- PDF handling: open in the phone's PDF viewer (with the `store_key` parameter); show an error if no viewer / no network.

**Check:** history matches the panel, PDFs open, date filter returns the right days.

## Phase 6 — Reports (Screen 7) ✅ Done

> Notes: each period's report is cached while the app runs, so switching Daily / Weekly / Monthly is instant after the first load; pull-to-refresh reloads the visible period. The selected period resets to Daily when a different store signs in. No PDF: "Download Report" saves the report (store, period, range, tiles, full table, generated time) as an image to the Gallery ("Store Quote" album), like "Download Orders" on Approved quotes.

- Segmented control: Daily · Weekly · Monthly → `GET /reports?period=`.
- Subtitle from `range_label`, title "Sales & collection".
- Summary tiles: Sales / Received / Due.
- Table: Date · Sale · Received (green) · Due (red, or green when 0).
- "Download Report" → save the report as an image to the Gallery (no PDF).
- Remember the selected period while switching tabs.

**Check:** totals match the panel for all three periods.

## Phase 7 — Profile (Screen 8) ✅ Done

> Notes: Change PIN also blocks a new PIN equal to the current one. PIN fields keep the same keyboard as sign-in (PINs may contain letters). Log out stays visible even when the profile fails to load. Loading `/profile` refreshes the cached store name.

- `GET /profile`: info card with Phone, Quote window (`opens_at – closes_at`), App PIN → "Change PIN".
- Notifications list (title, body, `time_ago`) with an icon per `type` (quote_reviewed, window, payment); empty state.
- Change PIN bottom sheet: current / new / confirm (min 6, must match) → `POST /change-pin`, show 422 messages under fields.
- "Log out" button (red outline) with confirm dialog → back to Sign in.

**Check:** change PIN and sign in with the new one; logout clears the session.

## Phase 8 — Polish & release ✅ Done

> Notes: the app is now named **Medi Purchase** (icon label, sign-in title, Gallery album) with app id **`com.medisupplybd.purchase`** (Android + iOS). Launcher icon and launch screen come from `assets/images/lon_icon.jpg` (generated PNGs in `assets/icon/`). The offline banner sits above the bottom nav; after 30 s+ in the background (or on reconnecting) Home, Quote, Reports and Profile reload — History keeps its loaded pages. Release signing reads `android/key.properties`; see `docs/RELEASE.md`. Price / Qty already used number keyboards; PIN keeps the text keyboard.

- Loading skeletons, consistent empty and error states with "Try again".
- Offline banner; refresh data when the app comes back to the foreground (the window may have opened or closed).
- Accessibility: tap targets ≥ 48 px, text scaling, contrast check on the green.
- App icon and splash screen with the MediSupply BD logo (`flutter_launcher_icons`, `flutter_native_splash`).
- Lock to portrait; number keyboards on price / qty / PIN.
- Basic tests: formatters, API response parsing, quote "send" logic.
- Release build: app id, version, Android signing, `flutter build apk` / `appbundle`.

---

## Things to confirm along the way

1. **Logo file:** please put the MediSupply BD logo (PNG, ideally transparent) in the project, or I'll crop it from the PDF.
2. **Sign-in label:** the PDF says "Phone number", but the API also accepts email. Plan: label "Phone or email".
3. **Platforms:** plan targets Android first (iOS works with the same code). Tell me if you also need web / desktop.
4. **Approved screen access:** it isn't a tab in the design. Plan: open it from History cards and from the "Last quote" card on Home.
