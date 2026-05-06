// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Marker protocol for the generic ``LabeledMetric`` payload type.
/// ``Counter``, ``Gauge``, and ``Histogram`` conform.
public protocol AnyMetric: Sendable {}
