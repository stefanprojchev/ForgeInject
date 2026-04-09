import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#inject()` freestanding expression macro.
///
/// Expands to a `ForgeContainer.shared.resolve()` call. The result type is inferred from the
/// surrounding context (the variable's type annotation or the expected return type).
public struct InjectExpressionMacro: ExpressionMacro {

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        """
        {
            guard let container = ForgeContainer.shared else {
                fatalError("ForgeContainer.shared is not set. Configure it before calling #inject().")
            }
            do {
                return try container.resolve()
            } catch {
                fatalError("#inject() failed to resolve type: \\(error.localizedDescription)")
            }
        }()
        """
    }
}
