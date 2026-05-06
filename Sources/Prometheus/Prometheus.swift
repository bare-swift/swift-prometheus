// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Sendable, Foundation-free Prometheus metrics + text-format exposition.
///
/// Standalone — no `swift-metrics` dependency, no HTTP server. The public
/// surface is the ``MetricsRegistry`` plus the metric reference types
/// ``Counter``, ``Gauge``, and ``Histogram``.
public enum Prometheus: Sendable {}
