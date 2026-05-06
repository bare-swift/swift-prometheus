// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("LabeledMetric")
struct LabeledMetricTests {
    @Test("with(_:) is get-or-create: same Labels returns the same instance")
    func getOrCreate() throws {
        let family = LabeledMetric<Counter>(
            name: "test", help: "", labelNames: ["k"]
        ) { _ in Counter() }
        let a = try family.with(["k": "v"])
        let b = try family.with(["k": "v"])
        #expect(a === b)
    }

    @Test("different Labels yield different instances")
    func differentLabels() throws {
        let family = LabeledMetric<Counter>(
            name: "test", help: "", labelNames: ["k"]
        ) { _ in Counter() }
        let a = try family.with(["k": "1"])
        let b = try family.with(["k": "2"])
        #expect(a !== b)
    }

    @Test("with mismatched label keys throws .wrongLabels")
    func wrongLabels() {
        let family = LabeledMetric<Counter>(
            name: "test", help: "", labelNames: ["method", "status"]
        ) { _ in Counter() }
        #expect(throws: MetricsError.wrongLabels) {
            try family.with(["method": "GET"])
        }
        #expect(throws: MetricsError.wrongLabels) {
            try family.with(["method": "GET", "code": "200"])
        }
        #expect(throws: MetricsError.wrongLabels) {
            try family.with(["method": "GET", "status": "200", "extra": "x"])
        }
    }

    @Test("withoutLabels works for unlabeled families")
    func withoutLabels() throws {
        let family = LabeledMetric<Counter>(
            name: "test", help: "", labelNames: []
        ) { _ in Counter() }
        let a = try family.withoutLabels
        let b = try family.withoutLabels
        #expect(a === b)
    }

    @Test("withoutLabels on a labeled family throws")
    func withoutLabelsOnLabeled() {
        let family = LabeledMetric<Counter>(
            name: "test", help: "", labelNames: ["k"]
        ) { _ in Counter() }
        #expect(throws: MetricsError.wrongLabels) {
            _ = try family.withoutLabels
        }
    }
}
