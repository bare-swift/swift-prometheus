// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Internal pure-function namespace for Prometheus text-format exposition.
/// Full implementation in Task 13.
enum Exposition {
    static func encode(_ entry: MetricsRegistry.FamilyEntry) -> String {
        switch entry {
        case .counter(let f):   return "# stub counter \(f.name)\n"
        case .gauge(let f):     return "# stub gauge \(f.name)\n"
        case .histogram(let f): return "# stub histogram \(f.name)\n"
        }
    }
}
