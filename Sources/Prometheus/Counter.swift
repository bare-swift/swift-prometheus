// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Synchronization

/// Monotonically increasing `Double` counter.
///
/// ``inc()`` is wait-free; ``inc(by:)`` is wait-free for non-negative
/// arguments and throws ``MetricsError/negativeIncrement`` otherwise.
public final class Counter: AnyMetric, @unchecked Sendable {
    private let bits: Atomic<UInt64> = Atomic(0)

    public init() {}

    public var value: Double {
        Double(bitPattern: bits.load(ordering: .relaxed))
    }

    public func inc() {
        var current: UInt64 = bits.load(ordering: .relaxed)
        while true {
            let asDouble: Double = Double(bitPattern: current)
            let next: UInt64 = (asDouble + 1.0).bitPattern
            let (exchanged, original) = bits.compareExchange(
                expected: current, desired: next,
                successOrdering: .relaxed, failureOrdering: .relaxed)
            if exchanged { return }
            current = original
        }
    }

    public func inc(by amount: Double) throws(MetricsError) {
        guard amount >= 0 else { throw .negativeIncrement }
        var current: UInt64 = bits.load(ordering: .relaxed)
        while true {
            let asDouble: Double = Double(bitPattern: current)
            let next: UInt64 = (asDouble + amount).bitPattern
            let (exchanged, original) = bits.compareExchange(
                expected: current, desired: next,
                successOrdering: .relaxed, failureOrdering: .relaxed)
            if exchanged { return }
            current = original
        }
    }
}
