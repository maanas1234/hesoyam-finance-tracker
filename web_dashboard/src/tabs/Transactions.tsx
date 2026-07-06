import { useState, useMemo } from 'react'
import { format, parseISO } from 'date-fns'
import type { Transaction } from '../types'
import { colorFor } from '../lib/categories'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })
const PAGE = 25

export default function Transactions({ transactions }: { transactions: Transaction[] }) {
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState('All')
  const [type, setType] = useState('all')
  const [page, setPage] = useState(0)

  const categories = useMemo(() => {
    const set = new Set(transactions.map(t => t.category))
    return ['All', ...Array.from(set).sort()]
  }, [transactions])

  const filtered = useMemo(() => {
    const q = search.toLowerCase()
    return transactions.filter(t => {
      if (type !== 'all' && t.type !== type) return false
      if (category !== 'All' && t.category !== category) return false
      if (q && !(t.merchant ?? '').toLowerCase().includes(q) && !(t.bank ?? '').toLowerCase().includes(q)) return false
      return true
    })
  }, [transactions, search, category, type])

  const totalPages = Math.ceil(filtered.length / PAGE)
  const paged = filtered.slice(page * PAGE, (page + 1) * PAGE)

  function onSearch(v: string) { setSearch(v); setPage(0) }
  function onCategory(v: string) { setCategory(v); setPage(0) }
  function onType(v: string) { setType(v); setPage(0) }

  return (
    <div>
      {/* Filters */}
      <div className="filter-row">
        <input
          className="filter-search"
          placeholder="Search merchant…"
          value={search}
          onChange={e => onSearch(e.target.value)}
        />
        <select className="filter-select" value={category} onChange={e => onCategory(e.target.value)}>
          {categories.map(c => <option key={c}>{c}</option>)}
        </select>
        <select className="filter-select" value={type} onChange={e => onType(e.target.value)}>
          <option value="all">All types</option>
          <option value="debit">Debit</option>
          <option value="credit">Credit</option>
        </select>
        <span className="filter-count">{filtered.length} transactions</span>
      </div>

      {/* Table */}
      <div className="card">
        {paged.length === 0 ? (
          <p className="empty">No transactions match your filters.</p>
        ) : (
          <div className="txn-table-wrap">
            <table className="txn-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Merchant</th>
                  <th>Category</th>
                  <th>Bank</th>
                  <th>Amount</th>
                </tr>
              </thead>
              <tbody>
                {paged.map(t => (
                  <tr key={t.id}>
                    <td className="mono">{format(parseISO(t.transaction_date), 'dd MMM yy, h:mm a')}</td>
                    <td>{t.merchant ?? '—'}</td>
                    <td>
                      <span className="badge" style={{ background: colorFor(t.category) + '22', color: colorFor(t.category) }}>
                        {t.category}
                      </span>
                    </td>
                    <td>{t.bank ?? '—'}</td>
                    <td className={`amount ${t.type}`}>
                      {t.type === 'debit' ? '−' : '+'}{rupee.format(t.amount)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="pagination">
          <button disabled={page === 0} onClick={() => setPage(0)}>«</button>
          <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>‹</button>
          <span>{page + 1} / {totalPages}</span>
          <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)}>›</button>
          <button disabled={page >= totalPages - 1} onClick={() => setPage(totalPages - 1)}>»</button>
        </div>
      )}
    </div>
  )
}
