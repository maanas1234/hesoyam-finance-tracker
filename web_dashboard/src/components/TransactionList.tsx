import { format } from 'date-fns'
import type { Transaction } from '../types'
import { colorFor } from '../lib/categories'

interface Props {
  transactions: Transaction[]
}

const rupee = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  maximumFractionDigits: 0,
})

export default function TransactionList({ transactions }: Props) {
  return (
    <div className="card">
      <h2>Recent Transactions</h2>
      {transactions.length === 0 ? (
        <p className="empty">No transactions this month.</p>
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
              {transactions.map(t => (
                <tr key={t.id}>
                  <td className="mono">
                    {format(new Date(t.transaction_date), 'dd MMM, h:mm a')}
                  </td>
                  <td>{t.merchant ?? '—'}</td>
                  <td>
                    <span
                      className="badge"
                      style={{ background: colorFor(t.category) + '22', color: colorFor(t.category) }}
                    >
                      {t.category}
                    </span>
                  </td>
                  <td>{t.bank ?? '—'}</td>
                  <td
                    className={`amount ${t.type === 'debit' ? 'debit' : 'credit'}`}
                  >
                    {t.type === 'debit' ? '−' : '+'}{rupee.format(t.amount)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
