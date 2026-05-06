// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Labels")
struct LabelsTests {
    @Test("init from pairs preserves keys+values, sorted by key")
    func sortedRepresentation() {
        let l = Labels([("zebra", "3"), ("apple", "1"), ("mango", "2")])
        let keys: [String] = l.pairs.map(\.key)
        #expect(keys == ["apple", "mango", "zebra"])
        let values: [String] = l.pairs.map(\.value)
        #expect(values == ["1", "2", "3"])
    }

    @Test("dictionary literal init")
    func dictLiteral() {
        let l: Labels = ["b": "2", "a": "1"]
        #expect(l.pairs.map(\.key) == ["a", "b"])
        #expect(l.pairs.map(\.value) == ["1", "2"])
    }

    @Test("two Labels with same content (any order) are equal and hash equal")
    func equalityHash() {
        let a: Labels = ["status": "200", "method": "GET"]
        let b: Labels = ["method": "GET", "status": "200"]
        #expect(a == b)
        var set: Set<Labels> = [a]
        #expect(set.contains(b))
        set.insert(b)
        #expect(set.count == 1)
    }

    @Test("duplicate keys collapse last-wins")
    func duplicates() {
        let l = Labels([("k", "first"), ("k", "second")])
        #expect(l.pairs.count == 1)
        #expect(l.pairs[0].key == "k")
        #expect(l.pairs[0].value == "second")
    }

    @Test("empty Labels has no pairs")
    func emptyLabels() {
        #expect(Labels.empty.pairs.isEmpty)
        let l: Labels = [:]
        #expect(l.pairs.isEmpty)
        #expect(l == Labels.empty)
    }

    @Test("Labels is Sendable")
    func sendable() {
        let _: any Sendable = Labels.empty
    }
}
