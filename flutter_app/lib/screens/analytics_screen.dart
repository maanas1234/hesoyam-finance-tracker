import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/supabase_service.dart';

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _monthFmt = DateFormat('MMM yy');
final _monthKeyFmt = DateFormat('yyyy-MM');
final _monthLabelFmt = DateFormat('MMMM yyyy');
final _dateFmt = DateFormat('dd MMM, hh:mm a');

enum _ASort { amountDesc, amountAsc, nameAsc, nameDesc }

const _categoryColors = <String, Color>{
  'Food & Dining': Color(0xFFF97316),
  'Groceries':     Color(0xFF22C55E),
  'Transport':     Color(0xFF3B82F6),
  'Shopping':      Color(0xFFA855F7),
  'Entertainment': Color(0xFFEC4899),
  'Healthcare':    Color(0xFF14B8A6),
  'Utilities':     Color(0xFF64748B),
  'Recharge':      Color(0xFF0EA5E9),
  'Finance':       Color(0xFFEF4444),
  'Education':     Color(0xFFEAB308),
  'Other':         Color(0xFF9CA3AF),
};
Color _colorFor(String cat) => _categoryColors[cat] ?? const Color(0xFF9CA3AF);

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Transaction> _all = [];
  bool _loading = true;
  String? _selectedMonthKey; // null = all time, 'yyyy-MM' = specific month

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txns = await SupabaseService.getAllForAnalytics();
    if (mounted) setState(() { _all = txns; _loading = false; });
  }

  List<String> get _monthKeys {
    final months = <String>{};
    for (final t in _all) months.add(_monthKeyFmt.format(t.transactionDate));
    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  List<Transaction> get _filtered {
    if (_selectedMonthKey == null) return _all;
    return _all.where((t) => _monthKeyFmt.format(t.transactionDate) == _selectedMonthKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _AnalyticsBody(
                all: _all,
                filtered: _filtered,
                isAllTime: _selectedMonthKey == null,
                monthKeys: _monthKeys,
                selectedMonthKey: _selectedMonthKey,
                onMonthChanged: (k) => setState(() => _selectedMonthKey = k),
              ),
            ),
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  final List<Transaction> all;
  final List<Transaction> filtered;
  final bool isAllTime;
  final List<String> monthKeys;
  final String? selectedMonthKey;
  final ValueChanged<String?> onMonthChanged;

  const _AnalyticsBody({
    required this.all,
    required this.filtered,
    required this.isAllTime,
    required this.monthKeys,
    required this.selectedMonthKey,
    required this.onMonthChanged,
  });

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  _ASort _merchantSort = _ASort.amountDesc;
  _ASort _catSort = _ASort.amountDesc;

  List<MapEntry<String, double>> _sort(List<MapEntry<String, double>> list, _ASort s) {
    final r = [...list];
    switch (s) {
      case _ASort.amountDesc: r.sort((a, b) => b.value.compareTo(a.value));
      case _ASort.amountAsc:  r.sort((a, b) => a.value.compareTo(b.value));
      case _ASort.nameAsc:    r.sort((a, b) => a.key.compareTo(b.key));
      case _ASort.nameDesc:   r.sort((a, b) => b.key.compareTo(a.key));
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.all;
    final filtered = widget.filtered;
    final isAllTime = widget.isAllTime;
    final debits  = filtered.where((t) => t.type == 'debit').toList();
    final credits = filtered.where((t) => t.type == 'credit').toList();
    final totalSpent    = debits.fold(0.0,  (s, t) => s + t.amount);
    final totalReceived = credits.fold(0.0, (s, t) => s + t.amount);

    final now = DateTime.now();
    final months6 = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return (label: _monthFmt.format(d), date: d);
    });
    final allDebits = all.where((t) => t.type == 'debit').toList();
    final monthlyTotals = months6.map((m) {
      final total = allDebits
          .where((t) => t.transactionDate.year == m.date.year && t.transactionDate.month == m.date.month)
          .fold(0.0, (s, t) => s + t.amount);
      return (label: m.label, total: total);
    }).toList();

    final merchantMap = <String, double>{};
    for (final t in debits) {
      if (t.merchant != null) merchantMap[t.merchant!] = (merchantMap[t.merchant!] ?? 0) + t.amount;
    }
    final top8Merchants = (merchantMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8).toList();
    final topMerchants = _sort(top8Merchants, _merchantSort);

    final catMap = <String, double>{};
    for (final t in debits) catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    final top8Cats = (catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(8).toList();
    final catList = _sort(top8Cats, _catSort);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [

        // ── Month picker ──────────────────────────────────────
        Row(children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: widget.selectedMonthKey,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All Time')),
                  ...widget.monthKeys.map((k) => DropdownMenuItem<String?>(
                    value: k,
                    child: Text(_monthLabelFmt.format(DateTime.parse('$k-01'))),
                  )),
                ],
                onChanged: widget.onMonthChanged,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // ── Summary cards ─────────────────────────────────────
        Row(children: [
          _StatCard('Spent',    _rupee.format(totalSpent),    '${debits.length} txns',
              const Color(0xFFFFEBEE), Colors.red.shade700),
          const SizedBox(width: 10),
          _StatCard('Received', _rupee.format(totalReceived), '${credits.length} txns',
              const Color(0xFFE8F5E9), Colors.green.shade700),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatCard(
            isAllTime ? 'Avg/Month' : 'Net',
            isAllTime ? _rupee.format(totalSpent / 6) : _rupee.format(totalReceived - totalSpent),
            isAllTime ? 'last 6 months' : 'this month',
            const Color(0xFFE8EAF6), const Color(0xFF5C6BC0),
          ),
          const SizedBox(width: 10),
          _StatCard('Transactions', '${filtered.length}', 'total',
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.onSurface),
        ]),
        const SizedBox(height: 20),

        // ── Monthly bar chart (always all-time for context) ───
        if (isAllTime) ...[
          _SectionTitle('Monthly Spend — Last 6 Months'),
          const SizedBox(height: 12),
          _MonthlyChart(monthlyTotals: monthlyTotals),
          const SizedBox(height: 20),
        ],

        // ── Category pie ──────────────────────────────────────
        if (catList.isNotEmpty) ...[
          Row(children: [
            const Expanded(child: _SectionTitle('By Category')),
            _ASortDropdown(value: _catSort, onChanged: (v) => setState(() => _catSort = v!)),
          ]),
          const SizedBox(height: 12),
          _CategoryPie(
            catList: catList,
            totalSpent: totalSpent,
            onCategoryTap: (cat) => _showTxnSheet(
              context, cat,
              debits.where((t) => t.category == cat).toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...catList.map((e) => _HBar(
            label: e.key, value: e.value, max: catList.first.value, color: _colorFor(e.key),
            onTap: () => _showTxnSheet(
              context, e.key,
              debits.where((t) => t.category == e.key).toList(),
            ),
          )),
          const SizedBox(height: 20),
        ],

        // ── Top merchants ─────────────────────────────────────
        if (topMerchants.isNotEmpty) ...[
          Row(children: [
            const Expanded(child: _SectionTitle('Top Merchants')),
            _ASortDropdown(value: _merchantSort, onChanged: (v) => setState(() => _merchantSort = v!)),
          ]),
          const SizedBox(height: 12),
          ...topMerchants.map((e) => _HBar(
            label: e.key, value: e.value,
            max: topMerchants.first.value,
            color: const Color(0xFF5C6BC0),
            onTap: () => _showTxnSheet(
              context, e.key,
              debits.where((t) => t.merchant == e.key).toList(),
            ),
          )),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final Color bg, fg;
  const _StatCard(this.label, this.value, this.sub, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: fg.withOpacity(0.75))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: TextStyle(fontSize: 10, color: fg.withOpacity(0.6))),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));
}

class _MonthlyChart extends StatelessWidget {
  final List<({String label, double total})> monthlyTotals;
  const _MonthlyChart({required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final maxY = monthlyTotals.map((m) => m.total).fold(0.0, (a, b) => a > b ? a : b);
    if (maxY == 0) return const Text('No spending data yet.', style: TextStyle(color: Colors.grey));
    final interval = (maxY / 4).ceilToDouble();
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 190,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) =>
                BarTooltipItem(_rupee.format(rod.toY), const TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= monthlyTotals.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(monthlyTotals[i].label, style: const TextStyle(fontSize: 10)));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 42, interval: interval,
            getTitlesWidget: (v, _) =>
                Text('₹${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9)),
          )),
        ),
        gridData: FlGridData(
          show: true, horizontalInterval: interval, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: monthlyTotals.asMap().entries.map((e) {
          final isMax = e.value.total == maxY;
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: e.value.total,
              color: isMax ? cs.primary : cs.primary.withOpacity(0.5),
              width: 28,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ]);
        }).toList(),
      )),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  final List<MapEntry<String, double>> catList;
  final double totalSpent;
  final void Function(String category)? onCategoryTap;
  const _CategoryPie({required this.catList, required this.totalSpent, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                if (event is FlTapUpEvent && onCategoryTap != null) {
                  final idx = response?.touchedSection?.touchedSectionIndex;
                  if (idx != null && idx >= 0 && idx < catList.length) {
                    onCategoryTap!(catList[idx].key);
                  }
                }
              },
            ),
            sections: catList.map((e) {
              final pct = totalSpent > 0 ? e.value / totalSpent * 100 : 0;
              return PieChartSectionData(
                value: e.value,
                title: '${pct.toStringAsFixed(0)}%',
                color: _colorFor(e.key),
                radius: 52,
                titleStyle: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              );
            }).toList(),
            sectionsSpace: 2, centerSpaceRadius: 30,
          )),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: catList.take(6).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Container(width: 9, height: 9,
                  decoration: BoxDecoration(color: _colorFor(e.key), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(e.key, style: const TextStyle(fontSize: 11)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}

class _HBar extends StatelessWidget {
  final String label;
  final double value, max;
  final Color color;
  final VoidCallback? onTap;
  const _HBar({required this.label, required this.value, required this.max, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(_rupee.format(value), style: const TextStyle(fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (max > 0 ? value / max : 0.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
      ),
    );
  }
}

// ── Analytics sort dropdown ───────────────────────────────────────────────────

class _ASortDropdown extends StatelessWidget {
  final _ASort value;
  final ValueChanged<_ASort?> onChanged;
  const _ASortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<_ASort>(
        value: value,
        isDense: true,
        items: const [
          DropdownMenuItem(value: _ASort.amountDesc, child: Text('Amount ↓', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: _ASort.amountAsc,  child: Text('Amount ↑', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: _ASort.nameAsc,    child: Text('Name A→Z', style: TextStyle(fontSize: 12))),
          DropdownMenuItem(value: _ASort.nameDesc,   child: Text('Name Z→A', style: TextStyle(fontSize: 12))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

// ── Transaction drill-down sheet ─────────────────────────────────────────────

void _showTxnSheet(BuildContext context, String title, List<Transaction> txns) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _TxnListSheet(title: title, txns: txns),
  );
}

class _TxnListSheet extends StatelessWidget {
  final String title;
  final List<Transaction> txns;
  const _TxnListSheet({required this.title, required this.txns});

  @override
  Widget build(BuildContext context) {
    final total = txns.where((t) => t.type == 'debit').fold(0.0, (s, t) => s + t.amount);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              if (total > 0) Text(
                _rupee.format(total),
                style: TextStyle(fontSize: 14, color: Colors.red[700], fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text('${txns.length} txns', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: txns.isEmpty
                ? const Center(child: Text('No transactions'))
                : ListView.builder(
                    controller: controller,
                    itemCount: txns.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (_, i) {
                      final t = txns[i];
                      final isDebit = t.type == 'debit';
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isDebit ? Colors.red.shade50 : Colors.green.shade50,
                          child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 14, color: isDebit ? Colors.red : Colors.green),
                        ),
                        title: Text(t.merchant ?? t.bank ?? 'Unknown', style: const TextStyle(fontSize: 13)),
                        subtitle: Text(_dateFmt.format(t.transactionDate.toLocal()),
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                          '${isDebit ? '−' : '+'}${_rupee.format(t.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13,
                            color: isDebit ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
