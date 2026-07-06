class ParsedSms {
  final double amount;
  final String type; // 'debit' | 'credit'
  final String? merchant;
  final String? bank;

  const ParsedSms({
    required this.amount,
    required this.type,
    this.merchant,
    this.bank,
  });
}

class SmsParser {
  static final _amountRe = RegExp(
    r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );
  static final _debitRe = RegExp(
    r'\b(?:debited|debit|spent|withdrawn|purchase)\b',
    caseSensitive: false,
  );
  static final _creditRe = RegExp(
    r'\b(?:credited|credit|received|refund|reversal)\b',
    caseSensitive: false,
  );

  static bool isTransactionSms(String sender, String body) {
    return _amountRe.hasMatch(body) &&
        (_debitRe.hasMatch(body) || _creditRe.hasMatch(body));
  }

  static ParsedSms? parse(String body) {
    final amountMatch = _amountRe.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) return null;

    final isDebit = _debitRe.hasMatch(body);
    final isCredit = _creditRe.hasMatch(body);
    if (!isDebit && !isCredit) return null;

    return ParsedSms(
      amount: amount,
      type: isDebit ? 'debit' : 'credit',
      merchant: _extractMerchant(body),
      bank: _detectBank(body),
    );
  }

  static String? _extractMerchant(String body) {
    // ── ICICI UPI format ────────────────────────────────────────────────────
    // "ICICI Bank Acct XX789 debited for Rs X on DATE; MERCHANT credited. UPI:REF"
    // Merchant name sits between "; " and " credited."
    final iciciUpi = RegExp(r';\s*([^;]{1,50}?)\s+credited\.', caseSensitive: false);
    var m = iciciUpi.firstMatch(body);
    if (m != null) {
      final name = m.group(1)!.trim();
      if (name.isNotEmpty && !RegExp(r'^\d+$').hasMatch(name)) {
        return _clean(name);
      }
    }

    // ── ICICI / HDFC AutoPay mandate ────────────────────────────────────────
    // "towards Autopay for Spotify India, MERCHANTMANDATE"
    // "towards Spotify India L for MERCHANTMANDATE"
    final autopay = RegExp(
      r'towards\s+(?:Autopay\s+for\s+)?(.+?)\s*(?:,\s*MERCHANTMANDATE|for\s+MERCHANTMANDATE)',
      caseSensitive: false,
    );
    m = autopay.firstMatch(body);
    if (m != null) return _clean(m.group(1)!.trim());

    // ── NEFT / IMPS credit ──────────────────────────────────────────────────
    // "Info NEFT-HSBCN18161-GENPAC"  → source is after last "-"
    final neft = RegExp(r'\bNEFT-[A-Z0-9]+-([A-Z][A-Z0-9 ]+)', caseSensitive: false);
    m = neft.firstMatch(body);
    if (m != null) return _clean(m.group(1)!);

    // ── Generic UPI VPA (HDFC, Axis, Kotak, SBI) ───────────────────────────
    // "Info: UPI/zomatopay@icici/desc/ref"  or  "Info: UPI/9876543210@okaxis/..."
    final upiVpa = RegExp(r'Info:\s*UPI[/ ]([^/\s,]+)', caseSensitive: false);
    m = upiVpa.firstMatch(body);
    if (m != null) {
      return _merchantFromVpa(m.group(1)!, body);
    }

    // ── "trf to MERCHANT via" (Paytm / some SBI) ───────────────────────────
    final trf = RegExp(r'trf\s+to\s+([A-Za-z][A-Za-z0-9 ]{1,30}?)\s+via', caseSensitive: false);
    m = trf.firstMatch(body);
    if (m != null) return _clean(m.group(1)!);

    // ── "at MERCHANT on/for" ────────────────────────────────────────────────
    final at = RegExp(
      r'\bat\s+([A-Za-z][A-Za-z0-9 &]{2,30}?)\s+(?:on|for|via)\b',
      caseSensitive: false,
    );
    m = at.firstMatch(body);
    if (m != null) return _clean(m.group(1)!);

    return null;
  }

  // Converts a UPI VPA like "zomatopay@icici" into a merchant name.
  static String? _merchantFromVpa(String vpa, String body) {
    final handle = vpa.split('@').first.toLowerCase();

    // Phone-number VPA = person-to-person; try description field for context.
    if (RegExp(r'^\d{10,}$').hasMatch(handle)) {
      final descRe = RegExp(
        r'Info:\s*UPI[/ ][^/]+/([A-Za-z][^/\d,]{2,40}?)(?:/|$)',
        caseSensitive: false,
      );
      final dm = descRe.firstMatch(body);
      if (dm != null) return _clean(dm.group(1)!.trim());
      return null;
    }

    // Strip noisy VPA suffixes: "zomatopay" → "zomato", "swiggy.b2b" → "swiggy"
    String clean = handle
        .replaceAll(RegExp(r'\.(b2b|pay|pg|online)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'(pay|pg|gv|online)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_.]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (clean.isEmpty) clean = handle;
    return clean.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  }

  static String _clean(String raw) {
    return raw
        .replaceAll(RegExp(r'[-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  static String? _detectBank(String body) {
    final u = body.toUpperCase();
    if (u.contains('HDFC')) return 'HDFC';
    if (u.contains('ICICI')) return 'ICICI';
    if (u.contains('STATE BANK') || u.contains('SBI')) return 'SBI';
    if (u.contains('AXIS')) return 'Axis';
    if (u.contains('KOTAK')) return 'Kotak';
    if (u.contains('PAYTM')) return 'Paytm';
    if (u.contains('YES BANK') || u.contains('YESBANK')) return 'Yes Bank';
    if (u.contains('PNB') || u.contains('PUNJAB NATIONAL')) return 'PNB';
    if (u.contains('CANARA')) return 'Canara';
    if (u.contains('INDUSIND')) return 'IndusInd';
    if (u.contains('IDBI')) return 'IDBI';
    if (u.contains('FEDERAL')) return 'Federal';
    if (u.contains('RBL')) return 'RBL';
    return null;
  }
}
