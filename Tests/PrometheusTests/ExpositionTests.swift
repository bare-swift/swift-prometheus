// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Exposition (text-format)")
struct ExpositionTests {
    @Test("unlabeled counter renders HELP, TYPE, single sample")
    func unlabeledCounter() throws {
        let r = MetricsRegistry()
        let c = try r.counter(name: "http_requests_total", help: "Total HTTP requests.")
        let inst = try c.withoutLabels
        inst.inc()
        inst.inc()
        let body = r.exposition()
        #expect(body.contains("# HELP http_requests_total Total HTTP requests."))
        #expect(body.contains("# TYPE http_requests_total counter"))
        #expect(body.contains("http_requests_total 2.0"))
    }

    @Test("labeled counter renders one sample per label set, sorted")
    func labeledCounter() throws {
        let r = MetricsRegistry()
        let c = try r.counter(
            name: "errors_total",
            help: "Errors by method and status.",
            labels: ["method", "status"]
        )
        try c.with(["method": "POST", "status": "500"]).inc()
        try c.with(["method": "GET", "status": "200"]).inc()
        try c.with(["method": "GET", "status": "200"]).inc()
        let body = r.exposition()
        #expect(body.contains(#"errors_total{method="GET",status="200"} 2.0"#))
        #expect(body.contains(#"errors_total{method="POST",status="500"} 1.0"#))
        // Ordering: GET row should appear before POST row.
        if let getIdx = body.range(of: #"method="GET""#)?.lowerBound,
           let postIdx = body.range(of: #"method="POST""#)?.lowerBound {
            #expect(getIdx < postIdx)
        }
    }

    @Test("gauge renders TYPE gauge")
    func gauge() throws {
        let r = MetricsRegistry()
        let g = try r.gauge(name: "in_flight_requests", help: "Currently-handled requests.")
        let inst = try g.withoutLabels
        inst.set(3.0)
        let body = r.exposition()
        #expect(body.contains("# TYPE in_flight_requests gauge"))
        #expect(body.contains("in_flight_requests 3.0"))
    }

    @Test("histogram renders _bucket / _sum / _count series")
    func histogram() throws {
        let r = MetricsRegistry()
        let h = try r.histogram(
            name: "request_duration_seconds",
            help: "Request latency.",
            buckets: [0.1, 0.5, 1.0]
        )
        let inst = try h.withoutLabels
        inst.observe(0.05)
        inst.observe(0.3)
        inst.observe(2.0)
        let body = r.exposition()
        #expect(body.contains("# TYPE request_duration_seconds histogram"))
        #expect(body.contains(#"request_duration_seconds_bucket{le="0.1"} 1"#))
        #expect(body.contains(#"request_duration_seconds_bucket{le="0.5"} 2"#))
        #expect(body.contains(#"request_duration_seconds_bucket{le="1.0"} 2"#))
        #expect(body.contains(#"request_duration_seconds_bucket{le="+Inf"} 3"#))
        #expect(body.contains("request_duration_seconds_count 3"))
        // Sum should be 0.05 + 0.3 + 2.0 = 2.35 (within float precision).
        #expect(body.contains("request_duration_seconds_sum 2.35"))
    }

    @Test("label values escape backslash, double-quote, and newline")
    func labelEscaping() throws {
        let r = MetricsRegistry()
        let c = try r.counter(
            name: "weird",
            help: "Edge cases.",
            labels: ["v"]
        )
        // Real backslash, real double-quote, and real newline in the label value.
        try c.with(["v": "back\\slash and \"quote\" and\nnewline"]).inc()
        let body = r.exposition()
        // Backslash → \\, double-quote → \", newline → \n
        #expect(body.contains(#"weird{v="back\\slash and \"quote\" and\nnewline"} 1.0"#))
    }

    @Test("help text escapes backslash and newline")
    func helpEscaping() throws {
        let r = MetricsRegistry()
        _ = try r.counter(name: "x", help: "line1\nline2 with \\ backslash")
        let body = r.exposition()
        #expect(body.contains(#"# HELP x line1\nline2 with \\ backslash"#))
    }
}
