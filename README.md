# ForgeInject

A lightweight dependency injection library for iOS, built with Swift.

## Requirements

- iOS 16+
- Swift 6.0+

## Installation

### Swift Package Manager

Add ForgeInject to your project via Xcode:

1. **File > Add Package Dependencies...**
2. Enter the repository URL
3. Select the version rule and add to your target

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stefanprojchev/ForgeInject.git", from: "1.0.0")
]
```

## Quick Start

### 1. Register dependencies at app launch

```swift
import ForgeInject

@main
struct MyApp: App {
    init() {
        let container = ForgeContainer()

        container.register(with: .singleton) { _ in
            NetworkService()
        }

        container.register(with: .singleton) { container in
            let networkService: NetworkService = try container.resolve()
            return UserRepository(networkService: networkService)
        }

        ForgeContainer.shared = container
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Resolve dependencies with the property wrapper

```swift
class ProfileViewModel: ObservableObject {
    @ForgeInject var userRepository: UserRepository

    func loadProfile() {
        // userRepository is resolved automatically
    }
}
```

## Retain Policies

Control how the container manages dependency lifetimes:

| Policy | Behavior |
|--------|----------|
| `.transient` | Creates a **new instance** on every resolve |
| `.singleton` | Creates once, returns the **same instance** (singleton) |
| `.weak` | Returns the same instance **while something holds a strong reference**, creates a new one after it's deallocated |

```swift
// New instance every time
container.register(with: .transient) { _ in AnalyticsEvent() }

// Singleton — shared across the app
container.register(with: .singleton) { _ in DatabaseService() }

// Lives as long as someone holds a reference
container.register(with: .weak) { _ in CacheService() }
```

## Modular Registration

Use `ForgeRegisterProtocol` to organize registrations by feature module:

```swift
struct NetworkModule: ForgeRegisterProtocol {
    func registerDependencies(in container: ForgeContainerProtocol) {
        container.register(with: .singleton) { _ in URLSession.shared as URLSessionProtocol }
        container.register(with: .singleton) { _ in APIClient() }
    }
}

struct DataModule: ForgeRegisterProtocol {
    func registerDependencies(in container: ForgeContainerProtocol) {
        container.register(with: .singleton) { container in
            let apiClient: APIClient = try container.resolve()
            return UserRepository(apiClient: apiClient)
        }
    }
}

// At app launch
let container = ForgeContainer()
NetworkModule().registerDependencies(in: container)
DataModule().registerDependencies(in: container)
ForgeContainer.shared = container
```

## Eager Resolution

By default, dependencies are resolved lazily on first access. To resolve immediately:

```swift
@ForgeInject(lazy: false) var service: MyService
```

## Thread Safety

All container operations (`register`, `resolve`, `reset`) are internally synchronized and safe to call from any thread.

## Forge Ecosystem

ForgeInject is part of the **Forge** family of Swift packages for iOS:

| Package | Description |
|---------|-------------|
| [ForgeCore](https://github.com/stefanprojchev/ForgeCore) | Thread-safe utilities — `LockedState` and `SendableFileManager` |
| **ForgeInject** | Lightweight dependency injection with property wrapper |
| [ForgeObservers](https://github.com/stefanprojchev/ForgeObservers) | Reactive system observers (connectivity, lifecycle, keyboard, and more) |
| [ForgeStorage](https://github.com/stefanprojchev/ForgeStorage) | Type-safe persistence — key-value, file storage, and Keychain |
| [ForgeBackgroundTasks](https://github.com/stefanprojchev/ForgeBackgroundTasks) | BGTaskScheduler registration, scheduling, and dispatch |
| [ForgeLocation](https://github.com/stefanprojchev/ForgeLocation) | Location-based triggers — geofencing, significant changes, visits |
| [ForgePush](https://github.com/stefanprojchev/ForgePush) | Push notification management — permissions, tokens, silent and visible routing |
| [ForgeOrchestrator](https://github.com/stefanprojchev/ForgeOrchestrator) | Sequence, pipeline, and monitor orchestrators for iOS app flows |

## License

MIT License. See [LICENSE](LICENSE) for details.
