// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Internal pure-function namespace for Prometheus text-format exposition.
/// In 0.2 this writes UTF-8 bytes directly into a `Bytes` buffer; the public
/// exposition entry point returns `Bytes` for callers to hand to HTTP transport.
enum Exposition {
    static func encode(_ entry: MetricsRegistry.FamilyEntry, into out: inout Bytes) {
        switch entry {
        case .counter(let family):   encodeCounter(family, into: &out)
        case .gauge(let family):     encodeGauge(family, into: &out)
        case .histogram(let family): encodeHistogram(family, into: &out)
        }
    }

    static func encodeCounter(_ family: LabeledMetric<Counter>, into out: inout Bytes) {
        appendLine(into: &out, "# HELP \(family.name) \(escapeHelp(family.help))")
        appendLine(into: &out, "# TYPE \(family.name) counter")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            appendLine(into: &out, "\(family.name)\(formatLabels(labels)) \(formatDouble(instance.value))")
        }
        if snap.isEmpty && family.labelNames.isEmpty {
            appendLine(into: &out, "\(family.name) 0")
        }
        out.append(0x0A)  // trailing blank-line separator
    }

    static func encodeGauge(_ family: LabeledMetric<Gauge>, into out: inout Bytes) {
        appendLine(into: &out, "# HELP \(family.name) \(escapeHelp(family.help))")
        appendLine(into: &out, "# TYPE \(family.name) gauge")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            appendLine(into: &out, "\(family.name)\(formatLabels(labels)) \(formatDouble(instance.value))")
        }
        if snap.isEmpty && family.labelNames.isEmpty {
            appendLine(into: &out, "\(family.name) 0")
        }
        out.append(0x0A)
    }

    static func encodeHistogram(_ family: LabeledMetric<Histogram>, into out: inout Bytes) {
        appendLine(into: &out, "# HELP \(family.name) \(escapeHelp(family.help))")
        appendLine(into: &out, "# TYPE \(family.name) histogram")
        let snap = family.snapshot()
        for (labels, instance) in snap {
            for (upperBound, count) in instance.bucketCounts {
                let leLabel: Labels = mergeLeLabel(into: labels, le: formatLeBound(upperBound))
                appendLine(into: &out, "\(family.name)_bucket\(formatLabels(leLabel)) \(count)")
            }
            appendLine(into: &out, "\(family.name)_sum\(formatLabels(labels)) \(formatDouble(instance.sum))")
            appendLine(into: &out, "\(family.name)_count\(formatLabels(labels)) \(instance.count)")
        }
        out.append(0x0A)
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

    /// Append a UTF-8 line plus a trailing `\n`. Used by all three encoders.
    private static func appendLine(into out: inout Bytes, _ line: String) {
        out.append(contentsOf: line.utf8)
        out.append(0x0A)  // '\n'
    }
}
