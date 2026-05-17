import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `@Injectable` macro.
///
/// Generates an `init` that takes every stored `let` property without a default value as a parameter,
/// with each parameter defaulting to `ForgeContainer.shared.resolve()`. Production call sites stay
/// zero-arg; tests can swap in mocks via the generated init.
public struct InjectableMacro: MemberMacro {

    // MARK: - Implementation

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only classes, structs, and actors are supported.
        guard declaration.is(ClassDeclSyntax.self)
            || declaration.is(StructDeclSyntax.self)
            || declaration.is(ActorDeclSyntax.self) else {
            throw InjectableMacroError.unsupportedDeclaration
        }

        let properties = collectInjectableProperties(from: declaration)

        // No injectable properties → generate an empty init for consistency.
        if properties.isEmpty {
            return [
                """
                init() {}
                """
            ]
        }

        let parameters = properties
            .map { "\($0.name): \($0.type) = try! ForgeContainer.shared!.resolve()" }
            .joined(separator: ", ")

        let assignments = properties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n")

        return [
            """
            init(\(raw: parameters)) {
                \(raw: assignments)
            }
            """
        ]
    }

    // MARK: - Private

    private struct InjectableProperty {
        let name: String
        let type: TypeSyntax
    }

    /// Collects every stored `let` property without a default value or accessor.
    /// These become parameters of the generated init.
    private static func collectInjectableProperties(
        from declaration: some DeclGroupSyntax
    ) -> [InjectableProperty] {
        var result: [InjectableProperty] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }

            // Must be `let`
            guard varDecl.bindingSpecifier.tokenKind == .keyword(.let) else { continue }

            // Must not be static
            let isStatic = varDecl.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.static)
                    || modifier.name.tokenKind == .keyword(.class)
            }
            if isStatic { continue }

            for binding in varDecl.bindings {
                // Must have an identifier pattern
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                // Must have an explicit type annotation
                guard let type = binding.typeAnnotation?.type else { continue }
                // Must NOT have an initializer (already provided)
                guard binding.initializer == nil else { continue }
                // Must NOT have accessors (computed property)
                guard binding.accessorBlock == nil else { continue }

                result.append(InjectableProperty(name: pattern.identifier.text, type: type))
            }
        }

        return result
    }
}
