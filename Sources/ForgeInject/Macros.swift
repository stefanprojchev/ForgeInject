/// Property-level dependency injection macro.
///
/// Resolves a dependency from `ForgeContainer.shared` and provides it as a stored or computed property.
///
/// ## Lazy resolution (default)
/// ```swift
/// @Inject var database: Database
/// ```
/// Expands to a `Mutex`-protected lazy backing — resolved on first access, cached afterwards,
/// thread-safe across concurrent first-accesses.
///
/// ## Eager resolution
/// ```swift
/// @Inject(lazy: false) var logger: Logger
/// ```
/// Expands to a plain `let` initialized at the containing object's init time. No `Mutex` overhead.
/// Best for cheap, always-needed dependencies.
///
/// - Parameter lazy: When `true` (default), the dependency is resolved on first access and cached.
///   When `false`, the dependency is resolved eagerly when the containing object is initialized.
@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Inject(lazy: Bool = true) = #externalMacro(
    module: "ForgeInjectMacros",
    type: "InjectMacro"
)

/// Type-level dependency injection macro.
///
/// Generates an `init` that takes every stored `let` property as a parameter, with default values
/// resolved from `ForgeContainer.shared`. This enables constructor injection while keeping
/// production call sites zero-arg.
///
/// ```swift
/// @Injectable
/// final class UserViewModel {
///     let database: Database
///     let analytics: AnalyticsService
/// }
///
/// // Production: dependencies resolved from container
/// let vm = UserViewModel()
///
/// // Tests: swap with mocks
/// let vm = UserViewModel(database: MockDatabase(), analytics: MockAnalytics())
/// ```
///
/// Only `let` stored properties without default values are included in the generated init.
@attached(member, names: named(init))
public macro Injectable() = #externalMacro(
    module: "ForgeInjectMacros",
    type: "InjectableMacro"
)

/// Freestanding expression macro that resolves a dependency from `ForgeContainer.shared`.
///
/// The type is inferred from context, so you can use `#inject()` anywhere a value is expected:
///
/// ```swift
/// struct UserService: Sendable {
///     let database: Database = #inject()
/// }
///
/// final class ImageProcessor {
///     lazy var heavyDep: HeavyService = #inject()  // pair with `lazy var` for lazy semantics
/// }
///
/// func handleRequest() {
///     let logger: Logger = #inject()
///     logger.info("processing")
/// }
/// ```
@freestanding(expression)
public macro inject<T>() -> T = #externalMacro(
    module: "ForgeInjectMacros",
    type: "InjectExpressionMacro"
)
