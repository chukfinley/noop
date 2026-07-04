package com.noop.ingest

import android.content.Context
import android.net.Uri
import com.noop.data.DailyMetric
import com.noop.data.ImportSummary
import com.noop.data.MetricSeriesRow
import com.noop.data.SleepSession
import com.noop.data.WhoopRepository
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.util.zip.ZipInputStream
import kotlin.math.roundToInt

/**
 * Imports a **whoopsi** `whoop_backup/` JSON export (the directory the `whoop export` /
 * `whoop deep-dive` CLI writes) into the local Room store — the same sink the WHOOP **CSV**
 * importer feeds ([WhoopCsvImporter]), so the rest of the app lights up identically.
 *
 * Why a second importer: the whoopsi tool pulls the **full** cloud dataset WHOOP exposes —
 * the numeric developer-API cycles plus the internal "deep-dive" tiles that carry the
 * recovery/sleep contributors and the per-minute sleep-stage scrubber. That is richer and
 * more accurate than the daily-rollup CSV a user can self-export. This importer reads it
 * directly. It is purely **additive**: the CSV path is untouched, and everything written
 * here lands under the same `deviceId = "my-whoop"`, so imported rows still win over the
 * on-device computed `"-noop"` rows via [WhoopRepository] merge precedence.
 *
 * What it reads from a `whoop_backup/` (folder zipped, or individual JSON files):
 *   api/all_cycles.json            -> per-day numeric strain / energy / avg+max HR  (developer/v1 cycle)
 *   deep_dive/<YYYY-MM-DD>.json     -> recovery (score, HRV, RHR, resp), sleep (perf, efficiency,
 *   deep_dive_all.json                 consistency), and the last-night stage timeline
 *
 * The whole pipeline is tolerant in the spirit of [WhoopCsvImporter]: every file, key and tile
 * is optional; unknown shapes degrade to null rather than throwing. Cycles and deep-dive are
 * joined on the cycle `start[:10]` date — the exact key the backup producer itself uses to name
 * the deep-dive files (`whoop_cli` export.py derives deep-dive dates from `cycle.start[:10]`).
 *
 * NOTE: WHOOP's cloud export carries no stable, parseable per-workout or journal payload (the
 * `activities/<id>.json` are render trees and journal is a local app feature), so this importer
 * writes daily metrics, sleep sessions and metric series only. Workouts/journal still come from
 * the CSV export. SpO2 and skin-temp are not present in the cloud JSON (BLE-sensor only) — left null.
 */
object WhoopJsonImporter {

    private const val WHOOP_DEVICE = "my-whoop"
    private const val SOURCE_LABEL = "WHOOP (whoopsi)"

    /** Per-entry uncompressed ceiling (zip-bomb guard). Matches [WhoopCsvImporter]. */
    private const val MAX_ENTRY_BYTES = 256L shl 20

    private val STAGE_ENUM = mapOf(
        "AWAKE" to "awake",
        "LIGHT_SLEEP" to "light",
        "SWS_SLEEP" to "deep",
        "REM_SLEEP" to "rem",
    )

    // MARK: - Public entry point (I/O wrapper)

    /**
     * Public entry point the UI calls. Accepts a `.zip` of a `whoop_backup/` folder, or a single
     * `.json` file from it (all_cycles.json / a deep_dive day / deep_dive_all.json). Reads the SAF
     * [uri], parses, and upserts via [repo] under [deviceId] (default "my-whoop").
     */
    suspend fun importBackup(
        context: Context,
        uri: Uri,
        repo: WhoopRepository,
        deviceId: String = WHOOP_DEVICE,
    ): ImportSummary {
        val files: Map<String, ByteArray> = try {
            loadJsonData(context, uri)
        } catch (e: Exception) {
            return ImportSummary.failure(SOURCE_LABEL, "Could not read backup: ${e.message ?: "unknown error"}")
        }
        if (files.isEmpty()) {
            return ImportSummary.failure(
                SOURCE_LABEL,
                "No whoopsi JSON found (expected all_cycles.json and/or deep_dive/*.json).",
            )
        }

        val parsed = parse(files, deviceId)
        if (parsed.daily.isEmpty() && parsed.sessions.isEmpty()) {
            return ImportSummary.failure(SOURCE_LABEL, "Backup contained no usable WHOOP days.")
        }

        repo.upsertDevice(deviceId, name = "WHOOP")
        if (parsed.daily.isNotEmpty()) repo.upsertDailyMetrics(parsed.daily)
        if (parsed.sessions.isNotEmpty()) repo.upsertSleepSessions(parsed.sessions)
        if (parsed.series.isNotEmpty()) repo.upsertMetricSeries(parsed.series)

        val counts = LinkedHashMap<String, Int>()
        if (parsed.daily.isNotEmpty()) counts["dailyMetric"] = parsed.daily.size
        if (parsed.sessions.isNotEmpty()) counts["sleepSession"] = parsed.sessions.size
        if (parsed.series.isNotEmpty()) counts["metricSeries"] = parsed.series.size

        val days = parsed.daily.map { it.day }
        val firstDay = days.minOrNull()
        val lastDay = days.maxOrNull()
        val total = counts.values.sum()
        val message = buildString {
            append("Imported ").append(total).append(" WHOOP rows from whoopsi backup")
            if (firstDay != null && lastDay != null) append(" ($firstDay → $lastDay)")
            append(".")
        }
        return ImportSummary(SOURCE_LABEL, counts, firstDay, lastDay, message)
    }

    // MARK: - Pure parse (JVM-unit-testable)

    /** Normalized output of parsing a whoopsi backup. */
    internal class Parsed(
        val daily: List<DailyMetric>,
        val sessions: List<SleepSession>,
        val series: List<MetricSeriesRow>,
    )

    /** Per-day fields gathered from cycles + deep-dive before being collapsed to store rows. */
    private class DayAcc(val day: String) {
        var recovery: Double? = null
        var restingHr: Double? = null
        var hrv: Double? = null
        var resp: Double? = null
        var strain: Double? = null
        var energyKcal: Double? = null
        var avgHr: Double? = null
        var maxHr: Double? = null
        var sleepPerformance: Double? = null
        var sleepEfficiency: Double? = null
        var sleepConsistency: Double? = null
        var lightMin: Double? = null
        var deepMin: Double? = null
        var remMin: Double? = null
        var awakeMin: Double? = null
        var onsetTs: Long? = null
        var wakeTs: Long? = null
    }

    /**
     * Parse a map of `relativePath -> rawJsonBytes` into store rows. Tolerant: routes each file by
     * name/shape, merges everything per day, and degrades missing data to null.
     */
    internal fun parse(files: Map<String, ByteArray>, deviceId: String): Parsed {
        val acc = LinkedHashMap<String, DayAcc>()
        fun day(d: String) = acc.getOrPut(d) { DayAcc(d) }

        for ((path, bytes) in files) {
            val base = path.substringAfterLast('/').substringAfterLast('\\').lowercase()
            val text = String(bytes, Charsets.UTF_8).trim()
            if (text.isEmpty()) continue
            when {
                base == "all_cycles.json" || text.startsWith("[") ->
                    runCatching { ingestCycles(JSONArray(text), ::day) }
                base == "deep_dive_all.json" ->
                    runCatching { ingestDeepDiveAll(JSONObject(text), ::day) }
                base.startsWith("deep_dive") || looksLikeDeepDiveDay(text) -> {
                    // A single deep_dive/<date>.json — the date is the filename stem.
                    val date = base.removeSuffix(".json").takeIf { isDate(it) }
                    runCatching { JSONObject(text) }.getOrNull()?.let { obj ->
                        if (date != null) ingestDeepDiveDay(date, obj, ::day)
                        else ingestDeepDiveAll(obj, ::day) // unkeyed object: try as {date: {...}}
                    }
                }
                text.startsWith("{") ->
                    // Unknown object — try as deep_dive_all (a {date: {...}} map). Harmless if it isn't.
                    runCatching { ingestDeepDiveAll(JSONObject(text), ::day) }
            }
        }

        val daily = ArrayList<DailyMetric>()
        val series = ArrayList<MetricSeriesRow>()
        val sessions = ArrayList<SleepSession>()
        for (a in acc.values) {
            val asleep = sumOrNull(a.lightMin, a.deepMin, a.remMin)
            daily.add(
                DailyMetric(
                    deviceId = deviceId,
                    day = a.day,
                    totalSleepMin = asleep,
                    efficiency = a.sleepEfficiency,
                    deepMin = a.deepMin,
                    remMin = a.remMin,
                    lightMin = a.lightMin,
                    disturbances = a.awakeMin?.roundToInt(),
                    restingHr = a.restingHr?.roundToInt(),
                    avgHrv = a.hrv,
                    recovery = a.recovery,
                    strain = a.strain,
                    exerciseCount = null,
                    spo2Pct = null,       // not in WHOOP cloud JSON (BLE-sensor only)
                    skinTempDevC = null,  // not in WHOOP cloud JSON (BLE-sensor only)
                    respRateBpm = a.resp,
                ),
            )
            // Long-format series (same keys the macOS WhoopImporter publishes for the explorer).
            fun s(key: String, v: Double?) { if (v != null) series.add(MetricSeriesRow(deviceId, a.day, key, v)) }
            s("sleep_performance", a.sleepPerformance)
            s("sleep_consistency", a.sleepConsistency)
            s("energy_kcal", a.energyKcal)
            s("avg_hr", a.avgHr)
            s("max_hr", a.maxHr)

            val start = a.onsetTs
            val end = a.wakeTs
            if (start != null && end != null && end > start) {
                sessions.add(
                    SleepSession(
                        deviceId = deviceId,
                        startTs = start,
                        endTs = end,
                        efficiency = a.sleepEfficiency,
                        restingHr = a.restingHr?.roundToInt(),
                        avgHrv = a.hrv,
                        stagesJSON = stagesJson(a.lightMin, a.deepMin, a.remMin, a.awakeMin),
                    ),
                )
            }
        }
        return Parsed(daily, sessions, series)
    }

    // MARK: - all_cycles.json (developer/v1 cycle objects)

    private fun ingestCycles(arr: JSONArray, day: (String) -> DayAcc) {
        for (i in 0 until arr.length()) {
            val c = arr.optJSONObject(i) ?: continue
            if (c.optString("score_state").let { it.isNotEmpty() && it != "SCORED" }) continue
            val start = c.optString("start").takeIf { it.length >= 10 } ?: continue
            val score = c.optJSONObject("score") ?: continue
            val d = day(start.substring(0, 10))
            optDouble(score, "strain")?.let { d.strain = it }
            // WHOOP reports energy as kilojoules; the app stores kcal (kJ / 4.184).
            optDouble(score, "kilojoule", "kilojoules")?.let { d.energyKcal = it / 4.184 }
            optDouble(score, "average_heart_rate")?.let { d.avgHr = it }
            optDouble(score, "max_heart_rate")?.let { d.maxHr = it }
        }
    }

    // MARK: - deep-dive

    private fun ingestDeepDiveAll(obj: JSONObject, day: (String) -> DayAcc) {
        val keys = obj.keys()
        while (keys.hasNext()) {
            val k = keys.next()
            if (!isDate(k)) continue
            obj.optJSONObject(k)?.let { ingestDeepDiveDay(k, it, day) }
        }
    }

    /** Parse one deep-dive day object `{sleep, recovery, strain, last_night}` into [day]. */
    private fun ingestDeepDiveDay(date: String, obj: JSONObject, day: (String) -> DayAcc) {
        val d = day(date)

        // Recovery tile tree: SCORE_GAUGE + CONTRIBUTORS_TILE metrics (values are display strings).
        obj.optJSONObject("recovery")?.let { rec ->
            scoreGauge(rec, "RECOVERY_SCORE_GAUGE")?.let { d.recovery = it }
            contributor(rec, "HRV")?.let { d.hrv = it }
            contributor(rec, "RHR")?.let { d.restingHr = it }
            contributor(rec, "RESPIRATORY")?.let { d.resp = it }
        }
        // Sleep tile tree.
        obj.optJSONObject("sleep")?.let { sl ->
            scoreGauge(sl, "SLEEP_SCORE_GAUGE")?.let { d.sleepPerformance = it }
            contributor(sl, "EFFICIENCY")?.let { d.sleepEfficiency = it }
            contributor(sl, "CONSISTENCY")?.let { d.sleepConsistency = it }
        }
        // Last-night: onset/wake timestamps + the per-minute stage scrubber.
        val lastNight = obj.optJSONObject("last_night") ?: obj.optJSONObject("sleep")
        if (lastNight != null) {
            findString(lastNight, "start_time")?.let { d.onsetTs = parseIso(it) ?: d.onsetTs }
            findString(lastNight, "end_time")?.let { d.wakeTs = parseIso(it) ?: d.wakeTs }
            val mins = stageMinutes(collectStageLabels(lastNight))
            if (mins != null) {
                d.lightMin = mins["light"]; d.deepMin = mins["deep"]
                d.remMin = mins["rem"]; d.awakeMin = mins["awake"]
            }
        }
    }

    // MARK: - tile-tree extraction (mirrors whoopsi loader.py / features.py)

    /** `content.score_display` (as a number) for the SCORE_GAUGE whose `content.id == id`. */
    private fun scoreGauge(tree: JSONObject, id: String): Double? {
        var found: Double? = null
        walkObjects(tree) { o ->
            if (o.optString("type") == "SCORE_GAUGE") {
                val c = o.optJSONObject("content")
                if (c != null && c.optString("id") == id) {
                    parseNumber(c.optString("score_display"))?.let { found = it }
                }
            }
        }
        return found
    }

    /** First CONTRIBUTORS_TILE metric whose `id` (or `title`) contains [idContains], value = `status`. */
    private fun contributor(tree: JSONObject, idContains: String): Double? {
        var found: Double? = null
        walkObjects(tree) { o ->
            if (found == null && o.optString("type") == "CONTRIBUTORS_TILE") {
                val metrics = o.optJSONObject("content")?.optJSONArray("metrics") ?: return@walkObjects
                for (i in 0 until metrics.length()) {
                    val m = metrics.optJSONObject(i) ?: continue
                    val key = (m.optString("id") + " " + m.optString("title")).uppercase()
                    if (key.contains(idContains)) {
                        parseNumber(m.optString("status"))?.let { found = it }
                        if (found != null) break
                    }
                }
            }
        }
        return found
    }

    /** Collect (minuteOfDay, stage) labels from every `scrubber_style` node in the subtree. */
    private fun collectStageLabels(tree: JSONObject): List<Pair<Int, String>> {
        val seen = HashMap<Int, String>()
        walkObjects(tree) { o ->
            val raw = o.optString("scrubber_style")
            val stage = STAGE_ENUM[raw] ?: return@walkObjects
            val timeStr = o.optString("secondary_contextual_display").takeIf { it.isNotEmpty() }
                ?: return@walkObjects
            val minute = parseClockMinute(timeStr) ?: return@walkObjects
            if (!seen.containsKey(minute)) seen[minute] = stage
        }
        return seen.entries.map { it.key to it.value }.sortedBy { sortMinute(it.first) }
    }

    /** Minutes per stage from deduped per-minute labels (each label ≈ one minute, as WHOOP renders). */
    private fun stageMinutes(labels: List<Pair<Int, String>>): Map<String, Double>? {
        if (labels.isEmpty()) return null
        val counts = HashMap<String, Double>()
        for ((_, stage) in labels) counts[stage] = (counts[stage] ?: 0.0) + 1.0
        return counts
    }

    // MARK: - JSON tree walkers + scalar parsing

    /** Depth-first visit of every JSONObject in the tree (including [root]). */
    private fun walkObjects(root: Any?, visit: (JSONObject) -> Unit) {
        when (root) {
            is JSONObject -> {
                visit(root)
                val keys = root.keys()
                while (keys.hasNext()) walkObjects(root.get(keys.next()), visit)
            }
            is JSONArray -> for (i in 0 until root.length()) walkObjects(root.opt(i), visit)
        }
    }

    /** First string value for [key] anywhere in the subtree (tolerant of deep nesting). */
    private fun findString(root: JSONObject, key: String): String? {
        var found: String? = null
        walkObjects(root) { o ->
            if (found == null) {
                val v = o.opt(key)
                if (v is String && v.isNotEmpty()) found = v
            }
        }
        return found
    }

    /** Parse a WHOOP display number: strips "%", "ms", "bpm", spaces; tolerates "1,234". */
    private fun parseNumber(raw: String?): Double? {
        val t = raw?.trim() ?: return null
        if (t.isEmpty()) return null
        val cleaned = t.replace(",", "").replace("%", "").filter { it.isDigit() || it == '.' || it == '-' }
        return cleaned.toDoubleOrNull()
    }

    private fun optDouble(o: JSONObject, vararg keys: String): Double? {
        for (k in keys) {
            if (o.has(k) && !o.isNull(k)) {
                val v = o.optDouble(k, Double.NaN)
                if (!v.isNaN()) return v
            }
        }
        return null
    }

    /** "11:45 PM" / "1:54 AM" / "23:30" -> minute-of-day [0,1440); null if unparseable. */
    private fun parseClockMinute(raw: String): Int? {
        val s = raw.trim().uppercase()
        val ampm = when {
            s.endsWith("AM") -> false
            s.endsWith("PM") -> true
            else -> null
        }
        val body = s.removeSuffix("AM").removeSuffix("PM").trim()
        val parts = body.split(":")
        if (parts.size < 2) return null
        var h = parts[0].trim().toIntOrNull() ?: return null
        val m = parts[1].trim().toIntOrNull() ?: return null
        if (ampm != null) {
            if (h == 12) h = 0
            if (ampm) h += 12
        }
        if (h !in 0..23 || m !in 0..59) return null
        return h * 60 + m
    }

    /** Order a night: pre-noon minutes belong to "tomorrow", so push them past 1440 (whoopsi logic). */
    private fun sortMinute(min: Int): Int = if (min < 720) min + 1440 else min

    /** ISO-8601 timestamp -> unix seconds, via the shared [WhoopTime] parser. */
    private fun parseIso(raw: String): Long? = WhoopTime.parseEpochSeconds(raw, 0)

    private fun isDate(s: String): Boolean =
        s.length == 10 && s[4] == '-' && s[7] == '-' &&
            s.substring(0, 4).all { it.isDigit() } &&
            s.substring(5, 7).all { it.isDigit() } &&
            s.substring(8, 10).all { it.isDigit() }

    private fun looksLikeDeepDiveDay(text: String): Boolean =
        text.contains("\"recovery\"") || text.contains("\"last_night\"") ||
            text.contains("SCORE_GAUGE") || text.contains("scrubber_style")

    private fun sumOrNull(vararg v: Double?): Double? {
        val present = v.filterNotNull()
        return if (present.isEmpty()) null else present.sum()
    }

    /** Stage-segments array `[{stage, min}]` (minutes), null if no stage data. Matches CSV importer. */
    private fun stagesJson(lightMin: Double?, deepMin: Double?, remMin: Double?, awakeMin: Double?): String? {
        if (lightMin == null && deepMin == null && remMin == null && awakeMin == null) return null
        val arr = JSONArray()
        fun seg(stage: String, min: Double?) {
            if (min != null) arr.put(JSONObject().put("stage", stage).put("min", min))
        }
        seg("light", lightMin); seg("deep", deepMin); seg("rem", remMin); seg("awake", awakeMin)
        return if (arr.length() == 0) null else arr.toString()
    }

    // MARK: - Locate + load JSON

    private fun loadJsonData(context: Context, uri: Uri): Map<String, ByteArray> {
        val result = LinkedHashMap<String, ByteArray>()
        val firstBytes: ByteArray = context.contentResolver.openInputStream(uri)?.use { it.readAllCappedJson(MAX_ENTRY_BYTES) }
            ?: throw IllegalStateException("Could not open input stream for $uri")

        if (looksLikeZip(firstBytes)) {
            firstBytes.inputStream().use { raw ->
                ZipInputStream(raw).use { zis ->
                    var entry = zis.nextEntry
                    while (entry != null) {
                        if (!entry.isDirectory) {
                            val name = entry.name
                            if (name.lowercase().endsWith(".json") && entry.size <= MAX_ENTRY_BYTES) {
                                val bytes = zis.readEntryCappedJson(MAX_ENTRY_BYTES)
                                if (bytes != null && bytes.isNotEmpty() && !result.containsKey(name)) {
                                    result[name] = bytes
                                }
                            }
                        }
                        zis.closeEntry()
                        entry = zis.nextEntry
                    }
                }
            }
            if (result.isNotEmpty()) return result
        }

        // Single JSON file. Key it by display name so routing can use the filename.
        val name = displayName(context, uri) ?: "data.json"
        result[name] = firstBytes
        return result
    }

    private fun looksLikeZip(bytes: ByteArray): Boolean =
        bytes.size >= 4 &&
            bytes[0] == 0x50.toByte() && bytes[1] == 0x4B.toByte() &&
            bytes[2] == 0x03.toByte() && bytes[3] == 0x04.toByte()

    private fun displayName(context: Context, uri: Uri): String? {
        try {
            context.contentResolver.query(uri, null, null, null, null)?.use { c ->
                val idx = c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (idx >= 0 && c.moveToFirst()) {
                    val n = c.getString(idx)
                    if (!n.isNullOrEmpty()) return n
                }
            }
        } catch (_: Exception) {
        }
        return uri.lastPathSegment
    }
}

private fun InputStream.readAllCappedJson(cap: Long): ByteArray {
    val buffer = ByteArrayOutputStream(64 * 1024)
    val chunk = ByteArray(64 * 1024)
    var total = 0L
    while (true) {
        val n = read(chunk)
        if (n < 0) break
        total += n
        if (total > cap) throw IllegalStateException("Input exceeds $cap bytes")
        buffer.write(chunk, 0, n)
    }
    return buffer.toByteArray()
}

private fun ZipInputStream.readEntryCappedJson(cap: Long): ByteArray? {
    val buffer = ByteArrayOutputStream(64 * 1024)
    val chunk = ByteArray(64 * 1024)
    var total = 0L
    while (true) {
        val n = read(chunk)
        if (n < 0) break
        total += n
        if (total > cap) return null
        buffer.write(chunk, 0, n)
    }
    return buffer.toByteArray()
}
