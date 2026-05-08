// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Synchronization

/// Top-level metrics collector. Register counter / gauge / histogram families
/// at startup; serve text-format exposition from ``exposition()`` at scrape time.
public final class MetricsRegistry: @unchecked Sendable {
    enum FamilyEntry: Sendable {
        case counter(LabeledMetric<Counter>)
        case gauge(LabeledMetric<Gauge>)
        case histogram(LabeledMetric<Histogram>)

        var name: String {
            switch self {
            case .counter(let f):   return f.name
            case .gauge(let f):     return f.name
            case .histogram(let f): return f.name
            }
        }
    }

    private let families: Mutex<[FamilyEntry]>

    public init() {
        self.families = Mutex([])
    }

    public static let defaultBuckets: [Double] = [
        0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10
    ]

    public func counter(
        name: String, help: String, labels: [String] = []
    ) throws(MetricsError) -> LabeledMetric<Counter> {
        try Validation.validateMetricName(name)
        for ln in labels { try Validation.validateLabelName(ln) }
        return try families.withLock { list throws(MetricsError) -> LabeledMetric<Counter> in
            for e in list where e.name == name {
                throw .duplicateRegistration(name)
            }
            let f = LabeledMetric<Counter>(
                name: name, help: help, labelNames: labels
            ) { _ in Counter() }
            list.append(.counter(f))
            return f
        }
    }

    public func gauge(
        name: String, help: String, labels: [String] = []
    ) throws(MetricsError) -> LabeledMetric<Gauge> {
        try Validation.validateMetricName(name)
        for ln in labels { try Validation.validateLabelName(ln) }
        return try families.withLock { list throws(MetricsError) -> LabeledMetric<Gauge> in
            for e in list where e.name == name {
                throw .duplicateRegistration(name)
            }
            let f = LabeledMetric<Gauge>(
                name: name, help: help, labelNames: labels
            ) { _ in Gauge() }
            list.append(.gauge(f))
            return f
        }
    }

    public func histogram(
        name: String, help: String, labels: [String] = [],
        buckets: [Double] = MetricsRegistry.defaultBuckets
    ) throws(MetricsError) -> LabeledMetric<Histogram> {
        try Validation.validateMetricName(name)
        for ln in labels { try Validation.validateLabelName(ln) }
        let canonical: [Double] = try Validation.validateAndCanonicalizeBuckets(buckets)
        return try families.withLock { list throws(MetricsError) -> LabeledMetric<Histogram> in
            for e in list where e.name == name {
                throw .duplicateRegistration(name)
            }
            let f = LabeledMetric<Histogram>(
                name: name, help: help, labelNames: labels
            ) { _ in
                try! Histogram(buckets: canonical)
            }
            list.append(.histogram(f))
            return f
        }
    }

    /// Render the canonical Prometheus text-format exposition as UTF-8 bytes.
    ///
    /// Hand `payload.storage` to your HTTP response body, set
    /// `Content-Type: text/plain; version=0.0.4` per the Prometheus exposition
    /// spec, and respond. To recover a `String`,
    /// `String(decoding: payload.storage, as: UTF8.self)`.
    public func exposition() -> Bytes {
        let snapshot: [FamilyEntry] = families.withLock { Array($0) }
        var out: Bytes = Bytes(reservingCapacity: 256)
        for entry in snapshot {
            Exposition.encode(entry, into: &out)
        }
        return out
    }
}
