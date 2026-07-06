import { useMemo, useState } from 'react'
import { format, subMonths, parseISO, startOfMonth, endOfMonth } from 'date-fns'
import type { Transaction } from '../types'
import MonthlyTrend from '../components/MonthlyTrend'
import CumulativeChart from '../components/CumulativeChart'
import TopMerchants from '../components/TopMerchants'
import CategoryPie from '../components/CategoryPie'
import CategoryChart from '../components/CategoryChart'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

export default function Analytics({ transactions }: { transactions: Transaction[] }) {
  const [monthFilter, setMonthFilter] = useState<string>('all')

  // Build dropdown options from actual transaction dates
  const monthOptions = useMemo(() => {
    const seen = new Set<string>()
    transactions.forEach(t => seen.add(format(parseISO(t.transaction_date), 'yyyy-MM')))
    return Array.from(seen)
      .sort((a, b) => b.localeCompare(a))
      .map(key => ({
        value: key,
        label: format(new Date(key + '-01'), 'MMMM yyyy'),
      }))
  }, [transactions])

  // Filter transactions by selected month (or keep all)
  const filtered = useMemo(() => {
    if (monthFilter === 'all') return transactions
    const ref = new Date(monthFilter + '-01')
    const from = startOfMonth(ref).getTime()
    const to   = endOfMonth(ref).getTime()
    return transactions.filter(t => {
      const d = parseISO(t.transaction_date).getTime()
      return d >= from && d <= to
    })
  }, [transactions, monthFilter])

  const debits  = filtered.filter(t => t.type === 'debit')
  const credits = filtered.filter(t => t.type === 'credit')

  const isAllTime = monthFilter === 'all'

  // All-time 12-month trend data (always unfiltered)
  const now = new Date()
  const monthLabels = Array.from({ length: 12 }, (_, i) =>
    format(subMonths(now, 11 - i), 'MMM yy')
  )
  const monthlyData = useMemo(() => {
    const allDebits = transactions.filter(t => t.type === 'debit')
    const map: Record<string, number> = {}
    allDebits.forEach(t => {
      const key = format(parseISO(t.transaction_date), 'MMM yy')
      map[key] = (map[key] ?? 0) + t.amount
    })
    return monthLabels.map(m => ({ month: m, total: map[m] ?? 0 }))
  }, [transactions])

  const cumulativeData = useMemo(() => {
    let cum = 0
    return monthlyData.map(d => ({ month: d.month, total: (cum += d.total) }))
  }, [monthlyData])

  const topMerchants = useMemo(() => {
    const map: Record<string, number> = {}
    debits.forEach(t => {
      if (t.merchant) map[t.merchant] = (map[t.merchant] ?? 0) + t.amount
    })
    return Object.entries(map)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([name, total]) => ({ name, total }))
  }, [debits])

  const categoryData = useMemo(() => {
    const map: Record<string, number> = {}
    debits.forEach(t => { map[t.category] = (map[t.category] ?? 0) + t.amount })
    return Object.entries(map)
      .sort((a, b) => b[1] - a[1])
      .map(([name, value]) => ({ name, value }))
  }, [debits])

  // For CategoryChart (used in month view)
  const categoryBarData = categoryData.map(d => ({ category: d.name, total: d.value }))

  const totalSpent    = debits.reduce((s, t) => s + t.amount, 0)
  const totalReceived = credits.reduce((s, t) => s + t.amount, 0)

  return (
    <div>
      {/* Month selector */}
      <div className="analytics-header">
        <span className="analytics-title">
          {isAllTime ? 'All Time' : monthOptions.find(m => m.value === monthFilter)?.label}
        </span>
        <select
          className="filter-select"
          value={monthFilter}
          onChange={e => setMonthFilter(e.target.value)}
        >
          <option value="all">All Time</option>
          {monthOptions.map(m => (
            <option key={m.value} value={m.value}>{m.label}</option>
          ))}
        </select>
      </div>

      {/* Summary cards */}
      <div className="stats-row" style={{ marginBottom: 20 }}>
        <div className="stat-card stat-spent">
          <span className="stat-label">{isAllTime ? 'Total Spent' : 'Spent'}</span>
          <span className="stat-value">{rupee.format(totalSpent)}</span>
          <span className="stat-sub">{debits.length} transactions</span>
        </div>
        <div className="stat-card stat-received">
          <span className="stat-label">{isAllTime ? 'Total Received' : 'Received'}</span>
          <span className="stat-value">{rupee.format(totalReceived)}</span>
          <span className="stat-sub">{credits.length} transactions</span>
        </div>
        <div className="stat-card">
          <span className="stat-label">{isAllTime ? 'Avg Monthly Spend' : 'Net'}</span>
          <span className={`stat-value ${!isAllTime ? (totalReceived - totalSpent >= 0 ? 'positive' : 'negative') : ''}`}>
            {isAllTime ? rupee.format(totalSpent / 12) : rupee.format(totalReceived - totalSpent)}
          </span>
          <span className="stat-sub">{isAllTime ? 'last 12 months' : 'this month'}</span>
        </div>
      </div>

      {/* All-time only: trend + cumulative */}
      {isAllTime && (
        <>
          <MonthlyTrend data={monthlyData} />
          <CumulativeChart data={cumulativeData} />
        </>
      )}

      {/* Month view: category bar chart instead of pie */}
      {isAllTime ? (
        <div className="two-col">
          <TopMerchants data={topMerchants} />
          <CategoryPie data={categoryData} />
        </div>
      ) : (
        <>
          <CategoryChart data={categoryBarData} />
          <TopMerchants data={topMerchants} />
        </>
      )}
    </div>
  )
}
