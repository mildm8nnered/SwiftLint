internal struct AttributesRuleExamples {
    static let nonTriggeringExamples = [
        Example("@objc var x: String"),
        Example("@objc private var x: String"),
        Example("@nonobjc var x: String"),
        Example("@IBOutlet private var label: UILabel"),
        Example("@IBOutlet @objc private var label: UILabel"),
        Example("@NSCopying var name: NSString"),
        Example("@NSManaged var name: String?"),
        Example("@IBInspectable var cornerRadius: CGFloat"),
        Example("@available(iOS 9.0, *)\n let stackView: UIStackView"),
        Example("@NSManaged func addSomeObject(book: SomeObject)"),
        Example("@IBAction func buttonPressed(button: UIButton)"),
        Example("@objc\n @IBAction func buttonPressed(button: UIButton)"),
        Example("@available(iOS 9.0, *)\n func animate(view: UIStackView)"),
        Example("@available(*, deprecated, message: \"A message\")\n func animate(view: UIStackView)"),
        Example("@nonobjc\n final class X {}"),
        Example("@available(iOS 9.0, *)\n class UIStackView {}"),
        Example("@NSApplicationMain\n class AppDelegate: NSObject, NSApplicationDelegate {}"),
        Example("@UIApplicationMain\n class AppDelegate: NSObject, UIApplicationDelegate {}"),
        Example("@IBDesignable\n class MyCustomView: UIView {}"),
        Example("@testable import SourceKittenFramework"),
        Example("@objc(foo_x)\n var x: String"),
        Example("@available(iOS 9.0, *)\n@objc(abc_stackView)\n let stackView: UIStackView"),
        Example("@objc(abc_addSomeObject:)\n @NSManaged func addSomeObject(book: SomeObject)"),
        Example("@objc(ABCThing)\n @available(iOS 9.0, *)\n class Thing {}"),
        Example("class Foo: NSObject {\n override var description: String { return \"\" }\n}"),
        Example("class Foo: NSObject {\n\n override func setUp() {}\n}"),
        Example("@objc\nclass ⽺ {}"),

        // attribute with allowed empty new line above
        Example("""
        extension Property {

            @available(*, unavailable, renamed: \"isOptional\")
            public var optional: Bool { fatalError() }
        }
        """),
        Example("@GKInspectable var maxSpeed: Float"),
        Example("@discardableResult\n func a() -> Int"),
        Example("@objc\n @discardableResult\n func a() -> Int"),
        Example("func increase(f: @autoclosure () -> Int) -> Int"),
        Example("func foo(completionHandler: @escaping () -> Void)"),
        Example("private struct DefaultError: Error {}"),
        Example("@testable import foo\n\nprivate let bar = 1"),
        Example("""
        import XCTest
        @testable import DeleteMe

        @available (iOS 11.0, *)
        class DeleteMeTests: XCTestCase {
        }
        """),
        Example("""
        @objc
        internal func foo(identifier: String, completion: @escaping (() -> Void)) {}
        """),
        Example("""
        @objc
        internal func foo(identifier: String, completion: @autoclosure (() -> Bool)) {}
        """),
        Example("""
        func printBoolOrTrue(_ expression: @autoclosure () throws -> Bool?) rethrows {
          try print(expression() ?? true)
        }
        """),
        Example("""
        import Foundation

        class MyClass: NSObject {
          @objc(
            first:
          )
          static func foo(first: String) {}
        }
        """),
        Example("""
        func refreshable(action: @escaping @Sendable () async -> Void) -> some View {
            modifier(RefreshableModifier(action: action))
        }
        """),
        Example("""
        import AppKit

        @NSApplicationMain
        @MainActor
        final class AppDelegate: NSAppDelegate {}
        """),
        Example(#"""
        @_spi(Private) import SomeFramework

        @_spi(Private)
        final class MyView: View {
            @SwiftUI.Environment(\.colorScheme) var first: ColorScheme
            @Environment(\.colorScheme) var second: ColorScheme
            @Persisted(primaryKey: true) var id: Int
        }
        """#, configuration: ["attributes_with_arguments_always_on_line_above": false], excludeFromDocumentation: true),
    ]

    static let triggeringExamples = [
        Example("@objc\n ↓var x: String"),
        Example("@objc\n\n ↓var x: String"),
        Example("@objc\n private ↓var x: String"),
        Example("@nonobjc\n ↓var x: String"),
        Example("@IBOutlet\n private ↓var label: UILabel"),
        Example("@IBOutlet\n\n private ↓var label: UILabel"),
        Example("@NSCopying\n ↓var name: NSString"),
        Example("@NSManaged\n ↓var name: String?"),
        Example("@IBInspectable\n ↓var cornerRadius: CGFloat"),
        Example("@available(iOS 9.0, *) ↓let stackView: UIStackView"),
        Example("@NSManaged\n ↓func addSomeObject(book: SomeObject)"),
        Example("@IBAction\n ↓func buttonPressed(button: UIButton)"),
        Example("@IBAction\n @objc\n ↓func buttonPressed(button: UIButton)"),
        Example("@available(iOS 9.0, *) ↓func animate(view: UIStackView)"),
        Example("@nonobjc final ↓class X {}"),
        Example("@available(iOS 9.0, *) ↓class UIStackView {}"),
        Example("@available(iOS 9.0, *)\n @objc ↓class UIStackView {}"),
        Example("@available(iOS 9.0, *) @objc\n ↓class UIStackView {}"),
        Example("@available(iOS 9.0, *)\n\n ↓class UIStackView {}"),
        Example("@UIApplicationMain ↓class AppDelegate: NSObject, UIApplicationDelegate {}"),
        Example("@IBDesignable ↓class MyCustomView: UIView {}"),
        Example("@testable\n↓import SourceKittenFramework"),
        Example("@testable\n\n\n↓import SourceKittenFramework"),
        Example("@available(iOS 9.0, *) @objc(abc_stackView)\n ↓let stackView: UIStackView"),
        Example("@objc(abc_addSomeObject:) @NSManaged\n ↓func addSomeObject(book: SomeObject)"),
        Example("@objc(abc_addSomeObject:)\n @NSManaged\n ↓func addSomeObject(book: SomeObject)"),
        Example("@available(iOS 9.0, *)\n @objc(ABCThing) ↓class Thing {}"),
        Example("@GKInspectable\n ↓var maxSpeed: Float"),
        Example("@discardableResult ↓func a() -> Int"),
        Example("@objc\n @discardableResult ↓func a() -> Int"),
        Example("@objc\n\n @discardableResult\n ↓func a() -> Int"),
        Example(#"""
        struct S: View {
            @Environment(\.colorScheme) ↓var first: ColorScheme
            @Persisted var id: Int
            @FetchRequest(
                  animation: nil
            )
            var entities: FetchedResults
        }
        """#, excludeFromDocumentation: true),
    ]
}
