import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show themeNotifier, toggleTheme;
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../services/supabase_service.dart';
import 'add_transaction_sheet.dart';

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _dateF = DateFormat('dd MMM, hh:mm a');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _txns = [];
  Map<String, double> _cats = {};
  double _spent = 0;
  double _received = 0;
  bool _loading = true;
  String? _syncMsg;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final granted = await SmsService.requestPermission();
    if (granted) {
      final n = await SmsService.sync();
      if (n > 0 && mounted) {
        setState(() => _syncMsg = 'Synced $n new transaction${n == 1 ? '' : 's'}');
      }
    }
    await _load();
  }

  Future<void> _refresh() async {
    setState(() => _syncMsg = null);
    final n = await SmsService.sync();
    if (mounted && n > 0) {
      setState(() => _syncMsg = 'Synced $n new transaction${n == 1 ? '' : 's'}');
    }
    await _load();
  }

  void _prevMonth() {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    _load();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year && _selectedMonth.month == now.month) return;
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    _load();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    final txns = await SupabaseService.getTransactions(from: monthStart, to: monthEnd);

    double spent = 0;
    double received = 0;
    final cats = <String, double>{};

    for (final t in txns) {
      if (t.type == 'debit') {
        spent += t.amount;
        cats[t.category] = (cats[t.category] ?? 0) + t.amount;
      } else {
        received += t.amount;
      }
    }

    if (mounted) {
      setState(() {
        _txns = txns;
        _spent = spent;
        _received = received;
        _cats = Map.fromEntries(
          cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
        );
        _loading = false;
      });
      _pushWidget(
        spent, txns.where((t) => t.type == 'debit').length,
        received, txns.where((t) => t.type == 'credit').length,
      );
    }
  }

  static const _widgetChannel = MethodChannel('finance_widget');

  Future<void> _pushWidget(double spent, int spentCount, double received, int receivedCount) async {
    try {
      await _widgetChannel.invokeMethod('update', {
        'spent':           spent.toStringAsFixed(0),
        'count':           spentCount.toString(),
        'received':        received.toStringAsFixed(0),
        'received_count':  receivedCount.toString(),
        'month':           DateFormat('MMM yyyy').format(_selectedMonth),
      });
    } catch (_) {}
  }

  Future<void> _openAddSheet() async {
    final added = await showAddTransactionSheet(context);
    if (added) _load();
  }

  Future<void> _deleteTxn(Transaction txn) async {
    if (txn.id == null) return;
    // Optimistically remove from list first
    setState(() => _txns.remove(txn));
    try {
      await SupabaseService.deleteTransaction(txn.id!);
    } catch (_) {
      // Restore on failure
      if (mounted) {
        setState(() => _txns.insert(0, txn));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed. Try again.')),
        );
        return;
      }
    }
    // Reload to get updated totals and widget
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HESOYAM'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) => IconButton(
              icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
              tooltip: 'Toggle theme',
              onPressed: toggleTheme,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Month navigator
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                    splashRadius: 20,
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right,
                        color: _isCurrentMonth ? Colors.grey.shade300 : null),
                    onPressed: _isCurrentMonth ? null : _nextMonth,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        if (_syncMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _syncMsg!,
                              style: TextStyle(color: Colors.green[700]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _SummaryCards(spent: _spent, received: _received),
                        const SizedBox(height: 20),
                        if (_cats.isNotEmpty) ...[
                          _SectionHeader('Spending by Category'),
                          const SizedBox(height: 8),
                          _CategoryBars(cats: _cats, total: _spent),
                          const SizedBox(height: 20),
                        ],
                        _SectionHeader('Transactions'),
                        const SizedBox(height: 8),
                        if (_txns.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No transactions this month.\nPull down to sync SMS.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ..._txns.map((t) => _TxnTile(
                            txn: t,
                            onDelete: () => _deleteTxn(t),
                          )),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final double spent;
  final double received;
  const _SummaryCards({required this.spent, required this.received});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _Card(
            label: 'Spent',
            value: _rupee.format(spent),
            color: cs.errorContainer,
            textColor: cs.onErrorContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Card(
            label: 'Received',
            value: _rupee.format(received),
            color: cs.primaryContainer,
            textColor: cs.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  const _Card({required this.label, required this.value, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3),
    );
  }
}

class _CategoryBars extends StatelessWidget {
  final Map<String, double> cats;
  final double total;
  const _CategoryBars({required this.cats, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: cats.entries.map((e) {
        final pct = total > 0 ? e.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(fontSize: 13)),
                  Text(_rupee.format(e.value), style: const TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: cs.surfaceVariant,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Transaction txn;
  final VoidCallback onDelete;
  const _TxnTile({required this.txn, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.type == 'debit';
    return Dismissible(
      key: ValueKey(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text('Remove ${txn.merchant ?? txn.bank ?? 'this transaction'} for ${_rupee.format(txn.amount)}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isDebit ? Colors.red.shade50 : Colors.green.shade50,
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isDebit ? Colors.red : Colors.green,
            ),
          ),
          title: Text(
            txn.merchant ?? txn.bank ?? 'Unknown',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${txn.category}  ·  ${_dateF.format(txn.transactionDate.toLocal())}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            '${isDebit ? '-' : '+'}${_rupee.format(txn.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDebit ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ),
      ),
    );
  }
}
