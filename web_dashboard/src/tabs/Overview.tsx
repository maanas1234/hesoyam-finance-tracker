import { useState } from 'react'
import { format, subMonths, addMonths, parseISO, isSameMonth } from 'date-fns'
import type { Transaction } from '../types'
import CategoryChart from '../components/CategoryChart'
import TransactionList from '../components/TransactionList'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

export default function Overview({ transactions }: { transactions: Transaction[] }) {
  const [month, setMonth] = useState(new Date())

  const isCurrentMonth = isSameMonth(month, new Date())

  const monthTxns = transactions.filter(t =>
    isSameMonth(parseISO(t.transaction_date), month)
  )
  const debits  = monthTxns.filter(t => t.type === 'debit')
  const credits = monthTxns.filter(t => t.type === 'credit')
  const spent    = debits.reduce((s, t) => s + t.amount, 0)
  const received = credits.reduce((s, t) => s + t.amount, 0)

  const categoryTotals = Object.entries(
    debits.reduce<Record<string, number>>((acc, t) => {
      acc[t.category] = (acc[t.category] ?? 0) + t.amount
      return acc
    }, {})
  )
    .map(([category, total]) => ({ category, total }))
    .sort((a, b) => b.total - a.total)

  return (
    <div>
      {/* Month navigator */}
      <div className="month-nav">
        <button className="month-arrow" onClick={() => setMonth(m => subMonths(m, 1))}>‹</button>
        <span className="month-label">{format(month, 'MMMM yyyy')}</span>
        <button
          className="month-arrow"
          onClick={() => setMonth(m => addMonths(m, 1))}
          disabled={isCurrentMonth}
        >›</button>
      </div>

      {/* Stats */}
      <div className="stats-row">
        <div className="stat-card stat-spent">
          <span className="stat-label">Spent</span>
          <span className="stat-value">{rupee.format(spent)}</span>
          <span className="stat-sub">{debits.length} transactions</span>
        </div>
        <div className="stat-card stat-received">
          <span className="stat-label">Received</span>
          <span className="stat-value">{rupee.format(received)}</span>
          <span className="stat-sub">{credits.length} transactions</span>
        </div>
        <div className="stat-card stat-net">
          <span className="stat-label">Net</span>
          <span className={`stat-value ${received - spent >= 0 ? 'positive' : 'negative'}`}>
            {rupee.format(received - spent)}
          </span>
          <span className="stat-sub">this month</span>
        </div>
      </div>

      <CategoryChart data={categoryTotals} />
      <TransactionList transactions={monthTxns} />
    </div>
  )
}
