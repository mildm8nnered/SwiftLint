@testable import SwiftLintFramework
import TestHelpers
import XCTest

final class CollectingRuleTests: SwiftLintTestCase {
    func testCollectsIntoStorage() {
        struct Spec: MockCollectingRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for _: SwiftLintFile) -> Int {
                42
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: Int]) -> [StyleViolation] {
                XCTAssertEqual(collectedInfo[file], 42)
                return [
                    StyleViolation(
                        ruleDescription: Self.description,
                        location: Location(file: file, byteOffset: 0)
                    ),
                ]
            }
        }

        XCTAssertFalse(violations(Example("_ = 0"), config: Spec.configuration!).isEmpty)
    }

    func testCollectsAllFiles() {
        struct Spec: MockCollectingRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                let values = collectedInfo.values
                XCTAssertTrue(values.contains("foo"))
                XCTAssertTrue(values.contains("bar"))
                XCTAssertTrue(values.contains("baz"))
                return [
                    StyleViolation(
                        ruleDescription: Self.description,
                        location: Location(file: file, byteOffset: 0)
                    ),
                ]
            }
        }

        let inputs = ["foo", "bar", "baz"]
        XCTAssertEqual(inputs.violations(config: Spec.configuration!).count, inputs.count)
    }

    func testCollectsAnalyzerFiles() {
        struct Spec: MockCollectingRule, AnalyzerRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for _: SwiftLintFile, compilerArguments: [String]) -> [String] {
                compilerArguments
            }
            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: [String]], compilerArguments: [String])
                -> [StyleViolation] {
                    XCTAssertEqual(collectedInfo[file], compilerArguments)
                    return [
                        StyleViolation(
                            ruleDescription: Self.description,
                            location: Location(file: file, byteOffset: 0)
                        ),
                    ]
            }
        }

        XCTAssertFalse(violations(Example("_ = 0"), config: Spec.configuration!, requiresFileOnDisk: true).isEmpty)
    }

    func testCorrects() {
        struct Spec: MockCollectingRule, CorrectableRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> [StyleViolation] {
                if collectedInfo[file] == "baz" {
                    return [
                        StyleViolation(
                            ruleDescription: Self.description,
                            location: Location(file: file, byteOffset: 2)
                        ),
                    ]
                }
                return []
            }

            func correct(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String]) -> Int {
                collectedInfo[file] == "baz" ? 1 : 0
            }

            func correct(file: SwiftLintFile) -> Int {
                correct(file: file, collectedInfo: [file: collectInfo(for: file)])
            }
        }

        struct AnalyzerSpec: MockCollectingRule, AnalyzerRule, CorrectableRule {
            var configuration = SeverityConfiguration<Self>(.warning)

            func collectInfo(for file: SwiftLintFile) -> String {
                file.contents
            }

            func validate(file: SwiftLintFile, collectedInfo: [SwiftLintFile: String], compilerArguments _: [String])
                -> [StyleViolation] {
                    collectedInfo[file] == "baz"
                        ? [.init(ruleDescription: Spec.description, location: Location(file: file, byteOffset: 2))]
                        : []
            }

            func correct(file: SwiftLintFile,
                         collectedInfo: [SwiftLintFile: String],
                         compilerArguments _: [String]) -> Int {
                collectedInfo[file] == "baz" ? 1 : 0
            }

            func correct(file: SwiftLintFile) -> Int {
                correct(file: file, collectedInfo: [file: collectInfo(for: file)], compilerArguments: [])
            }
        }

        let inputs = ["foo", "baz"]
        XCTAssertEqual(inputs.corrections(config: Spec.configuration!).count, 1)
        XCTAssertEqual(inputs.corrections(config: AnalyzerSpec.configuration!, requiresFileOnDisk: true).count, 1)
    }
}

private protocol MockCollectingRule: CollectingRule {}
extension MockCollectingRule {
    @RuleConfigurationDescriptionBuilder
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }
    static var description: RuleDescription {
        RuleDescription(identifier: "mock_test_rule_for_swiftlint_tests", name: "", description: "", kind: .lint)
    }
    static var configuration: Configuration? {
        Configuration(rulesMode: .onlyConfiguration([identifier]), ruleList: RuleList(rules: self))
    }

    init(configuration _: Any) throws { self.init() }
}
