# swift-prometheus

Sendable, Foundation-free Prometheus metrics + text-format `/metrics` exposition for Swift 6.

Standalone — no `swift-metrics` dependency, no HTTP server. Pair with whatever you already use for serving.

Translated from [`prometheus-client`](https://crates.io/crates/prometheus-client) (Rust). Conforms to the [Prometheus text exposition format](https://prometheus.io/docs/instrumenting/exposition_formats/).

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-prometheus.git", from: "0.1.0")
```

```swift
.product(name: "Prometheus", package: "swift-prometheus")
```

## Usage

```swift
import Prometheus

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

// Render for /metrics
let body = registry.exposition()
```

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-prometheus/>

## Source

Translated from the Rust crate [`prometheus-client`](https://crates.io/crates/prometheus-client).

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
