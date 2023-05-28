import ArgumentParser
import Foundation
import SwiftLintFramework
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftLint {
    struct Configure: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Configure SwiftLint")

        @Flag(help: "Colorize output regardless of terminal settings.")
        var colorize = false
        @Flag(help: "Do not colorize output regardless of terminal settings.")
        var noColorize = false

        private var shouldColorizeOutput: Bool {
            terminalSupportsColor() && (!noColorize || colorize)
        }

        func run() async throws {
            doYouWantToContinue("Welcome to SwiftLint! Do you want to continue?")
            checkForExistingConfiguration()
            checkForExistingChildConfigurations()
            let topLevelDirectories = checkForSwiftFiles()
            let rulesToDisable = try await rulesToDisable(topLevelDirectories)
            print("rulesToDisable = \(rulesToDisable)")
            ExitHelper.successfullyExit()
        }

        private func checkForExistingConfiguration() {
            print("Checking for existing .swiftlint.yml configuration file.")
            if FileManager.default.fileExists(atPath: ".swiftlint.yml") {
                doYouWantToContinue("Found an existing .swiftlint.yml configuration file - do you want to continue?")
            }
        }

        private func checkForExistingChildConfigurations() {
            print("Checking for any other .swiftlint.yml configuration files.")
            let files = FileManager.default.filesWithSuffix(".swiftlint.yml").filter { $0 != ".swiftlint.yml" }
            if files.isNotEmpty {
                print("Found existing child configurations:\n")
                files.forEach { print($0) }
                doYouWantToContinue("\nDo you want to continue?")
            }
        }

        private func checkForSwiftFiles() -> [String] {
            print("Checking for .swift files.")
            let topLevelDirectories = FileManager.default.filesWithSuffix(".swift")
                .compactMap { $0.firstPathComponent }
                .unique()
                .filter { !$0.isSwiftFile() }
            if topLevelDirectories.isNotEmpty {
                print("Found .swift files in the following top level directories:\n")
                topLevelDirectories.forEach { print($0) }
                if askUser("\nDo you want SwiftLint to scan all of those directories?") {
                    return topLevelDirectories
                } else {
                    var selectedDirectories: [String] = []
                    for topLevelDirectory in topLevelDirectories {
                        if askUser("Do you want SwiftLint to scan the \(topLevelDirectory) directory?") {
                            selectedDirectories.append(topLevelDirectory)
                        }
                    }
                    return selectedDirectories
                }
            } else {
                print("No .swift files found.")
                doYouWantToContinue("\nDo you want to continue? (Y/n)")
                return []
            }
        }

        private func rulesToDisable(_ topLevelDirectories: [String]) async throws -> [String] {
            var ruleIdentifiersToDisable: [String] = []
            print("Checking for violations.")
            let configuration = try writeTemporaryConfigurationFile(topLevelDirectories)
            defer {
                try? FileManager.default.removeItem(atPath: configuration)
            }

            let options = LintOrAnalyzeOptions(
                mode: .lint,
                paths: [""],
                useSTDIN: false,
                configurationFiles: [configuration],
                strict: false,
                lenient: true,
                forceExclude: false,
                useExcludingByPrefix: false,
                useScriptInputFiles: false,
                benchmark: false,
                reporter: "summary",
                quiet: false,
                output: nil,
                progress: true,
                cachePath: nil,
                ignoreCache: false,
                enableAllRules: true,
                autocorrect: false,
                format: false,
                compilerLogPath: nil,
                compileCommands: nil,
                inProcessSourcekit: false
            )

            let violations = try await LintOrAnalyzeCommand.lintOrAnalyze(options)
            if violations.isNotEmpty {
                if askUser("\nDo you want to disable all of the SwiftLint rules with existing violations?") {
                    let dictionary = Dictionary(grouping: violations) { $0.ruleIdentifier }
                    ruleIdentifiersToDisable = dictionary.keys.sorted {
                        if dictionary[$0]!.count != dictionary[$1]!.count {
                            return dictionary[$0]!.count > dictionary[$1]!.count
                        } else {
                            return $0 > $1
                        }
                    }
                }
            }
            return ruleIdentifiersToDisable
        }

        private func writeTemporaryConfigurationFile(_ topLevelDirectories: [String]) throws -> String {
            var configuration = "included:\n"
            topLevelDirectories.forEach { configuration += "  - \($0)\n" }
            configuration += "opt_in_rules:\n  - all\n"
            let filename = ".\(UUID().uuidString).swiftlint.yml"
            try configuration.write(toFile: filename, atomically: true, encoding: .utf8)
            return filename
        }

        private func askUser(_ message: String) -> Bool {
            swiftlint.askUser(message, colorizeOutput: shouldColorizeOutput)
        }

        private func doYouWantToContinue(_ message: String) {
            if !askUser(message) {
                ExitHelper.successfullyExit()
            }
        }
    }
}

private func askUser(_ message: String, colorizeOutput: Bool) -> Bool {
    let message = "\(message) (Y/n)"
    let colorizedMessage = colorizeOutput ? message.boldify : message
    while true {
        print(colorizedMessage, terminator: " ")
        if let character = readLine() {
            if character == "" || character.lowercased() == "y" {
                return true
            } else if character.lowercased() == "n" {
                return false
            } else {
                print("Invalid Response")
            }
        }
    }
}

private func print(_ message: String, terminator: String = "\n") {
    Swift.print(message, terminator: terminator)
    fflush(stdout)
}

private func terminalSupportsColor() -> Bool {
    if
        isatty(1) != 0, let term = ProcessInfo.processInfo.environment["TERM"],
        term.contains("color"), term.contains("256")
    {
        return true
    }
    return false
}

private extension String {
    var boldify: String {
        "\u{001B}[0;1m\(self)\u{001B}[0;0m"
    }

    var firstPathComponent: String? {
        let components = components(separatedBy: "/")
        return components.first
    }
}

private extension FileManager {
    func filesWithSuffix(_ fileName: String) -> [String] {
        var results: [String] = []
        let directoryEnumerator = enumerator(atPath: currentDirectoryPath)
        while let file = directoryEnumerator?.nextObject() as? String {
            if file.hasSuffix(fileName) {
                results.append(file)
            }
        }
        return results
    }
}

private extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
