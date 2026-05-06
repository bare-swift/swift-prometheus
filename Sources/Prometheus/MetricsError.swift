// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by ``MetricsRegistry`` and the metric types.
public enum MetricsError: Error, Equatable, Sendable {
    /// Metric name doesn't match `[a-zA-Z_:][a-zA-Z0-9_:]*`.
    case invalidName(String)

    /// Label name doesn't match `[a-zA-Z_][a-zA-Z0-9_]*`, or starts with `__`.
    case invalidLabelName(String)

    /// A counter / gauge / histogram with this name was already registered.
    case duplicateRegistration(String)

    /// `LabeledMetric.with(_:)` was called with a label set whose keys don't
    /// match the family's static label names.
    case wrongLabels

    /// Bucket array is empty, contains NaN, isn't strictly increasing, or has
    /// `+Inf` in a non-final position.
    case invalidBuckets

    /// `Counter.inc(by:)` was called with a negative amount.
    case negativeIncrement
}
