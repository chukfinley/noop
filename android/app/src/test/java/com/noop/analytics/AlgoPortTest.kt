package com.noop.analytics

import com.noop.data.HrSample
import com.noop.data.RrInterval
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Tests for the additive whoopsi-ported analytics helpers (Ranks 1/2/6). Each is a NEW entry
 * point — the defaults of the existing functions are unchanged, which these tests also pin.
 */
class AlgoPortTest {

    private val dev = "my-whoop"

    // ── Rank 6: RMSSD successive-diff guard (default unchanged) ───────────────

    @Test
    fun rmssdRaw_defaultIsUnchanged() {
        // diffs 20, -10 -> sumSq 500 / (n-1=2) -> sqrt(250).
        val v = listOf(800.0, 820.0, 810.0)
        assertEquals(15.8114, HrvAnalyzer.rmssdRaw(v)!!, 1e-3)
        // Explicit null guard is identical to the no-arg call.
        assertEquals(HrvAnalyzer.rmssdRaw(v)!!, HrvAnalyzer.rmssdRaw(v, null)!!, 1e-12)
    }

    @Test
    fun rmssdRaw_dropsLargeSuccessiveJumps() {
        // A single 380/390 ms artifact dominates the unfiltered RMSSD; the |Δ|<200 guard removes it.
        val v = listOf(800.0, 820.0, 1200.0, 810.0)
        val unfiltered = HrvAnalyzer.rmssdRaw(v)!!
        val filtered = HrvAnalyzer.rmssdRaw(v, maxSuccessiveDiffMs = 200.0)!!
        assertTrue("artifact should inflate the raw value", unfiltered > 300.0)
        // Only the 20 ms diff survives -> sqrt(400/1) = 20.
        assertEquals(20.0, filtered, 1e-9)
    }

    // ── Rank 1: robust resting HR (P25+median blend) ─────────────────────────

    @Test
    fun restingHRRobust_blendsLowerQuartileAndMedian() {
        // 40 samples, bpm 50..89, one per minute across the window.
        val start = 1_000L
        val hr = (0 until 40).map { HrSample(dev, ts = start + it * 60L, bpm = 50 + it) }
        val end = start + 40 * 60L
        // p25 = 59.75, median = 69.5 -> mean 64.625 -> 65.
        assertEquals(65, RecoveryScorer.restingHRRobust(hr, start, end))
    }

    @Test
    fun restingHRRobust_fallsBackToMedianWhenSparse() {
        val start = 0L
        val hr = listOf(60, 62, 64).mapIndexed { i, b -> HrSample(dev, ts = i * 60L, bpm = b) }
        // < 30 samples -> plain median = 62.
        assertEquals(62, RecoveryScorer.restingHRRobust(hr, start, 10_000L))
    }

    // ── Rank 2: SWS-window HRV ────────────────────────────────────────────────

    @Test
    fun sessionAvgHRVSws_picksLowHrStableWindow() {
        val start = 0L
        val win = ArrayList<RrInterval>()
        // Window A (0..299): low RR / high HR, more variable — NOT slow-wave.
        for (i in 0 until 12) win.add(RrInterval(dev, ts = i * 20L, rrMs = if (i % 2 == 0) 600 else 650))
        // Window B (300..599): high RR / low HR, stable — slow-wave; RMSSD diffs ±10 -> 10 ms.
        for (i in 0 until 12) win.add(RrInterval(dev, ts = 300L + i * 20L, rrMs = if (i % 2 == 0) 1000 else 1010))
        val sws = SleepStager.sessionAvgHRVSws(start, 600L, win)
        assertNotNull(sws)
        assertEquals(10.0, sws!!, 1e-6)
    }
}
