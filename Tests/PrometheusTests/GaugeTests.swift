// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Gauge")
struct GaugeTests {
    @Test("new gauge starts at 0")
    func zero() {
        let g = Gauge()
        #expect(g.value == 0.0)
    }

    @Test("set replaces the value")
    func setValue() {
        let g = Gauge()
        g.set(42.0)
        #expect(g.value == 42.0)
        g.set(-3.14)
        #expect(g.value == -3.14)
    }

    @Test("inc / dec adjusts by 1")
    func incDecOne() {
        let g = Gauge()
        g.inc(); g.inc(); g.inc()
        g.dec()
        #expect(g.value == 2.0)
    }

    @Test("inc(by:) / dec(by:) adjust by amount, allow negative")
    func incDecBy() {
        let g = Gauge()
        g.inc(by: 5.5)
        g.dec(by: 2.5)
        g.inc(by: -1.0)
        #expect(g.value == 2.0)
    }

    @Test("Gauge is Sendable")
    func sendable() {
        let _: any Sendable = Gauge()
    }
}
