// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Histogram")
struct HistogramTests {
    @Test("new histogram has count 0, sum 0")
    func empty() throws {
        let h = try Histogram(buckets: [0.1, 0.5, 1.0])
        #expect(h.count == 0)
        #expect(h.sum == 0.0)
        let counts = h.bucketCounts.map(\.count)
        #expect(counts == [0, 0, 0, 0])
    }

    @Test("observe routes to first bucket whose upper bound >= value")
    func bucketRouting() throws {
        let h = try Histogram(buckets: [0.1, 0.5, 1.0])
        h.observe(0.05)
        h.observe(0.3)
        h.observe(0.5)
        h.observe(0.7)
        h.observe(2.0)
        #expect(h.count == 5)
        #expect(abs(h.sum - 3.55) < 1e-12)
        let cumulative = h.bucketCounts.map(\.count)
        #expect(cumulative == [1, 3, 4, 5])
    }

    @Test("custom buckets without explicit +Inf get +Inf appended")
    func autoAppendInf() throws {
        let h = try Histogram(buckets: [1.0, 2.0])
        let bounds = h.bucketCounts.map(\.upperBound)
        #expect(bounds == [1.0, 2.0, .infinity])
    }

    @Test("invalid buckets throw")
    func invalidBuckets() {
        #expect(throws: MetricsError.invalidBuckets) {
            try Histogram(buckets: [])
        }
        #expect(throws: MetricsError.invalidBuckets) {
            try Histogram(buckets: [0.5, 0.5])
        }
        #expect(throws: MetricsError.invalidBuckets) {
            try Histogram(buckets: [.nan])
        }
    }

    @Test("Histogram is Sendable")
    func sendable() throws {
        let h = try Histogram(buckets: [1.0])
        let _: any Sendable = h
    }
}
