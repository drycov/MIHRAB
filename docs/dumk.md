# DUMK integration (phase 1)
Official docs: https://namaz.muftyat.kz/ru/namaz/api/
Use coordinates from /cities/ (not rounded local coordinates) with /prayer-times/{year}/{lat}/{lng}.
Actual response schema has not been verified. DumkClient fetches raw JSON only; no automatic import is enabled. OfficialDayCodec accepts normalized internal keys (fajr, sunrise, dhuhr, asr, maghrib, isha), not an assertion about the external schema. The cache requires a complete validated year and is not populated by the app yet. MWL remains the only active source. Next: verify city mapping and a real response, normalize it, add sync UI, and route countdown and reminders through the same repository. Cache uses SharedPreferences for this prototype; SQLite migration remains pending.
