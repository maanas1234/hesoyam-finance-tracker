import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Transaction } from '../types'
import Overview from '../tabs/Overview'
import Analytics from '../tabs/Analytics'
import Transactions from '../tabs/Transactions'

type Tab = 'overview' | 'analytics' | 'transactions'

export default function Dashboard() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<Tab>('overview')
  const [dark, setDark] = useState(() => localStorage.getItem('theme') === 'dark')

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light')
    localStorage.setItem('theme', dark ? 'dark' : 'light')
  }, [dark])

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    const { data } = await supabase
      .from('transactions')
      .select('*')
      .order('transaction_date', { ascending: false })
      .limit(2000)
    setTransactions((data as Transaction[]) ?? [])
    setLoading(false)
  }

  return (
    <div className="dashboard">
      <header className="dash-header">
        <h1>HESOYAM</h1>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <button className="theme-toggle" onClick={() => setDark(d => !d)} title="Toggle theme">
            {dark ? '☀️' : '🌙'}
          </button>
          <button className="btn-link" onClick={() => supabase.auth.signOut()}>Sign out</button>
        </div>
      </header>

      <nav className="tabs-nav">
        {(['overview', 'analytics', 'transactions'] as Tab[]).map(t => (
          <button
            key={t}
            className={`tab-btn${tab === t ? ' active' : ''}`}
            onClick={() => setTab(t)}
          >
            {t[0].toUpperCase() + t.slice(1)}
          </button>
        ))}
      </nav>

      {loading ? (
        <div className="center-loader">Loading transactions…</div>
      ) : (
        <>
          {tab === 'overview'     && <Overview     transactions={transactions} />}
          {tab === 'analytics'    && <Analytics    transactions={transactions} />}
          {tab === 'transactions' && <Transactions transactions={transactions} />}
        </>
      )}
    </div>
  )
}
