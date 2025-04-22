import SourceKittenFramework
@testable import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import XCTest

final class CustomRulesTests: SwiftLintTestCase {
    private typealias Configuration = RegexConfiguration<CustomRules>

    private var testFile: SwiftLintFile { SwiftLintFile(path: "\(TestResources.path())/test.txt")! }

    func testCustomRuleConfigurationSetsCorrectlyWithMatchKinds() {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error",
            ],
        ]
        var comp = Configuration(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = "regex"
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.excludedMatchKinds = SyntaxKind.allKinds.subtracting([.comment])
        var compRules = CustomRulesConfiguration()
        compRules.customRuleConfigurations = [comp]
        do {
            var configuration = CustomRulesConfiguration()
            try configuration.apply(configuration: configDict)
            XCTAssertEqual(configuration, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCustomRuleConfigurationSetsCorrectlyWithExcludedMatchKinds() {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "excluded_match_kinds": "comment",
                "severity": "error",
            ],
        ]
        var comp = Configuration(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = "regex"
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.excludedMatchKinds = Set<SyntaxKind>([.comment])
        var compRules = CustomRulesConfiguration()
        compRules.customRuleConfigurations = [comp]
        do {
            var configuration = CustomRulesConfiguration()
            try configuration.apply(configuration: configDict)
            XCTAssertEqual(configuration, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCustomRuleConfigurationThrows() {
        let config = 17
        var customRulesConfig = CustomRulesConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try customRulesConfig.apply(configuration: config)
        }
    }

    func testCustomRuleConfigurationMatchKindAmbiguity() {
        let configDict = [
            "name": "MyCustomRule",
            "message": "Message",
            "regex": "regex",
            "match_kinds": "comment",
            "excluded_match_kinds": "argument",
            "severity": "error",
        ]

        var configuration = Configuration(identifier: "my_custom_rule")
        let expectedError = Issue.genericWarning(
            "The configuration keys 'match_kinds' and 'excluded_match_kinds' cannot appear at the same time."
        )
        checkError(expectedError) {
            try configuration.apply(configuration: configDict)
        }
    }

    func testCustomRuleConfigurationIgnoreInvalidRules() throws {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error",
            ],
            "invalid_rule": ["name": "InvalidRule"], // missing `regex`
        ]
        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)

        XCTAssertEqual(customRulesConfig.customRuleConfigurations.count, 1)

        let identifier = customRulesConfig.customRuleConfigurations.first?.identifier
        XCTAssertEqual(identifier, "my_custom_rule")
    }

    func testCustomRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = SwiftLintFile(contents: "// My file with\n// a pattern")
        XCTAssertEqual(
            customRules.validate(file: file),
            [
                StyleViolation(
                    ruleDescription: regexConfig.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 6),
                    reason: regexConfig.message
                ),
            ]
        )
    }

    func testLocalDisableCustomRule() throws {
        let customRules: [String: Any] = [
            "custom": [
                "regex": "pattern",
                "match_kinds": "comment",
            ],
        ]
        let example = Example("//swiftlint:disable custom \n// file with a pattern")
        let configDict: [String: Any] = [
            "only_rules": ["custom_rules", "superfluous_disable_command"],
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintFramework.Configuration(dict: configDict)
        let violations = TestHelpers.violations(
            example.skipWrappingInCommentTest(),
            config: configuration
        )
        XCTAssertTrue(violations.isEmpty)
    }

    func testLocalDisableCustomRuleWithMultipleRules() {
        let (configs, customRules) = getCustomRulesWithTwoRules()
        let file = SwiftLintFile(contents: "//swiftlint:disable \(configs.1.identifier) \n// file with a pattern")
        XCTAssertEqual(
            customRules.validate(file: file),
            [
                StyleViolation(
                    ruleDescription: configs.0.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 16),
                    reason: configs.0.message
                ),
            ]
        )
    }

    func testCustomRulesIncludedDefault() {
        // Violation detected when included is omitted.
        let (_, customRules) = getCustomRules()
        let violations = customRules.validate(file: testFile)
        XCTAssertEqual(violations.count, 1)
    }

    func testCustomRulesIncludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["included": "\\.yml$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesExcludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": "\\.txt$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesExcludedArrayExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": ["\\.pdf$", "\\.txt$"]])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesCaptureGroup() {
        let (_, customRules) = getCustomRules([
            "regex": #"\ba\s+(\w+)"#,
            "capture_group": 1,
        ])
        let violations = customRules.validate(file: testFile)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.line, 2)
        XCTAssertEqual(violations[0].location.character, 6)
    }

    // MARK: - only_rules support

    func testOnlyRulesWithCustomRules() throws {
        let ruleIdentifierToEnable = "aaa"
        let violations = try testOnlyRulesWithCustomRules([ruleIdentifierToEnable])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].ruleIdentifier, ruleIdentifierToEnable)
    }

    func testOnlyRulesWithIndividualIdentifiers() throws {
        let customRuleIdentifiers = ["aaa", "bbb"]
        let violationsWithIndividualRuleIdentifiers = try testOnlyRulesWithCustomRules(customRuleIdentifiers)
        XCTAssertEqual(violationsWithIndividualRuleIdentifiers.count, 2)
        XCTAssertEqual(
            violationsWithIndividualRuleIdentifiers.map { $0.ruleIdentifier },
            customRuleIdentifiers
        )
        let violationsWithCustomRulesIdentifier = try testOnlyRulesWithCustomRules(["custom_rules"])
        XCTAssertEqual(violationsWithIndividualRuleIdentifiers, violationsWithCustomRulesIdentifier)
    }

    // MARK: - Private

    private func getCustomRules(_ extraConfig: [String: Any] = [:]) -> (Configuration, CustomRules) {
        var config: [String: Any] = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]
        extraConfig.forEach { config[$0] = $1 }

        let regexConfig = configuration(withIdentifier: "custom", configurationDict: config)
        let customRules = customRules(withConfigurations: [regexConfig])
        return (regexConfig, customRules)
    }

    private func getCustomRulesWithTwoRules() -> ((Configuration, Configuration), CustomRules) {
        let config1 = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]

        let regexConfig1 = configuration(withIdentifier: "custom1", configurationDict: config1)

        let config2 = [
            "regex": "something",
            "match_kinds": "comment",
        ]

        let regexConfig2 = configuration(withIdentifier: "custom2", configurationDict: config2)

        let customRules = customRules(withConfigurations: [regexConfig1, regexConfig2])
        return ((regexConfig1, regexConfig2), customRules)
    }

    private func configuration(withIdentifier identifier: String, configurationDict: [String: Any]) -> Configuration {
        var regexConfig = Configuration(identifier: identifier)
        do {
            try regexConfig.apply(configuration: configurationDict)
        } catch {
            XCTFail("Failed regex config")
        }
        return regexConfig
    }

    private func customRules(withConfigurations configurations: [Configuration]) -> CustomRules {
        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = configurations
        var customRules = CustomRules()
        customRules.configuration = customRuleConfiguration
        return customRules
    }

    private func testOnlyRulesWithCustomRules(_ onlyRulesIdentifiers: [String]) throws -> [StyleViolation] {
        let customRules: [String: Any] = [
            "aaa": [
                "regex": "aaa"
            ],
            "bbb": [
                "regex": "bbb"
            ],
        ]
        let example = Example("""
                              let a = "aaa"
                              let b = "bbb"
                              """)
        let configDict: [String: Any] = [
            "only_rules": onlyRulesIdentifiers,
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintFramework.Configuration(dict: configDict)
        return TestHelpers.violations(example.skipWrappingInCommentTest(), config: configuration)
    }
}
