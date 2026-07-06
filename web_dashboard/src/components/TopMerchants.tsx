import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
} from 'recharts'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

const COLORS = ['#5C6BC0', '#7E57C2', '#42A5F5', '#26A69A', '#66BB6A', '#FFA726', '#EF5350', '#AB47BC', '#26C6DA', '#D4E157']

interface Props {
  data: { name: string; total: number }[]
}

export default function TopMerchants({ data }: Props) {
  if (data.length === 0) return (
    <div className="card"><h2>Top Merchants</h2><p className="empty">No merchant data.</p></div>
  )

  return (
    <div className="card">
      <h2>Top Merchants (All Time)</h2>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart
          data={data}
          layout="vertical"
          margin={{ top: 4, right: 60, left: 8, bottom: 4 }}
        >
          <XAxis type="number" tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 11 }} />
          <YAxis type="category" dataKey="name" width={110} tick={{ fontSize: 11 }} />
          <Tooltip formatter={v => [rupee.format(Number(v)), 'Total']} />
          <Bar dataKey="total" radius={[0, 4, 4, 0]}>
            {data.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
