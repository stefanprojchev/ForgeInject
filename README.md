# ForgeInject

Dependency injection for iOS with constructor and property wrapper support.

![Swift 6.3+](https://img.shields.io/badge/Swift-6.3+-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18+-blue.svg)
![macOS 15+](https://img.shields.io/badge/macOS-15+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
[![Release](https://img.shields.io/github/v/release/stefanprojchev/ForgeInject)](https://github.com/stefanprojchev/ForgeInject/releases)

---

ForgeInject is a macro-based dependency injection library for iOS. It gives you three ways to resolve dependencies — one is probably the right fit for every scenario you'll encounter.

| Macro | Use when | Resolution |
|---|---|---|
| **`@Injectable`** | View models and services with stable dependencies. Constructor injection, swappable in tests. | At init time |
| **`@Inject`** | Heavy or optional properties that may never be touched. Lazy + cached + thread-safe. | On first access |
| **`#inject()`** | Local variables, default parameters, `let` in structs. | Where used |

## Features

- **Three macros** for three injection patterns — pick whichever suits each dependency
- **Testable by design** — `@Injectable` generates an init that accepts overrides, so tests don't need to touch the container
- **Thread-safe** — `@Inject`'s lazy form is backed by `Mutex<T?>` from the Synchronization framework
- **Three retain policies** — `.transient`, `.singleton`, `.weak`
- **Modular registration** via `ForgeRegisterProtocol` for feature-based organization
- **Explicit error handling** via `ForgeContainerError`

## Requirements

- **iOS** 18+
- **macOS** 15+
- **Swift** 6.3+ (Xcode 26 or later)

## Installation

### Xcode

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/stefanprojchev/ForgeInject.git`
3. Set rule to **Up to Next Major** from `1.0.0`

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeInject.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["ForgeInject"]
    )
]
```

## Quick Start

### 1. Register dependencies

```swift
import ForgeInject

struct AppDependencies: ForgeRegisterProtocol {
    func registerDependencies(in container: ForgeContainerProtocol) {
        container.register(with: .singleton) { _ in
            NetworkService() as NetworkServiceProtocol
        }
        container.register(with: .singleton) { _ in
            UserRepository() as UserRepositoryProtocol
        }
    }
}
```

### 2. Bootstrap at app launch

```swift
import SwiftUI
import ForgeInject

@main
struct TaskFlowApp: App {
    init() {
        let container = ForgeContainer()
        AppDependencies().registerDependencies(in: container)
        ForgeContainer.shared = container
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### 3. Inject dependencies

```swift
import ForgeInject

@Injectable
@Observable
final class ProfileViewModel {
    let network: NetworkServiceProtocol
    let repository: UserRepositoryProtocol

    var user: User?

    func loadProfile() async {
        user = try? await repository.fetchCurrentUser()
    }
}

// Production — zero-arg init resolves from the container
let vm = ProfileViewModel()

// Tests — pass mocks directly, no container touching
let vm = ProfileViewModel(
    network: MockNetworkService(),
    repository: MockUserRepository()
)
```

## Which macro to use

**`@Injectable`** — start here. Generates a matching `init` with default values resolved from `ForgeContainer.shared`. Tests override dependencies via normal init arguments — no container manipulation required.

```swift
@Injectable
final class ImageProcessor {
    let filter: FilterService
    let storage: StorageService
}
```

**`@Inject`** — lazy, cached, thread-safe. Use for heavy dependencies, circular dependency breaks, or late-bootstrapped services.

```swift
final class AdvancedViewModel {
    @Inject var heavyService: HeavyService          // lazy (default)
    @Inject(lazy: false) var logger: LoggerService   // eager, no Mutex overhead
}
```

**`#inject()`** — freestanding, works anywhere a value is expected. Local variables, default parameters, `lazy var` initializers.

```swift
struct RequestHandler {
    let database: Database = #inject()

    func handle() async {
        let logger: Logger = #inject()
        logger.info("handling request")
    }
}
```

See the Macros section above for when to use which.

## Retain policies

```swift
// Singleton — shared for the container's lifetime
container.register(with: .singleton) { _ in
    DatabaseService() as DatabaseServiceProtocol
}

// Transient — new instance every resolve
container.register(with: .transient) { _ in
    FormValidator()
}

// Weak — shared while held, recreated after release
container.register(with: .weak) { _ in
    ImageCache() as ImageCacheProtocol
}
```

## The Forge Family

ForgeInject is part of the **Forge** family of Swift packages for iOS.

| Package | Description |
|---|---|
| [ForgeCore](https://github.com/stefanprojchev/ForgeCore) | Thread-safe primitives for iOS Swift packages. |
| **ForgeInject** | Dependency injection with constructor and property wrapper support. |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers — connectivity, lifecycle, keyboard, and more. |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe key-value, file, and Keychain storage. |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Orchestrate app flows — startup gates, data pipelines, and continuous monitors. |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, and routing. |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location triggers — geofencing, significant changes, and visits. |
| [ForgeBackgroundTasks](https://github.com/stefanprojchev/ForgeBackgroundTasks) | Background task scheduling and dispatch. |

## License

ForgeInject is released under the MIT License. See [LICENSE](LICENSE).
