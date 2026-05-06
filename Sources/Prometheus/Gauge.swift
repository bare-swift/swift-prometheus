// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Synchronization

/// Settable `Double` gauge. Supports `set`, `inc`, `dec`, including negative
/// adjustments (unlike Counter).
public final class Gauge: AnyMetric, @unchecked Sendable {
    private let bits: Atomic<UInt64> = Atomic(0)

    public init() {}

    public var value: Double {
        Double(bitPattern: bits.load(ordering: .relaxed))
    }

    public func set(_ newValue: Double) {
        bits.store(newValue.bitPattern, ordering: .relaxed)
    }

    public func inc() { adjust(by: 1.0) }
    public func dec() { adjust(by: -1.0) }
    public func inc(by amount: Double) { adjust(by: amount) }
    public func dec(by amount: Double) { adjust(by: -amount) }

    private func adjust(by amount: Double) {
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
