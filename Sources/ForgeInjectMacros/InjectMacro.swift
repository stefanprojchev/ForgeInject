import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `@Inject` macro.
///
/// Conforms to both `AccessorMacro` (replaces the stored property's accessors with a computed get)
/// and `PeerMacro` (adds the backing storage as a sibling declaration).
public struct InjectMacro: AccessorMacro, PeerMacro {

    // MARK: - PeerMacro: generates the backing storage

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let property = try parseProperty(declaration, context: context, attribute: node)
        let isLazy = parseLazyArgument(from: node)
        let storageName = "_\(property.name)"

        if isLazy {
            return [
                """
                private let \(raw: storageName) = Mutex<\(property.type)?>(nil)
                """
            ]
        } else {
            return [
                """
                private let \(raw: storageName): \(property.type) = {
                    guard let container = ForgeContainer.shared else {
                        fatalError("ForgeContainer.shared is not set. Configure it before any @Inject(lazy: false) property is initialized.")
                    }
                    do {
                        return try container.resolve()
                    } catch {
                        fatalError("\\(\(property.type).self) could not be resolved: \\(error.localizedDescription)")
                    }
                }()
                """
            ]
        }
    }

    // MARK: - AccessorMacro: replaces the stored property with a computed get

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        let property = try parseProperty(declaration, context: context, attribute: node)
        let isLazy = parseLazyArgument(from: node)
        let storageName = "_\(property.name)"

        if isLazy {
            return [
                """
                get {
                    \(raw: storageName).withLock { storage in
                        if let value = storage { return value }
                        guard let container = ForgeContainer.shared else {
                            fatalError("ForgeContainer.shared is not set. Configure it before accessing any @Inject property.")
                        }
                        do {
                            let value: \(property.type) = try container.resolve()
                            storage = value
                            return value
                        } catch {
                            fatalError("\\(\(property.type).self) could not be resolved: \\(error.localizedDescription)")
                        }
                    }
                }
                """
            ]
        } else {
            return [
                """
                get { \(raw: storageName) }
                """
            ]
        }
    }

    // MARK: - Helpers

    private struct ParsedProperty {
        let name: String
        let type: TypeSyntax
    }

    private static func parseProperty(
        _ declaration: some DeclSyntaxProtocol,
        context: some MacroExpansionContext,
        attribute: AttributeSyntax
    ) throws -> ParsedProperty {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw InjectMacroError.notAVariable
        }

        guard varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw InjectMacroError.requiresVar
        }

        guard let binding = varDecl.bindings.first,
              varDecl.bindings.count == 1 else {
            throw InjectMacroError.singleBindingRequired
        }

        guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw InjectMacroError.invalidPattern
        }

        guard let type = binding.typeAnnotation?.type else {
            throw InjectMacroError.missingTypeAnnotation
        }

        guard binding.initializer == nil else {
            throw InjectMacroError.unexpectedInitializer
        }

        return ParsedProperty(name: pattern.identifier.text, type: type)
    }

    private static func parseLazyArgument(from node: AttributeSyntax) -> Bool {
        guard case let .argumentList(args) = node.arguments else {
            return true
        }
        guard let lazyArg = args.first(where: { $0.label?.text == "lazy" }) else {
            return true
        }
        guard let boolLiteral = lazyArg.expression.as(BooleanLiteralExprSyntax.self) else {
            return true
        }
        return boolLiteral.literal.tokenKind == .keyword(.true)
    }
}

// MARK: - Errors

enum InjectMacroError: Error, CustomStringConvertible {
    case notAVariable
    case requiresVar
    case singleBindingRequired
    case invalidPattern
    case missingTypeAnnotation
    case unexpectedInitializer

    var description: String {
        switch self {
        case .notAVariable:
            "@Inject can only be applied to variable declarations."
        case .requiresVar:
            "@Inject requires `var`, not `let`. Use `@Inject var name: Type`."
        case .singleBindingRequired:
            "@Inject must be applied to a single property declaration."
        case .invalidPattern:
            "@Inject requires a simple property name (e.g. `var database: Database`)."
        case .missingTypeAnnotation:
            "@Inject requires an explicit type annotation, e.g. `@Inject var database: Database`."
        case .unexpectedInitializer:
            "@Inject properties must not have an initializer; the value is resolved from the container."
        }
    }
}
