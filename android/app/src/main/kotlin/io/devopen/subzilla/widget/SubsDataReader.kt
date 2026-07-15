package io.devopen.subzilla.widget

import android.content.Context
import org.json.JSONObject

data class WidgetSub(
    val name: String,
    val amount: Double,
    val monthlyAmount: Double,
    val startDate: String,   // ISO 8601, no timezone
    val frequency: String,   // "daily" | "weekly" | "monthly" | "yearly"
    val color: Long          // ARGB as Long (Flutter Color.value)
)

data class WidgetData(
    val subs: List<WidgetSub>,
    val currency: String,
    val monthlyTotal: Double
)

object SubsDataReader {
    fun read(context: Context): WidgetData? {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("subs_data", null) ?: return null
        return try {
            val obj = JSONObject(json)
            val subsArray = obj.getJSONArray("subs")
            val subs = (0 until subsArray.length()).map { i ->
                val s = subsArray.getJSONObject(i)
                WidgetSub(
                    name = s.getString("name"),
                    amount = s.getDouble("amount"),
                    monthlyAmount = s.getDouble("monthlyAmount"),
                    startDate = s.getString("startDate"),
                    frequency = s.getString("frequency"),
                    color = s.getLong("color")
                )
            }
            WidgetData(
                subs = subs,
                currency = obj.getString("currency"),
                monthlyTotal = obj.getDouble("monthlyTotal")
            )
        } catch (e: Exception) {
            null
        }
    }
}
