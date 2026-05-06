// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Synchronization

/// Bucketed Double observations + cumulative sum + count.
public final class Histogram: AnyMetric, @unchecked Sendable {
    /// Internal holder so we can store ~Copyable `Atomic` values in an array.
    final class AtomicCounter: @unchecked Sendable {
        let atomic: Atomic<UInt64> = Atomic(0)
        init() {}
    }

    /// Validated, canonicalized upper bounds (always ends with `+Inf`).
    public let upperBounds: [Double]
    private let perBucket: [AtomicCounter]
    private let _count: Atomic<UInt64> = Atomic(0)
    private let _sumBits: Atomic<UInt64> = Atomic(0)

    public init(buckets: [Double]) throws(MetricsError) {
        let canonical = try Validation.validateAndCanonicalizeBuckets(buckets)
        self.upperBounds = canonical
        self.perBucket = canonical.map { _ in AtomicCounter() }
    }

    public func observe(_ value: Double) {
        for i in 0..<upperBounds.count {
            if value <= upperBounds[i] {
                perBucket[i].atomic.add(1, ordering: .relaxed)
                break
            }
        }
        _count.add(1, ordering: .relaxed)
        var current: UInt64 = _sumBits.load(ordering: .relaxed)
        while true {
            let asDouble: Double = Double(bitPattern: current)
            let next: UInt64 = (asDouble + value).bitPattern
            let (exchanged, original) = _sumBits.compareExchange(
                expected: current, desired: next,
                successOrdering: .relaxed, failureOrdering: .relaxed)
            if exchanged { return }
            current = original
        }
    }

    public var count: UInt64 {
        _count.load(ordering: .relaxed)
    }

    public var sum: Double {
        Double(bitPattern: _sumBits.load(ordering: .relaxed))
    }

    public var bucketCounts: [(upperBound: Double, count: UInt64)] {
        var cumulative: UInt64 = 0
        var out: [(upperBound: Double, count: UInt64)] = []
        out.reserveCapacity(upperBounds.count)
        for i in 0..<upperBounds.count {
            let bucketCount: UInt64 = perBucket[i].atomic.load(ordering: .relaxed)
            cumulative &+= bucketCount
            out.append((upperBounds[i], cumulative))
        }
        return out
    }
}
