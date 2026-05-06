// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Counter")
struct CounterTests {
    @Test("new counter starts at 0")
    func zero() {
        let c = Counter()
        #expect(c.value == 0.0)
    }

    @Test("inc() increments by 1")
    func incOne() {
        let c = Counter()
        c.inc()
        c.inc()
        c.inc()
        #expect(c.value == 3.0)
    }

    @Test("inc(by:) accepts non-negative")
    func incBy() throws {
        let c = Counter()
        try c.inc(by: 2.5)
        try c.inc(by: 0.0)
        try c.inc(by: 7.5)
        #expect(c.value == 10.0)
    }

    @Test("inc(by:) throws on negative")
    func incNegative() {
        let c = Counter()
        #expect(throws: MetricsError.negativeIncrement) {
            try c.inc(by: -1.0)
        }
        #expect(c.value == 0.0)
    }

    @Test("Counter is Sendable")
    func sendable() {
        let _: any Sendable = Counter()
    }
}
