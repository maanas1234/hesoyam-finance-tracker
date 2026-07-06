export interface Transaction {
  id: string
  user_id: string
  amount: number
  type: 'debit' | 'credit'
  merchant: string | null
  category: string
  bank: string | null
  raw_sms: string | null
  transaction_date: string
  created_at: string
}
