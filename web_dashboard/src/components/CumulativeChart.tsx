import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'

const rupee = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 })

interface Props {
  data: { month: string; total: number }[]
}

export default function CumulativeChart({ data }: Props) {
  return (
    <div className="card">
      <h2>Cumulative Spend</h2>
      <ResponsiveContainer width="100%" height={220}>
        <AreaChart data={data} margin={{ top: 8, right: 16, left: 8, bottom: 0 }}>
          <defs>
            <linearGradient id="cumGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#5C6BC0" stopOpacity={0.2} />
              <stop offset="95%" stopColor="#5C6BC0" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis dataKey="month" tick={{ fontSize: 11 }} />
          <YAxis tickFormatter={v => `₹${(v / 1000).toFixed(0)}k`} tick={{ fontSize: 11 }} />
          <Tooltip formatter={v => [rupee.format(Number(v)), 'Total Spent']} />
          <Area
            type="monotone"
            dataKey="total"
            stroke="#5C6BC0"
            strokeWidth={2}
            fill="url(#cumGrad)"
            dot={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
