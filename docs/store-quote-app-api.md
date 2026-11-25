# Store Quote App — API guide

API for the **Store Quote** mobile app (Products to Quote). Each purchase store uses it to:

- sign in
- quote prices for the day's products
- see what was approved
- follow its sales, payments and due

The admin panel runs everything else:

- **Products to Quote → Products to Quote**: the day's products and quantities.
- **Portal Settings**: one daily quote window for every store.
- **Compare by Product**: approval.
- **Purchase Stores**: the stores, with phone, email, password (App PIN) and Active / Inactive.

The screens follow `Store Quote App – Screens.pdf` (8 screens). Each section below says which screen it is for.

---

## 1. Basics

| | |
|---|---|
| Base URL | `https://medisupplybd.softwhile.com/api/store-app` |
| Format | JSON in and out. Send `Accept: application/json`. |
| Auth | **No bearer token.** Login returns a `store_key`; send it with every call (see 1.2). |
| Dates | `Y-m-d` (e.g. `2026-11-20`). Times are Bangladesh time, `HH:MM` (24 h). |
| Money | Plain numbers in Taka (e.g. `63925.5`). The app adds the ৳ and the commas. |

### 1.1 Response shape

Every JSON response has the same shape:

```json
{ "status": 200, "message": "OK", "data": { } }
```

On an error, `status` is the HTTP code and `data` is `null`:

| HTTP | When |
|---|---|
| `401` | Wrong phone/email or PIN at login. Or on any other call: `store_key` is missing or invalid, or the store was made **Inactive** or deleted. **Go back to the sign-in screen.** |
| `422` | The input is not valid. A validation error has an `errors` object, one entry per field. |
| `423` | Quotes were sent while quoting is closed. |
| `429` | Too many requests. Wait a minute. |

### 1.2 `store_key`

- Login returns `data.store_key`, a long encrypted string (`eyJpdiI6…`). Save it on the phone.
- Send it with **every** call, in either of these ways:
  - as a header: `X-Store-Key: <store_key>` (recommended)
  - as a parameter: `?store_key=<store_key>` for GET requests, or `"store_key"` in the JSON body for POST requests

  The PDF links below use the parameter, so they can be opened directly in a browser or a download manager.
- The key does not expire. It stops working when:
  - the panel makes the store **Inactive** or deletes it, or
  - the server's `APP_KEY` changes.

  The call then answers `401`. Clear the key and show Sign in.
- **Logout** just deletes the key on the phone. `POST /logout` exists, but nothing has to happen on the server.

---

## 2. Sign in — *Screen 1*

### `POST /login`

The store signs in with its **phone number or email** (as saved under Purchase Stores) and its **password / App PIN**. Only **Active** stores can sign in. You can try 10 times per minute.

Request:

```json
{ "login": "01712345678", "pin": "123456" }
```

You can also send an email address as `login`, e.g. `"login": "store@example.com"`. Phone numbers are matched on their digits only, so `017-1234 5678` works too.

Response `200`:

```json
{
  "status": 200,
  "message": "Signed in",
  "data": {
    "store_key": "eyJpdiI6IlUrTkdn...In0",
    "store": { "name": "Green Corner Store", "company": null, "phone": "01712345678", "email": "store@example.com" }
  }
}
```

Response `401`: `"Phone number / email or PIN is not correct."`

### `POST /logout`

Always returns `200`. The app deletes its saved `store_key`.

---

## 3. Home — *Screen 2*

### `GET /home`

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "store": { "name": "Green Corner Store", "company": null, "phone": "01712345678", "email": null },
    "date": "2026-11-20",
    "date_label": "Fri, 20 Nov 2026",
    "window": {
      "open": true,
      "opens_at": "10:00",
      "closes_at": "14:00",
      "next_change": "2026-11-20T14:00:00+06:00",
      "seconds_left": 8048,
      "label": "Window open · closes 14:00"
    },
    "products_to_quote": 8,
    "priced": 3,
    "can_quote": true,
    "today": { "sales": 63925, "received": 40000, "due": 23925 },
    "total_due": 184500,
    "last_quote": {
      "date": "2026-11-19", "date_label": "Thu, 19 Nov 2026", "quote_no": "SQ-000041",
      "total_items": 8, "approved_count": 5, "rejected_count": 3, "pending_count": 0,
      "approved_amount": 63925, "status": "partial", "status_label": "Partly approved"
    }
  }
}
```

| Screen part | Field |
|---|---|
| "Window open · closes 14:00" | `window.label` (or build it from `window.open` and `window.closes_at`) |
| Countdown "02:14:08 left" | `window.seconds_left`. Count it down on the phone and call `/home` again when it reaches 0. |
| "8 products to quote" | `products_to_quote` |
| "3 priced" | `priced` |
| **Quote now** button | Opens screen 3. Disable it when `can_quote` is `false`. |
| Today: Sales / Received / Due | `today.sales`, `today.received`, `today.due` |
| Total outstanding due | `total_due` |
| Last quote "19 Nov · 5 of 8 approved · ৳63,925" | `last_quote` (`null` when there is none) |

How the money is counted:

- **Sales**: MediSupply's purchase bills from this store.
- **Received**: MediSupply's payments to this store.
- **Due**: Sales − Received for that period.
- **`total_due`**: everything still owed to the store, which is opening due + all bills − all payments.

---

## 4. Products to quote — *Screens 3 and 4*

### `GET /quote`

Optional: `?q=napa` searches the list by name.

- **The window is open** (`window.open: true`) → show screen 3, the products list with Price and Qty boxes.
- **The window is closed** → show screen 4. `products` is empty; show the lock card using `window.opens_at` and `window.closes_at`. Show the "Today's quotes" card from `todays_quote`.

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "date": "2026-11-20",
    "date_label": "Fri, 20 Nov 2026",
    "window": { "open": true, "opens_at": "10:00", "closes_at": "14:00", "next_change": "2026-11-20T14:00:00+06:00", "seconds_left": 8048, "label": "Window open · closes 14:00" },
    "total": 8,
    "priced": 3,
    "products": [
      {
        "product_id": 120,
        "name": "Napa 500 mg (100 pcs)",
        "brand": "Beximco Pharmaceuticals Ltd.",
        "image_url": "https://<your-domain>/storage/products/napa.jpg",
        "needed_qty": 40,
        "request_note": "Box of 100 preferred",
        "my_price": 620,
        "my_qty": 40,
        "status": "done",
        "editable": true
      },
      {
        "product_id": 121,
        "name": "Seclo 20 mg (30 pcs)",
        "brand": "Square Pharmaceuticals PLC",
        "image_url": null,
        "needed_qty": null,
        "request_note": null,
        "my_price": null,
        "my_qty": null,
        "status": "needs_price",
        "editable": true
      }
    ],
    "todays_quote": {
      "quote_no": "SQ-000052", "items": 3, "sent_at": "11:42",
      "status": "pending", "status_label": "Pending", "note": null
    }
  }
}
```

| Field | Meaning |
|---|---|
| `status` | `needs_price`: not quoted yet (badge "Needs price"). `done`: quoted, waiting for a decision (badge "Done"). `approved` / `rejected`: already decided in the panel. |
| `editable` | `false` once the line is approved or rejected. Show it read-only, because the server ignores changes to it. |
| `needed_qty` | How many MediSupply wants (`null` = not set). |
| Progress "3 of 8 priced" | `priced` of `total` |
| `todays_quote` | What the store already sent today (`null` = nothing yet). The closed screen shows "8 products sent at 11:42 · Awaiting approval". |

### `POST /quote` — "Send N quotes"

The store can send as many times as it likes **while the window is open**. Each send adds lines or updates them. A product with `price` or `qty` set to `0` is **taken off** the quote.

```json
{
  "items": [
    { "product_id": 120, "price": 620, "qty": 40 },
    { "product_id": 121, "price": 845, "qty": 25 },
    { "product_id": 122, "price": 0, "qty": 0 }
  ],
  "note": "Delivery after 3 PM"
}
```

Response `200`:

```json
{ "status": 200, "message": "Quotes sent", "data": { "quote_no": "SQ-000052", "items": 8, "sent_at": "11:42" } }
```

| Error | Meaning |
|---|---|
| `423` | `"Quoting is closed now. It opens at 10:00."` |
| `422` | None of the products can be quoted. Each one is either not on today's list or already decided. |

The server leaves out, without an error:

- products that are not on today's list
- lines that are already approved or rejected

---

## 5. Approved quotes — *Screen 5*

### `GET /approved`

Optional: `?date=2026-11-19`. Without it, you get the latest day that has an approved line.

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "date": "2026-11-19",
    "date_label": "Thu, 19 Nov 2026",
    "quote_no": "SQ-000041",
    "bill_no": "PUR-000182",
    "total_items": 8,
    "approved_count": 5,
    "not_approved_count": 3,
    "pending_count": 0,
    "items": [
      { "product_id": 120, "name": "Napa 500 mg (100 pcs)", "brand": "Beximco Pharmaceuticals Ltd.", "qty": 40, "unit_price": 620, "total": 24800 }
    ],
    "total": 63925
  }
}
```

| Screen part | Field |
|---|---|
| "5 of 8 approved" | `approved_count` of `total_items` |
| Each line "৳620 × 40" and "৳24,800" | `unit_price`, `qty` and `total` |
| "Total ৳63,925" | `total` |
| "3 quotes were not approved today." | `not_approved_count` |

`qty` is the **approved** quantity, which can be less than what the store offered. `bill_no` is the purchase bill made in the panel (`null` until there is one).

### `GET /approved/list` — approved quotes, date-wise filter

Use this when the store picks a date range ("From – To"). It returns every day in the range that has at least one approved line, newest first, with that day's approved lines and the totals for the whole range.

| Parameter | Default | Meaning |
|---|---|---|
| `from` | 29 days before `to` | First day, `Y-m-d` |
| `to` | today | Last day, `Y-m-d`. It cannot be before `from`. |
| `items` | `1` | Use `0` to get only each day's summary, without the product lines. That is faster for a long range. |
| `page`, `per_page` | `1`, `20` | Paging; `per_page` can be 5–50 |

Example: `GET /approved/list?from=2026-11-01&to=2026-11-20`

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "from": "2026-11-01",
    "to": "2026-11-20",
    "range_label": "01 Nov 2026 – 20 Nov 2026",
    "summary": { "days": 12, "approved_lines": 64, "amount": 742150 },
    "days": [
      {
        "date": "2026-11-19", "date_label": "Thu, 19 Nov 2026",
        "quote_no": "SQ-000041", "bill_no": "PUR-000182",
        "total_items": 8, "approved_count": 5, "not_approved_count": 3, "pending_count": 0,
        "items": [
          { "product_id": 120, "name": "Napa 500 mg (100 pcs)", "brand": "Beximco Pharmaceuticals Ltd.", "qty": 40, "unit_price": 620, "total": 24800 }
        ],
        "total": 63925,
        "pdf_url": "https://<your-domain>/api/store-app/approved/pdf?store_key=eyJ...&date=2026-11-19"
      }
    ],
    "page": 1,
    "last_page": 1
  }
}
```

- `summary` covers the **whole range**, on all pages. `days` is the current page only.
- A bad date or a `to` before `from` returns `422`, with the problem field in `errors`.

### `GET /approved/pdf?date=2026-11-19&store_key=…` — "Download PDF"

Returns a PDF file (`approved-2026-11-19.pdf`). Open it with the phone's PDF viewer or download it.

---

## 6. Quote history — *Screen 6*

### `GET /history`

Optional: `?page=2&per_page=20` (`per_page` can be 5–50; the default is 20). Newest day first.

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "items": [
      {
        "date": "2026-11-20", "date_label": "Fri, 20 Nov 2026", "quote_no": "SQ-000052",
        "total_items": 8, "approved_count": 0, "rejected_count": 0, "pending_count": 8,
        "approved_amount": 0, "status": "pending", "status_label": "Pending",
        "pdf_url": "https://<your-domain>/api/store-app/approved/pdf?store_key=eyJ...&date=2026-11-20"
      }
    ],
    "page": 1,
    "last_page": 3,
    "total": 46
  }
}
```

| Screen part | Field |
|---|---|
| "5 of 8 approved · ৳63,925" | `approved_count` of `total_items`, and `approved_amount` |
| Badge | `status_label`. The values are `pending` → Pending, `approved` → Approved, `partial` → Partly approved, `rejected` → Rejected. |
| **PDF** | Open `pdf_url`. |

---

## 7. Reports: sales & collection — *Screen 7*

### `GET /reports?period=daily`

`period` is one of:

- `daily`: the last 7 days, one row per day. This is the default.
- `weekly`: the last 8 weeks, Saturday to Friday, one row per week.
- `monthly`: the last 6 months, one row per month.

Rows are newest first.

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "period": "daily",
    "range_label": "Last 7 days · 14 Nov–20 Nov",
    "summary": { "sales": 423775, "received": 327500, "due": 96275 },
    "rows": [
      { "label": "20 Nov", "from": "2026-11-20", "to": "2026-11-20", "sales": 63925, "received": 40000, "due": 23925 },
      { "label": "19 Nov", "from": "2026-11-19", "to": "2026-11-19", "sales": 58400, "received": 58400, "due": 0 }
    ]
  }
}
```

Each row's `due` is that row's Sales − Received. This differs from the store's total balance, which is `total_due` on `/home`.

### `GET /reports/pdf?period=daily&store_key=…` — "Download report PDF"

Returns a PDF of the same report.

---

## 8. Profile, PIN and notifications — *Screen 8*

### `GET /profile`

```json
{
  "status": 200,
  "message": "OK",
  "data": {
    "store": { "name": "Green Corner Store", "company": null, "phone": "01712345678", "email": "store@example.com" },
    "window": { "open": false, "opens_at": "10:00", "closes_at": "14:00", "next_change": "2026-11-21T10:00:00+06:00", "seconds_left": 64800, "label": "Quoting is closed · opens 10:00" },
    "notifications": [
      { "type": "quote_reviewed", "title": "Quote approved", "body": "5 of 8 products approved for 19 Nov.", "at": "2026-11-20T09:15:00+06:00", "time_ago": "2 hours ago" },
      { "type": "window", "title": "Window opens at 10:00", "body": "Today's products are ready to quote.", "at": "2026-11-20T10:00:00+06:00", "time_ago": "Today" },
      { "type": "payment", "title": "Payment received", "body": "৳40,000 recorded for 20 Nov.", "at": "2026-11-19T17:30:00+06:00", "time_ago": "1 day ago" }
    ]
  }
}
```

- "Quote window 10:00 – 14:00" comes from `window.opens_at` and `window.closes_at`. It is the same for every store and is set in Portal Settings.
- The notifications are built from what happened in the **last 14 days** (newest first, at most 20):
  - a quote was approved or not approved
  - today's window, when there are products to quote
  - a payment was recorded

  There are no push notifications yet.

### `GET /notifications`

Just the `notifications` list from `/profile`.

### `POST /change-pin` — "Change PIN"

You can try 10 times per minute.

```json
{ "current_pin": "123456", "new_pin": "654321", "new_pin_confirmation": "654321" }
```

| Response | Meaning |
|---|---|
| `200` | `"PIN changed"`. The `store_key` keeps working. |
| `422` | `"The current PIN is not correct."`, or the new PIN is shorter than 6 characters or the two new PINs do not match. |

---

## 9. All endpoints

| Method | Path | Screen | Notes |
|---|---|---|---|
| POST | `/login` | 1 | `login` (phone or email), `pin`. Returns `store_key`. |
| POST | `/logout` | 8 | Nothing to do on the server. |
| GET | `/home` | 2 | |
| GET | `/quote` | 3, 4 | `?q=` search |
| POST | `/quote` | 3 | `items[]`, `note`. Only while the window is open. |
| GET | `/approved` | 5 | `?date=`: one day |
| GET | `/approved/list` | 5 | `?from=&to=&items=&page=&per_page=`: date-wise filter |
| GET | `/approved/pdf` | 5, 6 | `?date=&store_key=`. Returns a PDF. |
| GET | `/history` | 6 | `?page=&per_page=` |
| GET | `/reports` | 7 | `?period=daily\|weekly\|monthly` |
| GET | `/reports/pdf` | 7 | `?period=&store_key=`. Returns a PDF. |
| GET | `/profile` | 8 | Includes the notifications. |
| GET | `/notifications` | 8 | |
| POST | `/change-pin` | 8 | `current_pin`, `new_pin`, `new_pin_confirmation` |

Every call except `/login` and `/logout` needs `store_key`, sent as the `X-Store-Key` header or the `store_key` parameter.

---

## 10. Existing APIs (unchanged)

These APIs keep working exactly as before. They are separate from the Store Quote app.

### 10.1 Older supplier app API — `/api/supplier-app` (Sanctum token)

| Method | Path | Notes |
|---|---|---|
| POST | `/api/supplier-app/login` | `phone`, `pin`. Returns a Sanctum `token`. |
| GET | `/api/supplier-app/today` | Today's list and the store's own prices. Needs `Authorization: Bearer <token>`. |
| POST | `/api/supplier-app/today` | Submit prices (`items[]`, `note`). |
| GET | `/api/supplier-app/approved` | Approved lines, day by day (`?date=`). |
| GET | `/api/supplier-app/approved/pdf` | `?date=`. Returns a PDF. |
| POST | `/api/supplier-app/logout` | Revokes the token. |

### 10.2 Customer (pharmacy) app API

The customer app's endpoints (`/api/app/login`, `/api/products/search`, `/api/invoice/create`, `/api/order/list`, `/api/message/...` and the rest) are not changed. See `routes/api.php`.
