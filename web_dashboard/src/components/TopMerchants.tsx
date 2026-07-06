import { useState, useMemo } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
} from 'recharts'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

const COLORS = ['#5C6BC0', '#7E57C2', '#42A5F5', '#26A69A', '#66BB6A', '#FFA726', '#EF5350', '#AB47BC', '#26C6DA', '#D4E157']

interface Props {
  data: { name: string; total: number }[]
  onSelect?: (name: string) => void
}

export default function TopMerchants({ data, onSelect }: Props) {
  const [sort, setSort] = useState('amount-desc')

  const sorted = useMemo(() => {
    const list = [...data]
    const [by, dir] = sort.split('-')
    list.sort((a, b) => {
      const cmp = by === 'name' ? a.name.localeCompare(b.name) : a.total - b.total
      return dir === 'asc' ? cmp : -cmp
    })
    return list
  }, [data, sort])

  if (data.length === 0) return (
    <div className="card"><h2>Top Merchants</h2><p className="empty">No merchant data.</p></div>
  )

  return (
    <div className="card">
      <div className="card-header">
        <h2>Top Merchants</h2>
        <select className="sort-select" value={sort} onChange={e => setSort(e.target.value)}>
          <option value="amount-desc">Amount ↓</option>
          <option value="amount-asc">Amount ↑</option>
          <option value="name-asc">Name A→Z</option>
          <option value="name-desc">Name Z→A</option>
        </select>
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart
          data={sorted}
          layout="vertical"
          margin={{ top: 4, right: 60, left: 8, bottom: 4 }}
        >
          <XAxis type="number" tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 11 }} />
          <YAxis type="category" dataKey="name" width={110} tick={{ fontSize: 11 }} />
          <Tooltip formatter={v => [rupee.format(Number(v)), 'Total']} />
          <Bar dataKey="total" radius={[0, 4, 4, 0]} cursor={onSelect ? 'pointer' : undefined}
            onClick={onSelect ? (d: any) => d?.name && onSelect(d.name) : undefined}>
            {data.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
