package com.maanas.finance_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.NumberFormat
import java.util.Locale

class FinanceWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, mgr, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val page = prefs.getInt("page", 0)
            prefs.edit().putInt("page", if (page == 0) 1 else 0).apply()
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, FinanceWidget::class.java))
            ids.forEach { update(context, mgr, it) }
        }
    }

    companion object {
        const val PREFS = "FinanceWidgetPrefs"
        const val ACTION_TOGGLE = "com.maanas.finance_tracker.WIDGET_TOGGLE"

        private val numFmt = NumberFormat.getNumberInstance(Locale("en", "IN"))
            .apply { maximumFractionDigits = 0 }

        fun update(context: Context, mgr: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val page          = prefs.getInt("page", 0)
            val spent         = prefs.getString("spent",          "0")?.toDoubleOrNull() ?: 0.0
            val spentCount    = prefs.getString("count",          "0")?.toIntOrNull()    ?: 0
            val received      = prefs.getString("received",       "0")?.toDoubleOrNull() ?: 0.0
            val receivedCount = prefs.getString("received_count", "0")?.toIntOrNull()    ?: 0
            val month         = prefs.getString("month",          "") ?: ""

            val isSpent      = page == 0
            val amount       = if (isSpent) spent else received
            val count        = if (isSpent) spentCount else receivedCount
            val label        = if (isSpent) "SPENT" else "RECEIVED"
            val indicator    = if (isSpent) "tap → received" else "← spent"
            // Red for spent, green for received
            val amountColor  = if (isSpent) 0xFFEF4444.toInt() else 0xFF22C55E.toInt()
            val labelColor   = if (isSpent) 0xFFEF4444.toInt() else 0xFF22C55E.toInt()

            val views = RemoteViews(context.packageName, R.layout.finance_widget)
            views.setTextViewText(R.id.widget_label,     label)
            views.setTextViewText(R.id.widget_amount,    "₹${numFmt.format(amount)}")
            views.setTextViewText(R.id.widget_count,     "$count txn${if (count == 1) "" else "s"}")
            views.setTextViewText(R.id.widget_month,     month)
            views.setTextViewText(R.id.widget_indicator, indicator)
            views.setTextColor(R.id.widget_label,        labelColor)
            views.setTextColor(R.id.widget_amount,       amountColor)

            // Tap → toggle
            val toggleIntent = Intent(ACTION_TOGGLE).apply { setPackage(context.packageName) }
            val pi = PendingIntent.getBroadcast(
                context, 0, toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)

            mgr.updateAppWidget(id, views)
        }
    }
}
