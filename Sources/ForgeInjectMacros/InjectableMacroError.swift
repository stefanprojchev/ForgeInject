enum InjectableMacroError: Error, CustomStringConvertible {
    case unsupportedDeclaration

    var description: String {
        switch self {
        case .unsupportedDeclaration:
            "@Injectable can only be applied to a class, struct, or actor."
        }
    }
}
