package io.devopen.subzilla.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.*
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import android.appwidget.AppWidgetManager
import io.devopen.subzilla.MainActivity
import java.time.LocalDate

// ── Color helpers ─────────────────────────────────────────────────────────────

private fun Long.toGlanceColor(): Color {
    val a = ((this shr 24) and 0xFF).toFloat() / 255f
    val r = ((this shr 16) and 0xFF).toFloat() / 255f
    val g = ((this shr 8) and 0xFF).toFloat() / 255f
    val b = (this and 0xFF).toFloat() / 255f
    return Color(r, g, b, a)
}

private fun urgencyColorProvider(days: Long): ColorProvider = when {
    days == 0L -> ColorProvider(Color(0xFFE53935))
    days <= 3L -> ColorProvider(Color(0xFFF57C00))
    else -> ColorProvider(Color(0xFF9E9E9E))
}

// ── Shared composables ────────────────────────────────────────────────────────

@Composable
private fun EmptyState(message: String) {
    Box(contentAlignment = Alignment.Center, modifier = GlanceModifier.fillMaxSize()) {
        Text(message, style = TextStyle(fontSize = 12.sp, color = GlanceTheme.colors.onSurface))
    }
}

@Composable
private fun Divider() {
    Box(
        modifier = GlanceModifier
            .fillMaxWidth()
            .height(1.dp)
            .background(GlanceTheme.colors.surfaceVariant)
    ) {}
}

@Composable
private fun DaysBadge(days: Long) {
    val chipBg: Color? = when {
        days == 0L -> Color(0xFFE53935)
        days <= 3L -> Color(0xFFF57C00)
        else -> null
    }
    val label = if (days == 0L) "Today" else "in ${days}d"
    if (chipBg != null) {
        Box(
            modifier = GlanceModifier
                .background(ColorProvider(chipBg))
                .cornerRadius(6.dp)
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            Text(
                label,
                style = TextStyle(
                    fontSize = 11.sp,
                    color = ColorProvider(Color.White),
                    fontWeight = FontWeight.Medium
                )
            )
        }
    } else {
        Text(
            label,
            style = TextStyle(fontSize = 11.sp, color = GlanceTheme.colors.onSurfaceVariant)
        )
    }
}

@Composable
private fun UpcomingSubRow(sub: WidgetSub, dueDate: LocalDate, today: LocalDate, currency: String) {
    val days = NextDueDateHelper.daysUntil(dueDate, today)
    val daysLabel = if (days == 0L) "Today" else "${days}d"
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = GlanceModifier.fillMaxWidth()
    ) {
        Box(
            modifier = GlanceModifier
                .size(14.dp)
                .cornerRadius(7.dp)
                .background(ColorProvider(sub.color.toGlanceColor()))
        ) {}
        Spacer(modifier = GlanceModifier.width(10.dp))
        Text(
            sub.name,
            style = TextStyle(fontSize = 12.sp, color = GlanceTheme.colors.onBackground),
            modifier = GlanceModifier.defaultWeight(),
            maxLines = 1
        )
        Spacer(modifier = GlanceModifier.width(8.dp))
        Text(
            daysLabel,
            style = TextStyle(fontSize = 10.sp, color = urgencyColorProvider(days))
        )
        Spacer(modifier = GlanceModifier.width(10.dp))
        Text(
            "$currency${String.format(java.util.Locale.US, "%.2f", sub.amount)}",
            style = TextStyle(fontSize = 12.sp, color = GlanceTheme.colors.primary)
        )
    }
}

// ── Monthly Spend Widget ──────────────────────────────────────────────────────

class MonthlySpendWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = SubsDataReader.read(context)
        provideContent { GlanceTheme { MonthlySpendContent(data) } }
    }
}

@Composable
private fun MonthlySpendContent(data: WidgetData?) {
    val modifier = GlanceModifier
        .fillMaxSize()
        .background(GlanceTheme.colors.background)
        .padding(16.dp)
        .clickable(actionStartActivity<MainActivity>())

    if (data == null || data.subs.isEmpty()) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            EmptyState("Add a subscription")
        }
        return
    }

    Column(modifier = modifier, verticalAlignment = Alignment.Top) {
        Text(
            "THIS MONTH",
            style = TextStyle(fontSize = 10.sp, color = GlanceTheme.colors.onSurfaceVariant)
        )
        Spacer(modifier = GlanceModifier.defaultWeight())
        Text(
            "${data.currency}${String.format(java.util.Locale.US, "%.2f", data.monthlyTotal)}",
            style = TextStyle(
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = GlanceTheme.colors.primary
            )
        )
        Spacer(modifier = GlanceModifier.defaultWeight())
        Text(
            "${data.subs.size} subscription${if (data.subs.size == 1) "" else "s"}",
            style = TextStyle(fontSize = 11.sp, color = GlanceTheme.colors.onSurfaceVariant)
        )
    }
}

class MonthlySpendWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = MonthlySpendWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        WidgetRefreshWorker.schedule(context)
    }
}

// ── Next Due Widget ───────────────────────────────────────────────────────────

class NextDueWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = SubsDataReader.read(context)
        val today = LocalDate.now()
        val sorted = data?.subs
            ?.mapNotNull { sub ->
                NextDueDateHelper.parseDate(sub.startDate)?.let { start ->
                    val due = NextDueDateHelper.nextDueDate(start, sub.frequency, today)
                    Triple(sub, due, NextDueDateHelper.daysUntil(due, today))
                }
            }
            ?.sortedBy { it.second }
        provideContent { GlanceTheme { NextDueContent(data, sorted) } }
    }
}

@Composable
private fun NextDueContent(data: WidgetData?, sorted: List<Triple<WidgetSub, LocalDate, Long>>?) {
    val modifier = GlanceModifier
        .fillMaxSize()
        .background(GlanceTheme.colors.background)
        .padding(16.dp)
        .clickable(actionStartActivity<MainActivity>())

    if (sorted.isNullOrEmpty()) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            EmptyState("No subscriptions")
        }
        return
    }

    val (first, _, days) = sorted[0]
    Column(modifier = modifier) {
        // Label row with left color stripe
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = GlanceModifier
                    .width(3.dp)
                    .height(13.dp)
                    .cornerRadius(2.dp)
                    .background(ColorProvider(first.color.toGlanceColor()))
            ) {}
            Spacer(modifier = GlanceModifier.width(7.dp))
            Text(
                "NEXT DUE",
                style = TextStyle(fontSize = 10.sp, color = GlanceTheme.colors.onSurfaceVariant)
            )
        }
        Spacer(modifier = GlanceModifier.defaultWeight())
        // Subscription name — hero element
        Text(
            first.name,
            style = TextStyle(
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = GlanceTheme.colors.onBackground
            ),
            maxLines = 1
        )
        Spacer(modifier = GlanceModifier.height(4.dp))
        Text(
            "${data!!.currency}${String.format(java.util.Locale.US, "%.2f", first.amount)}",
            style = TextStyle(fontSize = 14.sp, color = GlanceTheme.colors.primary)
        )
        Spacer(modifier = GlanceModifier.defaultWeight())
        DaysBadge(days)
    }
}

class NextDueWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = NextDueWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        WidgetRefreshWorker.schedule(context)
    }
}

// ── Upcoming Widget ───────────────────────────────────────────────────────────

class UpcomingWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = SubsDataReader.read(context)
        val today = LocalDate.now()
        val sorted = data?.subs
            ?.mapNotNull { sub ->
                NextDueDateHelper.parseDate(sub.startDate)?.let { start ->
                    Pair(sub, NextDueDateHelper.nextDueDate(start, sub.frequency, today))
                }
            }
            ?.sortedBy { it.second }
        provideContent { GlanceTheme { UpcomingContent(data, sorted) } }
    }
}

@Composable
private fun UpcomingContent(data: WidgetData?, sorted: List<Pair<WidgetSub, LocalDate>>?) {
    val modifier = GlanceModifier
        .fillMaxSize()
        .background(GlanceTheme.colors.background)
        .padding(16.dp)
        .clickable(actionStartActivity<MainActivity>())

    if (sorted.isNullOrEmpty()) {
        Box(modifier = modifier, contentAlignment = Alignment.Center) {
            EmptyState("No subscriptions")
        }
        return
    }

    val today = LocalDate.now()
    Column(modifier = modifier, verticalAlignment = Alignment.Top) {
        // Header: title left, monthly total right
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "UPCOMING",
                style = TextStyle(
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = GlanceTheme.colors.onSurfaceVariant
                )
            )
            Spacer(modifier = GlanceModifier.defaultWeight())
            Text(
                "${data!!.currency}${String.format(java.util.Locale.US, "%.2f", data.monthlyTotal)} / mo",
                style = TextStyle(fontSize = 11.sp, color = GlanceTheme.colors.primary)
            )
        }
        Spacer(modifier = GlanceModifier.height(10.dp))
        Divider()
        Spacer(modifier = GlanceModifier.height(10.dp))
        sorted.take(5).forEachIndexed { index, (sub, dueDate) ->
            UpcomingSubRow(sub = sub, dueDate = dueDate, today = today, currency = data!!.currency)
            if (index < minOf(sorted.size, 5) - 1) {
                Spacer(modifier = GlanceModifier.height(8.dp))
            }
        }
    }
}

class UpcomingWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = UpcomingWidget()

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        WidgetRefreshWorker.schedule(context)
    }
}
