# Test-parity exceptions

Per [RFC-0002](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0002-test-parity-policy.md), this file documents why some upstream test cases are not extracted as fixtures.

## Source: `prometheus-client` (Rust crate)

`prometheus-client` uses doctests for the API surface and integration tests
for HTTP server wiring.

The Swift translation:

- API behavior is captured by direct unit tests (`CounterTests.swift`,
  `GaugeTests.swift`, `HistogramTests.swift`, `LabeledMetricTests.swift`,
  `RegistryTests.swift`).
- Text-format exposition is verified against canonical hand-curated cases
  in `ExpositionTests.swift`. The Prometheus text format is unambiguous —
  a few representative cases (counter, gauge, histogram with labels,
  special characters in label values) cover the spec.
- Concurrency safety is verified by `ConcurrencyTests.swift`: parallel
  increments produce the exact expected total.

## Out of scope for v0.1 (no Swift counterpart)

- HTTP server / `/metrics` handler. Caller responsibility — documented in
  CHANGELOG.
- swift-metrics integration. Sibling package, not v0.1 of this one.
- Native histograms (Prometheus 2.40+ exponential buckets). Defer to v0.2.
- OpenMetrics format extras (`# UNIT`, `_created` series). Defer to v0.2.
- `Summary` type (CKMS / sliding-window quantiles). Defer to v0.2.
- Push gateway integration, callback gauges, process collectors.

## Refresh

When upstream releases new versions, re-read tests and add Swift
equivalents for any new cases. Record source commits here when refreshing:

- `prometheus-client`: tracked at upstream commit (record at next refresh)
