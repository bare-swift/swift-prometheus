// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Synchronization

/// One metric family, indexed by label values. Holds the metric metadata
/// (name, help, label-name list) and a `Labels → instance` map.
public final class LabeledMetric<M: AnyMetric>: @unchecked Sendable {
    public let name: String
    public let help: String
    public let labelNames: [String]
    /// Factory that builds a fresh instance for a given label set.
    private let factory: @Sendable (Labels) -> M
    private let instances: Mutex<[Labels: M]>

    public init(
        name: String,
        help: String,
        labelNames: [String],
        factory: @escaping @Sendable (Labels) -> M
    ) {
        self.name = name
        self.help = help
        self.labelNames = labelNames
        self.factory = factory
        self.instances = Mutex([:])
    }

    /// Get-or-create the metric instance for `labels`.
    public func with(_ labels: Labels) throws(MetricsError) -> M {
        let givenKeys: Set<String> = Set(labels.pairs.map(\.key))
        let expectedKeys: Set<String> = Set(labelNames)
        guard givenKeys == expectedKeys else { throw .wrongLabels }
        return instances.withLock { dict -> M in
            if let existing = dict[labels] {
                return existing
            }
            let fresh: M = factory(labels)
            dict[labels] = fresh
            return fresh
        }
    }

    /// Convenience for unlabeled families.
    public var withoutLabels: M {
        get throws(MetricsError) {
            try with(Labels.empty)
        }
    }

    /// Internal: snapshot the current (labels, instance) pairs for exposition.
    func snapshot() -> [(Labels, M)] {
        instances.withLock { dict in
            dict.sorted { lhs, rhs in
                let lhsKey: String = lhs.key.pairs.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
                let rhsKey: String = rhs.key.pairs.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
                return lhsKey < rhsKey
            }.map { ($0.key, $0.value) }
        }
    }
}
