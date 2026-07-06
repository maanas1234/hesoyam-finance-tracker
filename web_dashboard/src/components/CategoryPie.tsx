import { useState, useMemo } from 'react'
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import { colorFor } from '../lib/categories'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

interface Props {
  data: { name: string; value: number }[]
  onSelect?: (name: string) => void
}

export default function CategoryPie({ data, onSelect }: Props) {
  const [sort, setSort] = useState('amount-desc')

  const sorted = useMemo(() => {
    const list = [...data]
    const [by, dir] = sort.split('-')
    list.sort((a, b) => {
      const cmp = by === 'name' ? a.name.localeCompare(b.name) : a.value - b.value
      return dir === 'asc' ? cmp : -cmp
    })
    return list
  }, [data, sort])

  if (data.length === 0) return (
    <div className="card"><h2>By Category</h2><p className="empty">No data.</p></div>
  )

  const total = sorted.reduce((s, d) => s + d.value, 0)

  return (
    <div className="card">
      <div className="card-header">
        <h2>By Category</h2>
        <select className="sort-select" value={sort} onChange={e => setSort(e.target.value)}>
          <option value="amount-desc">Amount ↓</option>
          <option value="amount-asc">Amount ↑</option>
          <option value="name-asc">Name A→Z</option>
          <option value="name-desc">Name Z→A</option>
        </select>
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={sorted}
            dataKey="value"
            nameKey="name"
            cx="50%"
            cy="45%"
            outerRadius={90}
            innerRadius={52}
            paddingAngle={2}
            label={({ value }) => `${((value / total) * 100).toFixed(0)}%`}
            labelLine={false}
            cursor={onSelect ? 'pointer' : undefined}
            onClick={onSelect ? (d: any) => d?.name && onSelect(d.name) : undefined}
          >
            {sorted.map(d => <Cell key={d.name} fill={colorFor(d.name)} />)}
          </Pie>
          <Tooltip formatter={v => [rupee.format(Number(v)), '']} />
          <Legend iconType="circle" iconSize={8} wrapperStyle={{ fontSize: 12 }} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  )
}
