// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("MetricsRegistry")
struct RegistryTests {
    @Test("counter, gauge, histogram register and return families")
    func registerAll() throws {
        let r = MetricsRegistry()
        let c = try r.counter(name: "c", help: "h")
        let g = try r.gauge(name: "g", help: "h")
        let hh = try r.histogram(name: "h", help: "h")
        try c.withoutLabels.inc()
        let gauge = try g.withoutLabels
        gauge.set(1.0)
        let hist = try hh.withoutLabels
        hist.observe(0.05)
        let _ = try g.withoutLabels
    }

    @Test("invalid name throws .invalidName")
    func invalidName() {
        let r = MetricsRegistry()
        #expect(throws: MetricsError.invalidName("1bad")) {
            try r.counter(name: "1bad", help: "")
        }
    }

    @Test("invalid label name throws .invalidLabelName")
    func invalidLabelName() {
        let r = MetricsRegistry()
        #expect(throws: MetricsError.invalidLabelName("__reserved")) {
            try r.counter(name: "ok", help: "", labels: ["__reserved"])
        }
        #expect(throws: MetricsError.invalidLabelName("1bad")) {
            try r.gauge(name: "ok", help: "", labels: ["1bad"])
        }
    }

    @Test("duplicate registration throws")
    func duplicate() throws {
        let r = MetricsRegistry()
        _ = try r.counter(name: "x", help: "")
        #expect(throws: MetricsError.duplicateRegistration("x")) {
            try r.counter(name: "x", help: "")
        }
        #expect(throws: MetricsError.duplicateRegistration("x")) {
            try r.gauge(name: "x", help: "")
        }
    }

    @Test("default histogram buckets have +Inf appended")
    func defaultBuckets() throws {
        let r = MetricsRegistry()
        let h = try r.histogram(name: "x", help: "")
        let inst = try h.withoutLabels
        #expect(inst.upperBounds.last == .infinity)
    }

    @Test("invalid buckets throw")
    func invalidBuckets() {
        let r = MetricsRegistry()
        #expect(throws: MetricsError.invalidBuckets) {
            try r.histogram(name: "x", help: "", buckets: [])
        }
    }
}
