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

    fun nextDueDate(startDate: LocalDate, frequency: String, today: LocalDate = LocalDate.now()): LocalDate {
        if (startDate.isAfter(today)) return startDate
        var candidate = when (frequency) {
            "daily" -> {
                val days = ChronoUnit.DAYS.between(startDate, today) + 1
                startDate.plusDays(days)
            }
            "weekly" -> {
                val weeks = ChronoUnit.WEEKS.between(startDate, today) + 1
                startDate.plusWeeks(weeks)
            }
            "monthly" -> {
                val months = ChronoUnit.MONTHS.between(startDate, today) + 1
                startDate.plusMonths(months)
            }
            "yearly" -> {
                val years = ChronoUnit.YEARS.between(startDate, today) + 1
                startDate.plusYears(years)
            }
            else -> startDate.plusMonths(1)
        }
        // Guard: if still <= today (edge case with month-end clamping), advance one more period
        if (!candidate.isAfter(today)) {
            candidate = when (frequency) {
                "daily" -> candidate.plusDays(1)
                "weekly" -> candidate.plusWeeks(1)
                "monthly" -> candidate.plusMonths(1)
                "yearly" -> candidate.plusYears(1)
                else -> candidate.plusMonths(1)
            }
        }
        return candidate
    }

    fun daysUntil(date: LocalDate, today: LocalDate = LocalDate.now()): Long =
        ChronoUnit.DAYS.between(today, date)
}
