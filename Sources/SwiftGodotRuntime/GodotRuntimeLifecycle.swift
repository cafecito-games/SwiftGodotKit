//
//  GodotRuntimeLifecycle.swift
//  SwiftGodotRuntime
//
//  The single lifecycle authority for embedded Godot instances.
//

import SwiftGodot

/// Compatibility lifecycle hooks retained from the original `SwiftGodotKit`
/// boundary. They are read at initialization time, so a host can install them
/// any time before it creates an instance. New code should prefer the
/// per-instance hooks on ``GodotRuntime.createInstance(args:initHook:deinitHook:)``.
public var initHookCb: ((ExtensionInitializationLevel) -> ())?
public var deinitHookCb: ((ExtensionInitializationLevel) -> ())?

/// The one authority that composes every initialization and deinitialization
/// hook for an embedded Godot instance.
///
/// All registration paths — the module-scope compatibility hooks above and the
/// per-instance hooks accepted by ``GodotRuntime.createInstance(args:initHook:deinitHook:)``
/// — are merged here and nowhere else. The compatibility hook runs first,
/// followed by the per-instance hook, so a UI host using the compatibility
/// globals and a headless consumer passing scoped hooks never install two
/// competing initialization paths.
enum GodotRuntimeLifecycle {
    struct Hooks {
        var initialize: (ExtensionInitializationLevel) -> Void
        var deinitialize: (ExtensionInitializationLevel) -> Void
    }

    static func compose(
        initHook: ((ExtensionInitializationLevel) -> ())?,
        deinitHook: ((ExtensionInitializationLevel) -> ())?
    ) -> Hooks {
        Hooks(
            initialize: { level in
                initHookCb?(level)
                initHook?(level)
            },
            deinitialize: { level in
                deinitHookCb?(level)
                deinitHook?(level)
            }
        )
    }
}
