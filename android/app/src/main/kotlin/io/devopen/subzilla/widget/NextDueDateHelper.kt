package io.devopen.subzilla.widget

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

object NextDueDateHelper {
    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS")

    fun parseDate(isoString: String): LocalDate? = try {
        LocalDate.parse(isoString, formatter)
    } catch (e: Exception) {
        // Fallback for full ISO with timezone
        try { LocalDate.parse(isoString.take(10)) } catch (e2: Exception) { null }
    }

    /**
     * k-th charge date, always derived from the start date so month-end
     * anchors don't drift (Jan 31 -> Feb 28 -> Mar 31). Must match
     * lib/models/billing.dart.
     */
    fun occurrence(startDate: LocalDate, frequency: String, k: Long, interval: Int = 1): LocalDate {
        val n = k * maxOf(1, interval)
        return when (frequency) {
            "daily" -> startDate.plusDays(n)
            "weekly" -> startDate.plusWeeks(n)
            "yearly" -> startDate.plusYears(n)
            else -> startDate.plusMonths(n)
        }
    }

    /** First charge on or after [today]; a charge due today is "next". */
    fun nextDueDate(
        startDate: LocalDate,
        frequency: String,
        today: LocalDate = LocalDate.now(),
        interval: Int = 1,
    ): LocalDate {
        if (!startDate.isBefore(today)) return startDate
        val unit = when (frequency) {
            "daily" -> ChronoUnit.DAYS
            "weekly" -> ChronoUnit.WEEKS
            "yearly" -> ChronoUnit.YEARS
            else -> ChronoUnit.MONTHS
        }
        // Estimate from below in charges, then step forward.
        var k = maxOf(0L, (unit.between(startDate, today) - 1) / maxOf(1, interval))
        while (occurrence(startDate, frequency, k, interval).isBefore(today)) k++
        return occurrence(startDate, frequency, k, interval)
    }

    fun daysUntil(date: LocalDate, today: LocalDate = LocalDate.now()): Long =
        ChronoUnit.DAYS.between(today, date)
}
