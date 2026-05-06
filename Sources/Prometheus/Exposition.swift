// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Internal pure-function namespace for Prometheus text-format exposition.
enum Exposition {
    static func encode(_ entry: MetricsRegistry.FamilyEntry) -> String {
        switch entry {
        case .counter(let family):
            return encodeCounter(family)
        case .gauge(let family):
            return encodeGauge(family)
        case .histogram(let family):
            return encodeHistogram(family)
        }
    }

    static func encodeCounter(_ family: LabeledMetric<Counter>) -> String {
        var out: String = ""
        out.append("# HELP \(family.name) \(escapeHelp(family.help))\n")
        out.append("# TYPE \(family.name) counter\n")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            out.append("\(family.name)\(formatLabels(labels)) \(formatDouble(instance.value))\n")
        }
        if snap.isEmpty && family.labelNames.isEmpty {
            out.append("\(family.name) 0\n")
        }
        out.append("\n")
        return out
    }

    static func encodeGauge(_ family: LabeledMetric<Gauge>) -> String {
        var out: String = ""
        out.append("# HELP \(family.name) \(escapeHelp(family.help))\n")
        out.append("# TYPE \(family.name) gauge\n")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            out.append("\(family.name)\(formatLabels(labels)) \(formatDouble(instance.value))\n")
        }
        if snap.isEmpty && family.labelNames.isEmpty {
            out.append("\(family.name) 0\n")
        }
        out.append("\n")
        return out
    }

    static func encodeHistogram(_ family: LabeledMetric<Histogram>) -> String {
        var out: String = ""
        out.append("# HELP \(family.name) \(escapeHelp(family.help))\n")
        out.append("# TYPE \(family.name) histogram\n")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            for (upperBound, count) in instance.bucketCounts {
                let leLabel: Labels = mergeLeLabel(into: labels, le: formatLeBound(upperBound))
                out.append("\(family.name)_bucket\(formatLabels(leLabel)) \(count)\n")
            }
            out.append("\(family.name)_sum\(formatLabels(labels)) \(formatDouble(instance.sum))\n")
            out.append("\(family.name)_count\(formatLabels(labels)) \(instance.count)\n")
        }
        out.append("\n")
        return out
    }

    static func formatLabels(_ labels: Labels) -> String {
        if labels.pairs.isEmpty { return "" }
        var out: String = "{"
        var first: Bool = true
        for pair in labels.pairs {
            if !first { out.append(",") }
            first = false
            out.append(pair.key)
            out.append("=\"")
            out.append(escapeLabelValue(pair.value))
            out.append("\"")
        }
        out.append("}")
        return out
    }

    static func formatDouble(_ v: Double) -> String {
        if v == .infinity { return "+Inf" }
        if v == -.infinity { return "-Inf" }
        if v.isNaN { return "NaN" }
        return String(v)
    }

    static func formatLeBound(_ v: Double) -> String {
        formatDouble(v)
    }

    static func mergeLeLabel(into labels: Labels, le: String) -> Labels {
        var pairs: [(String, String)] = labels.pairs.map { ($0.key, $0.value) }
        pairs.append(("le", le))
        return Labels(pairs)
    }

    static func escapeHelp(_ s: String) -> String {
        var out: String = ""
        out.reserveCapacity(s.utf8.count)
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\\": out.append("\\\\")
            case "\n": out.append("\\n")
            default:   out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    static func escapeLabelValue(_ s: String) -> String {
        var out: String = ""
        out.reserveCapacity(s.utf8.count)
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\\": out.append("\\\\")
            case "\"": out.append("\\\"")
            case "\n": out.append("\\n")
            default:   out.unicodeScalars.append(scalar)
            }
        }
        return out
    }
}
