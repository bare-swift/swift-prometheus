// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Internal pure-function namespace for Prometheus validation rules.
enum Validation {
    /// Metric name: `[a-zA-Z_:][a-zA-Z0-9_:]*`.
    static func validateMetricName(_ name: String) throws(MetricsError) {
        guard !name.isEmpty else { throw .invalidName(name) }
        var iter = name.unicodeScalars.makeIterator()
        guard let first = iter.next(), isMetricNameStart(first) else {
            throw .invalidName(name)
        }
        while let s = iter.next() {
            if !isMetricNameContinue(s) {
                throw .invalidName(name)
            }
        }
    }

    /// Label name: `[a-zA-Z_][a-zA-Z0-9_]*`. Names starting with `__` are
    /// rejected (reserved by Prometheus).
    static func validateLabelName(_ name: String) throws(MetricsError) {
        guard !name.isEmpty else { throw .invalidLabelName(name) }
        var iter = name.unicodeScalars.makeIterator()
        guard let first = iter.next(), isLabelNameStart(first) else {
            throw .invalidLabelName(name)
        }
        while let s = iter.next() {
            if !isLabelNameContinue(s) {
                throw .invalidLabelName(name)
            }
        }
        if name.hasPrefix("__") { throw .invalidLabelName(name) }
    }

    /// Validate buckets: non-empty, no NaN, strictly increasing, `+Inf` only
    /// final. Returns canonicalised buckets with `+Inf` appended if not present.
    static func validateAndCanonicalizeBuckets(_ buckets: [Double]) throws(MetricsError) -> [Double] {
        guard !buckets.isEmpty else { throw .invalidBuckets }
        for b in buckets {
            if b.isNaN { throw .invalidBuckets }
        }
        for i in 0..<(buckets.count - 1) {
            if buckets[i] == .infinity { throw .invalidBuckets }
        }
        for i in 1..<buckets.count {
            if !(buckets[i] > buckets[i - 1]) { throw .invalidBuckets }
        }
        if buckets.last == .infinity {
            return buckets
        }
        var out = buckets
        out.append(.infinity)
        return out
    }

    @inlinable
    static func isMetricNameStart(_ c: Unicode.Scalar) -> Bool {
        switch c.value {
        case 0x41...0x5A: return true
        case 0x61...0x7A: return true
        case 0x5F: return true
        case 0x3A: return true
        default: return false
        }
    }

    @inlinable
    static func isMetricNameContinue(_ c: Unicode.Scalar) -> Bool {
        if isMetricNameStart(c) { return true }
        return c.value >= 0x30 && c.value <= 0x39
    }

    @inlinable
    static func isLabelNameStart(_ c: Unicode.Scalar) -> Bool {
        switch c.value {
        case 0x41...0x5A: return true
        case 0x61...0x7A: return true
        case 0x5F: return true
        default: return false
        }
    }

    @inlinable
    static func isLabelNameContinue(_ c: Unicode.Scalar) -> Bool {
        if isLabelNameStart(c) { return true }
        return c.value >= 0x30 && c.value <= 0x39
    }
}
