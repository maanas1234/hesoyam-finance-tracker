class Categorizer {
  static const _rules = <String, List<String>>{
    'Food & Dining': [
      'swiggy', 'zomato', 'zoma', 'mcdonald', 'kfc', 'burger king', 'domino',
      'pizza', 'restaurant', 'cafe', 'chaayos', 'starbucks', 'barbeque',
      'dhaba', 'haldiram', 'bikaner', 'wow momo', 'faasos', 'box8',
    ],
    'Groceries': [
      'bigbasket', 'blinkit', 'zepto', 'grofers', 'dunzo', 'jiomart',
      'dmart', 'reliance fresh', 'more hypermarket', 'grocery', 'kirana',
      'supermarket', 'nature basket',
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'metro', 'irctc', 'indigo', 'spicejet',
      'air india', 'vistara', 'airindia', 'petrol', 'fuel',
      'hp petro', 'indian oil', 'bharat petroleum', 'iocl', 'hpcl', 'bpcl',
      'namma metro', 'bmtc', 'best bus', 'dtc',
    ],
    'Shopping': [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa',
      'tatacliq', 'snapdeal', 'pepperfry', 'ikea', 'h&m', 'zara',
      'godaddy', 'namecheap', 'hostinger',
    ],
    'Entertainment': [
      'netflix', 'hotstar', 'primevideo', 'prime video', 'spotify',
      'gaana', 'jiosaavn', 'wynk', 'bookmyshow', 'pvr', 'inox',
      'cinepolis', 'theatre', 'movie',
    ],
    'Healthcare': [
      'apollo', 'medplus', 'netmeds', '1mg', 'pharmeasy', 'practo',
      'lybrate', 'pharmacy', 'hospital', 'clinic', 'diagnostic', 'lab',
    ],
    'Utilities': [
      'jio', 'airtel', 'vi ', 'vi c', 'vodafone', 'bsnl', 'electricity',
      'water bill', 'gas bill', 'broadband', 'tata sky', 'dish tv',
      'sun direct', 'act fibernet', 'hathway', 'tata power', 'adani',
      'google cloud', 'google one', 'google storage',
    ],
    'Recharge': [
      'recharge', 'topup', 'top up', 'prepaid', 'postpaid', 'mobile bill',
    ],
    'Finance': [
      'emi', 'loan repay', 'insurance', 'sip', 'mutual fund',
      'credit card bill', 'credit card payment', 'lumpsum',
    ],
    'Education': [
      'coursera', 'udemy', 'unacademy', 'byju', 'vedantu',
      'physicswallah', 'pw app', 'school fee', 'college fee', 'tuition',
    ],
  };

  static String categorize(String? merchant) {
    if (merchant == null || merchant.isEmpty) return 'Other';
    final lower = merchant.toLowerCase();
    for (final entry in _rules.entries) {
      if (entry.value.any(lower.contains)) return entry.key;
    }
    return 'Other';
  }
}
