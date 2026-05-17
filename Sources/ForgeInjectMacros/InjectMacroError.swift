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
