/// PII scrubbing for the SHAREABLE strap log (upstream #445).
///
/// The strap log exists to be handed to someone else: the device screen renders it and offers a
/// "copy" action whose whole purpose is pasting the trace into a bug report. Two of the things the
/// BLE path naturally logs are personal identifiers of the user's own hardware:
///
///  • the **Bluetooth MAC** — on Android `BluetoothDevice.remoteId` IS the MAC, a stable
///    device-unique identifier that survives reinstalls and is usable for cross-service tracking, and
///  • the **WHOOP serial** — a WHOOP advertises as `WHOOP 4C1594026`, so every "Strap found: …" line
///    carries the serial printed on the band.
///
/// Neither is needed to read a trace, so both are masked at the log SINK rather than at each call
/// site. Sink-level is load-bearing: a call site that forgets to mask is the normal failure mode
/// (there are ~60 `_log(...)` calls, and any future one is a fresh chance to leak), whereas a scrubber
/// on the one path into the ring buffer cannot be bypassed by a line that has not been written yet.
/// It also masks BOTH the rendered log and the copied text from one place, because both read the same
/// buffer. Twin of the Kotlin file-scope `redactStrapLogPii` in `WhoopBleClient.kt`.
///
/// This is NOT a second implementation of [BondRefusalGiveUp.opaqueId], and the two do not overlap:
/// `opaqueId` hashes a KNOWN device id at ONE call site to mint a stable pseudonym the epitaph can
/// name ("the strap [a1b2c3d4]"), so two straps stay tellable apart across a log. This scrubber
/// rewrites UNKNOWN, arbitrary line text that nobody hashed. Neither can do the other's job, and
/// upstream ships both for exactly that reason. They compose cleanly: an `opaqueId` token is bare hex
/// with no colons and no `WHOOP <digits>`, so it passes through this scrubber untouched.
///
/// Pure — no BLE import, no platform, no radio — so the whole policy is unit-testable off-device
/// (the project rule forbids launching the app to verify anything), which is also precisely why
/// upstream kept it at file scope instead of as a client method.
library;

/// A full 6-octet MAC, capturing ONLY the first and last octet — the two we keep.
///
/// Why keep any: a completely blanked MAC makes a log unreadable when two straps appear in it (which
/// is the whole diagnostic point of a scan trace). The first octet is part of the OUI, i.e. it
/// identifies the VENDOR, not the user; the last octet is 8 bits of the device-unique tail, enough to
/// tell two devices apart in one log and far too little to identify or track anyone. The four unique
/// middle octets — the identifying part — never survive.
final RegExp _macRe = RegExp(
  r'([0-9A-Fa-f]{2}):[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:([0-9A-Fa-f]{2})',
);

/// A WHOOP advertised name carrying the band's serial: `WHOOP ` then a digit-led alphanumeric run of
/// 6+ characters (`WHOOP 4C1594026`).
///
/// The length + digit-led shape is what separates a serial from the MODEL names that legitimately
/// appear all over this log and must survive: `WHOOP 4.0` and `WHOOP 5·MG` break on the non-alphanumeric
/// (`.` / `·`) before the run is long enough, `WHOOP 5/MG` on the `/`, and the family fallbacks
/// `WHOOP 4` / `WHOOP 5` are a single digit. Scrubbing those would strip the model out of every line
/// and cost the trace the one fact it most needs.
final RegExp _whoopSerialRe = RegExp(r'WHOOP (\d[0-9A-Za-z]{5,})');

/// Mask Bluetooth MACs and WHOOP serials in one strap-log line.
///
/// TOTAL — never throws, for any input. A redaction failure returns a placeholder rather than
/// falling back to the raw line, because the two ways this can fail are opposite kinds of bad and
/// only one is acceptable: leaking the un-redacted line defeats the entire point, while withholding
/// one line costs a trace one line. Upstream learned the throwing half the hard way — their
/// replacement string referenced a capture group that did not exist, so the moment any raw MAC
/// reached the sink the scrubber threw and aborted the caller's whole strap activation (#421), then
/// crashed the app on every Bluetooth-on reconnect (#453). Dart's [String.replaceAllMapped] takes the
/// groups from the match object rather than parsing `$n` out of a replacement string, so that
/// specific bug is not expressible here; the guard stays anyway, since "the log scrubber can break
/// the BLE path" is the failure mode worth designing out, not just that one instance of it.
String redactStrapLogPii(String line) {
  try {
    return line
        .replaceAllMapped(_macRe, (m) => '${m.group(1)}:••:••:••:••:${m.group(2)}')
        .replaceAll(_whoopSerialRe, 'WHOOP <serial>');
  } catch (_) {
    return '[redaction error - line withheld]';
  }
}
