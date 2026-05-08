# swift-prometheus

Sendable, Foundation-free Prometheus metrics + text-format `/metrics` exposition for Swift 6.

Standalone — no `swift-metrics` dependency, no HTTP server. Pair with whatever you already use for serving.

Translated from [`prometheus-client`](https://crates.io/crates/prometheus-client) (Rust). Conforms to the [Prometheus text exposition format](https://prometheus.io/docs/instrumenting/exposition_formats/).

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-prometheus.git", from: "0.2.0")
```

```swift
.product(name: "Prometheus", package: "swift-prometheus")
```

## Usage

```swift
import Prometheus
import Bytes

let registry = MetricsRegistry()

// Unlabeled counter
let requests = try registry.counter(
    name: "http_requests_total",
    help: "Total HTTP requests served."
)
try requests.withoutLabels.inc()

// Labeled counter
let errors = try registry.counter(
    name: "http_errors_total",
    help: "Total HTTP errors.",
    labels: ["method", "status"]
)
try errors.with(["method": "POST", "status": "500"]).inc()

// Histogram with custom buckets
let latency = try registry.histogram(
    name: "request_duration_seconds",
    help: "Request latency in seconds.",
    buckets: [0.01, 0.05, 0.1, 0.5, 1.0]
)
try latency.withoutLabels.observe(0.123)

// Render the canonical Prometheus text exposition.
let payload: Bytes = registry.exposition()
// Hand `payload.storage` to your HTTP response body with
// Content-Type: text/plain; version=0.0.4
// To recover a String: String(decoding: payload.storage, as: UTF8.self)
```

## Migration from 0.1

`MetricsRegistry.exposition()` now returns `Bytes` (from
[swift-bytes](https://github.com/bare-swift/swift-bytes)) instead of `String`.
The wire format is unchanged byte-for-byte; only the return type differs.

```swift
// 0.1
let body: String = registry.exposition()
let utf8: [UInt8] = Array(body.utf8)

// 0.2
let bytes: Bytes = registry.exposition()
let utf8: ContiguousArray<UInt8> = bytes.storage  // already UTF-8
// Or: String(decoding: bytes.storage, as: UTF8.self) if you still want a String.
```

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-prometheus/>

## Source

Translated from the Rust crate [`prometheus-client`](https://crates.io/crates/prometheus-client).

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
