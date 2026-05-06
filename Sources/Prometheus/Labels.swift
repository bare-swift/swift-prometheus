// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Sendable, Hashable key/value labels for a metric instance.
///
/// Internally stored as an array of pairs sorted by key. Two ``Labels``
/// values with the same logical content compare equal and hash equal,
/// regardless of insertion order. Duplicate keys collapse last-wins.
public struct Labels: Sendable, Hashable, ExpressibleByDictionaryLiteral {
    public let pairs: [Pair]

    public struct Pair: Sendable, Hashable {
        public let key: String
        public let value: String
        public init(_ key: String, _ value: String) {
            self.key = key
            self.value = value
        }
    }

    public init(_ items: [(String, String)]) {
        var dict: [String: String] = [:]
        for (k, v) in items { dict[k] = v }
        self.pairs = dict.sorted { $0.key < $1.key }.map { Pair($0.key, $0.value) }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(elements)
    }

    public static let empty = Labels([])
}
