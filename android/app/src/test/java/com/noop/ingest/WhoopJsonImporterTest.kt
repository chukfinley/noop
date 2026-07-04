package com.noop.ingest

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for the pure parse layer of [WhoopJsonImporter] — the whoopsi `whoop_backup/`
 * JSON → store-row mapping. Mirrors the convention of [WhoopCsvExporterTest] /
 * WhoopCycleSeriesTest: no Room, no Context, fixtures as raw JSON strings, assertions on the
 * returned row objects. Real `org.json` is on the JVM test classpath.
 */
class WhoopJsonImporterTest {

    private val device = "my-whoop"

    /** A representative all_cycles.json (developer/v1 cycle) for 2025-01-15. */
    private val cyclesJson = """
        [
          {
            "id": 111,
            "start": "2025-01-15T04:00:00.000Z",
            "end":   "2025-01-16T04:00:00.000Z",
            "score_state": "SCORED",
            "score": {
              "strain": 12.3,
              "kilojoule": 8368.0,
              "average_heart_rate": 60,
              "max_heart_rate": 150
            }
          },
          {
            "id": 112,
            "start": "2025-01-16T04:00:00.000Z",
            "score_state": "PENDING_SCORE",
            "score": null
          }
        ]
    """.trimIndent()

    /** A representative deep_dive/2025-01-15.json (internal home-service tile tree). */
    private val deepDiveJson = """
        {
          "recovery": { "sections": [ { "items": [
            { "type": "SCORE_GAUGE", "content": { "id": "RECOVERY_SCORE_GAUGE", "score_display": "72" } },
            { "type": "CONTRIBUTORS_TILE", "content": { "metrics": [
              { "id": "HRV_CONTRIBUTOR", "title": "HEART RATE VARIABILITY", "status": "62" },
              { "id": "RHR_CONTRIBUTOR", "title": "RESTING HEART RATE", "status": "55" },
              { "id": "RESPIRATORY_RATE", "title": "RESPIRATORY RATE", "status": "14.5" }
            ] } }
          ] } ] },
          "sleep": { "sections": [ { "items": [
            { "type": "SCORE_GAUGE", "content": { "id": "SLEEP_SCORE_GAUGE", "score_display": "88" } },
            { "type": "CONTRIBUTORS_TILE", "content": { "metrics": [
              { "id": "SLEEP_EFFICIENCY", "title": "EFFICIENCY", "status": "91" },
              { "id": "SLEEP_CONSISTENCY", "title": "CONSISTENCY", "status": "70" }
            ] } }
          ] } ] },
          "last_night": {
            "header_section": { "destination": { "parameters": {
              "start_time": "2025-01-14T23:00:00.000Z",
              "end_time":   "2025-01-15T06:30:00.000Z"
            } } },
            "graph": { "plots": [ { "points": [
              { "data_scrubber_details": { "secondary_contextual_display": "11:00 PM", "scrubber_style": "LIGHT_SLEEP" } },
              { "data_scrubber_details": { "secondary_contextual_display": "11:01 PM", "scrubber_style": "LIGHT_SLEEP" } },
              { "data_scrubber_details": { "secondary_contextual_display": "11:02 PM", "scrubber_style": "SWS_SLEEP" } },
              { "data_scrubber_details": { "secondary_contextual_display": "12:30 AM", "scrubber_style": "REM_SLEEP" } },
              { "data_scrubber_details": { "secondary_contextual_display": "1:00 AM",  "scrubber_style": "AWAKE" } }
            ] } ] }
          }
        }
    """.trimIndent()

    private fun files(vararg pairs: Pair<String, String>): Map<String, ByteArray> =
        pairs.associate { it.first to it.second.toByteArray() }

    @Test
    fun parsesCyclesAndDeepDive_intoOneDay() {
        val parsed = WhoopJsonImporter.parse(
            files(
                "api/all_cycles.json" to cyclesJson,
                "deep_dive/2025-01-15.json" to deepDiveJson,
            ),
            device,
        )

        // One scored day; the PENDING cycle is skipped (no score) and produces no extra day.
        assertEquals(1, parsed.daily.size)
        val d = parsed.daily.first()
        assertEquals(device, d.deviceId)
        assertEquals("2025-01-15", d.day)

        // Recovery contributors (display strings -> numbers).
        assertEquals(72.0, d.recovery!!, 1e-9)
        assertEquals(55, d.restingHr)          // rounded
        assertEquals(62.0, d.avgHrv!!, 1e-9)
        assertEquals(14.5, d.respRateBpm!!, 1e-9)

        // Strain from the numeric cycle score.
        assertEquals(12.3, d.strain!!, 1e-9)

        // Sleep architecture from the per-minute scrubber: light=2, deep=1, rem=1, awake=1.
        assertEquals(2.0, d.lightMin!!, 1e-9)
        assertEquals(1.0, d.deepMin!!, 1e-9)
        assertEquals(1.0, d.remMin!!, 1e-9)
        assertEquals(4.0, d.totalSleepMin!!, 1e-9)   // light + deep + rem
        assertEquals(1, d.disturbances)              // awake minutes -> disturbances slot
        assertEquals(91.0, d.efficiency!!, 1e-9)

        // SpO2 / skin-temp are not in WHOOP cloud JSON.
        assertNull(d.spo2Pct)
        assertNull(d.skinTempDevC)
    }

    @Test
    fun emitsMetricSeries_withEnergyKcalConversion() {
        val parsed = WhoopJsonImporter.parse(
            files(
                "api/all_cycles.json" to cyclesJson,
                "deep_dive/2025-01-15.json" to deepDiveJson,
            ),
            device,
        )
        val series = parsed.series.associate { (it.key) to it.value }
        // 8368 kJ / 4.184 = 2000 kcal.
        assertEquals(2000.0, series["energy_kcal"]!!, 1e-6)
        assertEquals(60.0, series["avg_hr"]!!, 1e-9)
        assertEquals(150.0, series["max_hr"]!!, 1e-9)
        assertEquals(88.0, series["sleep_performance"]!!, 1e-9)
        assertEquals(70.0, series["sleep_consistency"]!!, 1e-9)
    }

    @Test
    fun buildsSleepSession_fromLastNightAndStages() {
        val parsed = WhoopJsonImporter.parse(
            files("deep_dive/2025-01-15.json" to deepDiveJson),
            device,
        )
        assertEquals(1, parsed.sessions.size)
        val s = parsed.sessions.first()
        assertEquals(device, s.deviceId)
        // 2025-01-14T23:00:00Z and 2025-01-15T06:30:00Z.
        assertEquals(1736895600L, s.startTs)
        assertEquals(1736922600L, s.endTs)
        assertTrue(s.endTs > s.startTs)
        assertEquals(91.0, s.efficiency!!, 1e-9)
        assertEquals(55, s.restingHr)
        assertNotNull(s.stagesJSON)
        val stages = JSONArray(s.stagesJSON)
        // Aggregate [{stage,min}] shape, same as the CSV importer.
        val byStage = (0 until stages.length()).associate {
            val o = stages.getJSONObject(it); o.getString("stage") to o.getDouble("min")
        }
        assertEquals(2.0, byStage["light"]!!, 1e-9)
        assertEquals(1.0, byStage["deep"]!!, 1e-9)
        assertEquals(1.0, byStage["rem"]!!, 1e-9)
        assertEquals(1.0, byStage["awake"]!!, 1e-9)
    }

    @Test
    fun acceptsDeepDiveAll_keyedByDate() {
        val all = JSONObject().put("2025-01-15", JSONObject(deepDiveJson)).toString()
        val parsed = WhoopJsonImporter.parse(files("deep_dive_all.json" to all), device)
        assertEquals(1, parsed.daily.size)
        assertEquals("2025-01-15", parsed.daily.first().day)
        assertEquals(72.0, parsed.daily.first().recovery!!, 1e-9)
    }

    @Test
    fun emptyAndGarbageInput_degradesGracefully() {
        assertEquals(0, WhoopJsonImporter.parse(emptyMap(), device).daily.size)
        // Non-JSON / unrelated content must not throw.
        val parsed = WhoopJsonImporter.parse(files("note.txt" to "not json at all"), device)
        assertEquals(0, parsed.daily.size)
        assertEquals(0, parsed.sessions.size)
    }

    @Test
    fun missingDeepDive_stillImportsCycleNumerics() {
        val parsed = WhoopJsonImporter.parse(files("api/all_cycles.json" to cyclesJson), device)
        assertEquals(1, parsed.daily.size)
        val d = parsed.daily.first()
        assertEquals(12.3, d.strain!!, 1e-9)
        assertNull(d.recovery)        // no deep-dive -> no recovery
        assertNull(d.lightMin)        // no scrubber -> no stages
        assertEquals(0, parsed.sessions.size)
    }
}
