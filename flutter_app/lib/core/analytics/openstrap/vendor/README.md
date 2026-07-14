# Vendored: OpenStrap analytics (MIT)

A minimal, unmodified subset of [`OpenStrap/analytics`](https://github.com/OpenStrap/analytics)
(`openstrap_analytics`), MIT-licensed, Copyright (c) 2026 OpenStrap. Full license in
[`LICENSE`](LICENSE).

Used by `../openstrap_engine.dart` (the "OpenStrap" analysis engine) to score HRV
(Lipponen–Tarvainen RR correction → Task-Force RMSSD), respiratory rate (RSA
Lomb–Scargle) and lnRMSSD readiness (Plews) over the SAME raw strap stream our own
engine uses. Pure Dart, `dart:math` only — no I/O, no deps.

Files: `util.dart`, `types.dart`, `foundations/{fusion,rr_correction}.dart`,
`clinical/{hrv_time,readiness_lnrmssd}.dart`, `respiration/resp_rate.dart`.
