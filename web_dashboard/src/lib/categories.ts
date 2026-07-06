export const CATEGORY_COLORS: Record<string, string> = {
  'Food & Dining': '#f97316',
  Groceries: '#22c55e',
  Transport: '#3b82f6',
  Shopping: '#a855f7',
  Entertainment: '#ec4899',
  Healthcare: '#14b8a6',
  Utilities: '#64748b',
  Recharge: '#0ea5e9',
  Finance: '#ef4444',
  Education: '#eab308',
  Other: '#9ca3af',
}

export function colorFor(category: string): string {
  return CATEGORY_COLORS[category] ?? '#9ca3af'
}
