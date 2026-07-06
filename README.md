# HESOYAM — Automated Finance Tracker

A fully automated personal finance tracker that reads bank SMS on Android, syncs to the cloud, and provides a rich analytics dashboard — zero manual entry.

## Features

- **Auto SMS import** — reads ICICI (and other bank) transaction SMS, deduplicates via hash, syncs to Supabase
- **Flutter Android app** — home screen with month navigator, pull-to-refresh, manual add option
- **Analytics tab** — category pie chart, merchant rankings, 6-month bar chart, month-by-month filter
- **Home screen widget** — 4×2 tile showing monthly spend; tap to toggle between Spent / Received
- **Dark / light theme** — persists across restarts
- **React web dashboard** — Overview, Analytics, Transactions tabs with full Recharts visualizations
- **Supabase backend** — Postgres with Row Level Security; anon key safe for client-side use

## Stack

| Layer | Tech |
|---|---|
| Android app | Flutter 3.x |
| Charts (app) | fl_chart |
| Backend | Supabase (Postgres + Auth + RLS) |
| Web dashboard | React + Vite + TypeScript |
| Charts (web) | Recharts |

## Project Structure

```
├── flutter_app/          # Android app
│   ├── lib/
│   │   ├── config.dart.example   # copy → config.dart and fill in keys
│   │   ├── main.dart
│   │   ├── screens/
│   │   └── services/
│   └── android/
├── web_dashboard/        # React web dashboard
│   ├── src/
│   └── .env.local        # gitignored — see setup below
└── supabase/
    └── schema.sql        # run once in Supabase SQL editor
```

## Setup

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase/schema.sql` in the SQL editor
3. Copy your **Project URL** and **anon key** from Settings → API

### 2. Flutter app

```bash
cd flutter_app
cp lib/config.dart.example lib/config.dart
# edit config.dart — paste your Supabase URL and anon key
flutter pub get
flutter run
```

### 3. Web dashboard

```bash
cd web_dashboard
cp .env.local.example .env.local   # or create manually
# .env.local:
#   VITE_SUPABASE_URL=https://your-project.supabase.co
#   VITE_SUPABASE_ANON_KEY=your-anon-key
npm install
npm run dev
```

## Web Dashboard `.env.local`

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

---

> Built with [Claude Code](https://claude.ai/code)
