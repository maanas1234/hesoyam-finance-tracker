package com.maanas.finance_tracker

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "finance_widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    val prefs = getSharedPreferences("FinanceWidgetPrefs", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("spent",          call.argument<String>("spent")          ?: "0")
                        .putString("count",          call.argument<String>("count")          ?: "0")
                        .putString("received",       call.argument<String>("received")       ?: "0")
                        .putString("received_count", call.argument<String>("received_count") ?: "0")
                        .putString("month",          call.argument<String>("month")          ?: "")
                        .apply()

                    // Update widget directly — no broadcast needed
                    val mgr = AppWidgetManager.getInstance(this)
                    val ids = mgr.getAppWidgetIds(ComponentName(this, FinanceWidget::class.java))
                    ids.forEach { id -> FinanceWidget.update(this, mgr, id) }

                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
