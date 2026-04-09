import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ForgeInjectPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectMacro.self,
        InjectableMacro.self,
        InjectExpressionMacro.self,
    ]
}
