@testable import SwiftLintCore
@testable import SwiftLintFramework
import XCTest

extension CustomRulesTests {
    func testCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
    }

    func testSpecificCustomRuleTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    func testSpecificAndCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "\(customRuleIdentifier)"))
    }

    func testCustomRulesViolationAndViolationOfSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              let FORBIDDEN = 1
                              // swiftlint:disable:next \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].ruleIdentifier, customRuleIdentifier)
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    func testDisablingCustomRulesDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let FORBIDDEN = 1
                              """)

        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testMultipleSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let ALLOWED = 2
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testUnviolatedSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testViolatedSpecificAndGeneralCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2 custom_rules
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testSuperfluousDisableCommandWithMultipleCustomRules() throws {
        let customRules: [String: Any] = [
            "custom1": [
                "regex": "pattern",
                "match_kinds": "comment",
            ],
            "custom2": [
                "regex": "10",
                "match_kinds": "number",
            ],
            "custom3": [
                "regex": "100",
                "match_kinds": "number",
            ],
        ]

        let example = Example(
             """
             // swiftlint:disable custom1 custom3
             return 10
             """
        )

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 3)
        XCTAssertEqual(violations[0].ruleIdentifier, "custom2")
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "custom1"))
        XCTAssertTrue(violations[2].isSuperfluousDisableCommandViolation(for: "custom3"))
    }

    func testViolatedCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next dont_print
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testDisableAllDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next all
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testDisableAllAndDisableSpecificCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next all dont_print
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testNestedCustomRuleDisablesDoNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
        ]
        let example = Example("""
                               // swiftlint:disable rule1
                               // swiftlint:disable rule2
                               let pattern2 = ""
                               // swiftlint:enable rule2
                               let pattern1 = ""
                               // swiftlint:enable rule1
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testNestedAndOverlappingCustomRuleDisables() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
            "rule3": [
                "regex": "pattern3"
            ],
        ]
        let example = Example("""
                              // swiftlint:disable rule1
                              // swiftlint:disable rule2
                              // swiftlint:disable rule3
                              let pattern2 = ""
                              // swiftlint:enable rule2
                              // swiftlint:enable rule3
                              let pattern1 = ""
                              // swiftlint:enable rule1
                              """)
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "rule3"))
    }

    func testSuperfluousDisableRuleOrder() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
            "rule3": [
                "regex": "pattern3"
            ],
        ]
        let example = Example("""
                              // swiftlint:disable rule1
                              // swiftlint:disable rule2 rule3
                              // swiftlint:enable rule3 rule2
                              // swiftlint:disable rule2
                              // swiftlint:enable rule1
                              // swiftlint:enable rule2
                              """)
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 4)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "rule1"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "rule2"))
        XCTAssertTrue(violations[2].isSuperfluousDisableCommandViolation(for: "rule3"))
        XCTAssertTrue(violations[3].isSuperfluousDisableCommandViolation(for: "rule2"))
    }

    // MARK: - Private
    private func violations(forExample example: Example, customRules: [String: Any]) throws -> [StyleViolation] {
        let configDict: [String: Any] = [
            "only_rules": ["custom_rules", "superfluous_disable_command"],
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintFramework.Configuration(dict: configDict)
        return TestHelpers.violations(
            example.skipWrappingInCommentTest(),
            config: configuration
        )
    }
}

private extension StyleViolation {
    func isSuperfluousDisableCommandViolation(for ruleIdentifier: String) -> Bool {
        self.ruleIdentifier == SuperfluousDisableCommandRule.identifier &&
            reason.contains("SwiftLint rule '\(ruleIdentifier)' did not trigger a violation")
    }
}
