# ``Prometheus``

Sendable, Foundation-free Prometheus metrics for Swift 6.

## Overview

Standalone metric types — Counter, Gauge, Histogram — plus the text-format
exposition encoder for the `/metrics` endpoint. No `swift-metrics`
dependency, no HTTP server.

```swift
import Prometheus

let registry = MetricsRegistry()
let requests = try registry.counter(
    name: "http_requests_total",
    help: "Total HTTP requests."
)
try requests.withoutLabels.inc()

let body = registry.exposition()
```

## Topics

### Registry

- ``MetricsRegistry``
- ``MetricsRegistry/counter(name:help:labels:)``
- ``MetricsRegistry/gauge(name:help:labels:)``
- ``MetricsRegistry/histogram(name:help:labels:buckets:)``
- ``MetricsRegistry/exposition()``
- ``MetricsRegistry/defaultBuckets``

### Metric types

- ``Counter``
- ``Gauge``
- ``Histogram``
- ``LabeledMetric``
- ``Labels``
- ``AnyMetric``

### Errors

- ``MetricsError``
