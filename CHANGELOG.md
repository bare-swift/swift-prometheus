# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-05-08

### Changed (BREAKING)
- `MetricsRegistry.exposition()` now returns `Bytes` (from [swift-bytes](https://github.com/bare-swift/swift-bytes)) instead of `String`. Wire format is unchanged byte-for-byte; only the return type differs.

  Migration:
  ```swift
  // 0.1
  let body: String = registry.exposition()
  let utf8: [UInt8] = Array(body.utf8)

  // 0.2
  let bytes: Bytes = registry.exposition()
  let utf8: ContiguousArray<UInt8> = bytes.storage  // already UTF-8
  // Or: String(decoding: bytes.storage, as: UTF8.self) if you still want a String.
  ```

### Added
- Dependency on `swift-bytes` 0.1.0.
- README migration section.
- Regression test asserting the `Bytes` return type of `exposition()`.

### Internal
- Rewrote `Exposition.swift` to write UTF-8 bytes into a `Bytes` buffer instead of concatenating Swift `String`s. Aligns swift-prometheus with swift-statsd 0.1 and swift-otlp-exporter 0.1 — all three observability-tier exporters now produce `Bytes` ready for transport.

### Notes
- This is a pre-1.0 minor-version bump; per the SemVer pre-1.0 convention (and the swift-tools / Cargo precedent), breaking changes are permitted in minor releases.
- macOS platform floor unchanged at 15+ (required for `Synchronization` per RFC-0003).

## [0.1.0] - 2026-05-06

### Added
- `MetricsRegistry` — registers counter / gauge / histogram families and renders the canonical Prometheus text-format exposition for `/metrics`.
- `Counter` — monotonic Double counter; `inc()`, `inc(by:)` (throws on negative), `value`. Wait-free atomic update via `Synchronization.Atomic`.
- `Gauge` — settable Double gauge; `set`, `inc`, `dec`, `inc(by:)`, `dec(by:)`, `value`.
- `Histogram` — bucketed Double observations; cumulative `bucketCounts`, `sum`, `count`. Buckets validated; `+Inf` auto-appended.
- `LabeledMetric<M>` — generic per-label-set get-or-create indexer; `with(_:)`, `withoutLabels`.
- `Labels` — Sendable, Hashable, dictionary-literal value type with sorted-pair representation.
- `MetricsError` — typed error enum (`invalidName`, `invalidLabelName`, `duplicateRegistration`, `wrongLabels`, `invalidBuckets`, `negativeIncrement`).
- DocC documentation, full README example, NOTICE crediting upstream `prometheus-client` and `prometheus` Rust crates.

### Platform
- macOS 15+ / Swift 6.0+. The package uses `Synchronization.Atomic` and `Synchronization.Mutex`, which require macOS 15 on Apple platforms.

### Limitations (out of scope for v0.1)
- `Summary` type (CKMS / sliding-window quantiles). Histograms cover the same observability ground for most users.
- swift-metrics integration. A separate sibling package.
- HTTP server / `/metrics` handler. Caller wires it.
- Native histograms (Prometheus 2.40+ exponential buckets).
- OpenMetrics format extras (`# UNIT`, `_created` series).
- Push gateway integration, callback gauges, process collectors.
