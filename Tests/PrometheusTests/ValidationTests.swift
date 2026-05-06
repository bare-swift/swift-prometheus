// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import Prometheus

@Suite("Validation")
struct ValidationTests {
    @Test("validateMetricName accepts canonical names")
    func validNames() throws {
        for name in ["http_requests_total", "go_goroutines", "x", "_x", ":x", "x:y_2"] {
            try Validation.validateMetricName(name)
        }
    }

    @Test("validateMetricName rejects empty / leading-digit / illegal chars")
    func invalidNames() {
        let bad = ["", "1abc", "abc-def", "abc.def", "abc def"]
        for name in bad {
            #expect(throws: MetricsError.invalidName(name)) {
                try Validation.validateMetricName(name)
            }
        }
    }

    @Test("validateLabelName accepts canonical names")
    func validLabelNames() throws {
        for name in ["method", "status_code", "_x"] {
            try Validation.validateLabelName(name)
        }
    }

    @Test("validateLabelName rejects empty / leading-digit / colons / __ prefix")
    func invalidLabelNames() {
        let bad = ["", "1abc", "abc-def", "abc:def", "__reserved", "abc def"]
        for name in bad {
            #expect(throws: MetricsError.invalidLabelName(name)) {
                try Validation.validateLabelName(name)
            }
        }
    }

    @Test("validateBuckets accepts strictly-increasing finite buckets")
    func validBucketsPlain() throws {
        let result = try Validation.validateAndCanonicalizeBuckets([0.1, 0.5, 1.0])
        #expect(result == [0.1, 0.5, 1.0, .infinity])
    }

    @Test("validateBuckets accepts +Inf as final element")
    func validBucketsWithInf() throws {
        let result = try Validation.validateAndCanonicalizeBuckets([0.1, 0.5, .infinity])
        #expect(result == [0.1, 0.5, .infinity])
    }

    @Test("validateBuckets rejects empty array")
    func invalidEmpty() {
        #expect(throws: MetricsError.invalidBuckets) {
            try Validation.validateAndCanonicalizeBuckets([])
        }
    }

    @Test("validateBuckets rejects NaN")
    func invalidNaN() {
        #expect(throws: MetricsError.invalidBuckets) {
            try Validation.validateAndCanonicalizeBuckets([0.1, .nan, 1.0])
        }
    }

    @Test("validateBuckets rejects non-strictly-increasing")
    func invalidNotIncreasing() {
        #expect(throws: MetricsError.invalidBuckets) {
            try Validation.validateAndCanonicalizeBuckets([0.5, 0.5, 1.0])
        }
        #expect(throws: MetricsError.invalidBuckets) {
            try Validation.validateAndCanonicalizeBuckets([1.0, 0.5])
        }
    }

    @Test("validateBuckets rejects +Inf in non-final position")
    func invalidInfNotFinal() {
        #expect(throws: MetricsError.invalidBuckets) {
            try Validation.validateAndCanonicalizeBuckets([.infinity, 1.0])
        }
    }
}
