import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
} from 'recharts'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

interface Props {
  data: { month: string; total: number }[]
}

export default function MonthlyTrend({ data }: Props) {
  const max = Math.max(...data.map(d => d.total))

  return (
    <div className="card">
      <h2>Monthly Spend — Last 12 Months</h2>
      <ResponsiveContainer width="100%" height={260}>
        <BarChart data={data} margin={{ top: 8, right: 16, left: 8, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis dataKey="month" tick={{ fontSize: 11 }} />
          <YAxis tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 11 }} />
          <Tooltip formatter={v => [rupee.format(Number(v)), 'Spent']} />
          <Bar dataKey="total" radius={[4, 4, 0, 0]}>
            {data.map(d => (
              <Cell key={d.month} fill={d.total === max ? '#5C6BC0' : '#9FA8DA'} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
