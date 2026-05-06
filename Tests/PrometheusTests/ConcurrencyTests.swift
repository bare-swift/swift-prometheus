// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Concurrency")
struct ConcurrencyTests {
    @Test("100 tasks × 1000 increments → counter.value == 100_000")
    func parallelCounterIncrement() async throws {
        let registry = MetricsRegistry()
        let family = try registry.counter(name: "test", help: "")
        let counter = try family.withoutLabels
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    for _ in 0..<1000 { counter.inc() }
                }
            }
        }
        #expect(counter.value == 100_000.0)
    }

    @Test("100 tasks × 1000 inc(by:1.5) → counter.value == 150_000.0")
    func parallelCounterIncBy() async throws {
        let registry = MetricsRegistry()
        let family = try registry.counter(name: "test", help: "")
        let counter = try family.withoutLabels
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    for _ in 0..<1000 {
                        try? counter.inc(by: 1.5)
                    }
                }
            }
        }
        #expect(abs(counter.value - 150_000.0) < 1e-6)
    }

    @Test("100 tasks × 1000 histogram observations → count == 100_000")
    func parallelHistogramObserve() async throws {
        let registry = MetricsRegistry()
        let family = try registry.histogram(
            name: "test", help: "", buckets: [1.0, 2.0, 5.0]
        )
        let h = try family.withoutLabels
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    for _ in 0..<1000 { h.observe(0.5) }
                }
            }
        }
        #expect(h.count == 100_000)
        #expect(abs(h.sum - 50_000.0) < 1e-6)
        let cumulative = h.bucketCounts.map(\.count)
        #expect(cumulative == [100_000, 100_000, 100_000, 100_000])
    }

    @Test("LabeledMetric.with(_:) is safe under concurrent access")
    func parallelLabeledAccess() async throws {
        let registry = MetricsRegistry()
        let family = try registry.counter(
            name: "test", help: "", labels: ["k"]
        )
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for _ in 0..<1000 {
                        guard let counter = try? family.with(["k": "v\(i % 3)"]) else { return }
                        counter.inc()
                    }
                }
            }
        }
        var total: Double = 0
        for v in 0..<3 {
            let inst = try family.with(["k": "v\(v)"])
            total += inst.value
        }
        #expect(total == 10_000.0)
    }
}
