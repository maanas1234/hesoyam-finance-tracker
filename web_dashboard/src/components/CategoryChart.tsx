import {
  BarChart, Bar, XAxis, YAxis, Tooltip,
  ResponsiveContainer, Cell,
} from 'recharts'
import { colorFor } from '../lib/categories'

interface Props {
  data: { category: string; total: number }[]
}

export default function CategoryChart({ data }: Props) {
  if (data.length === 0) return null

  const fmt = (v: number) =>
    new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(v)

  return (
    <div className="card">
      <h2>Spend by Category</h2>
      <ResponsiveContainer width="100%" height={260}>
        <BarChart data={data} margin={{ top: 8, right: 16, left: 8, bottom: 60 }}>
          <XAxis
            dataKey="category"
            tick={{ fontSize: 12 }}
            angle={-40}
            textAnchor="end"
            interval={0}
          />
          <YAxis tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 12 }} />
          <Tooltip formatter={(v) => [fmt(Number(v)), 'Spent']} />
          <Bar dataKey="total" radius={[4, 4, 0, 0]}>
            {data.map(entry => (
              <Cell key={entry.category} fill={colorFor(entry.category)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
