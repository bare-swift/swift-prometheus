// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("MetricsError")
struct MetricsErrorTests {
    @Test("MetricsError is Sendable, Equatable, Error")
    func conformances() {
        let a: MetricsError = .invalidName("foo")
        let b: MetricsError = .invalidName("foo")
        let c: MetricsError = .invalidName("bar")
        let d: MetricsError = .invalidLabelName("x")
        #expect(a == b)
        #expect(a != c)
        #expect(a != d)
        let _: any Error = a
        let _: any Sendable = a
    }

    @Test("All six cases are distinguishable")
    func cases() {
        let xs: [MetricsError] = [
            .invalidName("x"),
            .invalidLabelName("x"),
            .duplicateRegistration("x"),
            .wrongLabels,
            .invalidBuckets,
            .negativeIncrement,
        ]
        for i in 0..<xs.count {
            for j in 0..<xs.count where i != j {
                #expect(xs[i] != xs[j])
            }
        }
    }
}
