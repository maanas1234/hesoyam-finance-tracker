-- Finance Tracker — Supabase Schema
-- Run this in your Supabase SQL editor

create table if not exists transactions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid references auth.users(id) on delete cascade not null,
  amount           decimal(12, 2) not null,
  type             text not null check (type in ('debit', 'credit')),
  merchant         text,
  category         text not null default 'Other',
  bank             text,
  raw_sms          text,
  transaction_date timestamptz not null,
  created_at       timestamptz not null default now(),
  sms_hash         text unique  -- prevents duplicate imports
);

-- Row Level Security: users can only read/write their own rows
alter table transactions enable row level security;

create policy "select own transactions"
  on transactions for select
  using (auth.uid() = user_id);

create policy "insert own transactions"
  on transactions for insert
  with check (auth.uid() = user_id);

create policy "delete own transactions"
  on transactions for delete
  using (auth.uid() = user_id);

-- Indexes for common queries
create index if not exists idx_txn_user_date
  on transactions (user_id, transaction_date desc);

create index if not exists idx_txn_user_category
  on transactions (user_id, category);
