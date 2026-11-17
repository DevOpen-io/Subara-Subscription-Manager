package io.devopen.subzilla.widget

import java.time.LocalDate
import org.junit.Assert.assertEquals
import org.junit.Test

/** Mirrors test/models/billing_test.dart so widget and app agree. */
class NextDueDateHelperTest {
    private fun d(y: Int, m: Int, day: Int) = LocalDate.of(y, m, day)
    private fun next(start: LocalDate, f: String, today: LocalDate) =
        NextDueDateHelper.nextDueDate(start, f, today)

    @Test fun chargeDueTodayIsNext() =
        assertEquals(d(2026, 11, 16), next(d(2026, 1, 16), "monthly", d(2026, 11, 16)))

    @Test fun dayAfterChargeMovesToNextMonth() =
        assertEquals(d(2026, 12, 16), next(d(2026, 1, 16), "monthly", d(2026, 11, 17)))

    @Test fun jan31DoesNotDriftAfterFebruary() {
        assertEquals(d(2026, 2, 28), next(d(2026, 1, 31), "monthly", d(2026, 2, 28)))
        assertEquals(d(2026, 3, 31), next(d(2026, 1, 31), "monthly", d(2026, 3, 1)))
        assertEquals(d(2026, 4, 30), next(d(2026, 1, 31), "monthly", d(2026, 4, 2)))
    }

    @Test fun yearlyFeb29FallsOnFeb28() =
        assertEquals(d(2029, 2, 28), next(d(2028, 2, 29), "yearly", d(2028, 3, 1)))

    @Test fun futureStartIsNext() =
        assertEquals(d(2027, 5, 1), next(d(2027, 5, 1), "yearly", d(2026, 11, 16)))

    @Test fun weeklyLandsOnStartWeekday() =
        assertEquals(d(2026, 11, 23), next(d(2026, 11, 2), "weekly", d(2026, 11, 18)))

    @Test fun dailyDueToday() =
        assertEquals(d(2026, 11, 16), next(d(1990, 1, 1), "daily", d(2026, 11, 16)))

    @Test fun everyThreeMonthsFromNov30() {
        val n = { today: LocalDate -> NextDueDateHelper.nextDueDate(d(2026, 11, 30), "monthly", today, 3) }
        assertEquals(d(2027, 2, 28), n(d(2026, 12, 1)))
        assertEquals(d(2027, 5, 30), n(d(2027, 3, 1)))
    }

    @Test fun biweeklySkipsOffWeek() =
        assertEquals(d(2026, 11, 16), NextDueDateHelper.nextDueDate(d(2026, 11, 2), "weekly", d(2026, 11, 3), 2))

    @Test fun invalidIntervalActsAsOne() =
        assertEquals(d(2026, 3, 15), NextDueDateHelper.nextDueDate(d(2026, 1, 15), "monthly", d(2026, 3, 2), 0))
}
