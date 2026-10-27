//
//  GodotRuntime.swift
//  SwiftGodotRuntime
//
//  Scoped entry points for creating and destroying embedded Godot instances.
//

import Foundation
import SwiftGodot
import libgodot

/// Creates and destroys embedded Godot instances — headless or UI-hosted —
/// through the pinned libgodot runtime.
///
/// This is the lightweight boundary of the package: it depends on SwiftGodot
/// and the platform libgodot payloads only, and compiles no SwiftUI, AppKit,
/// or UIKit hosting code. Consumers that need native view hosting should
/// depend on the `SwiftGodotKit` product instead, which builds on this
/// runtime.
@MainActor
public enum GodotRuntime {
    /// Creates the embedded Godot instance for this process.
    ///
    /// The executable path is prepended to `args` automatically, matching
    /// Godot's expectation that `argv[0]` names the running program.
    ///
    /// - Parameters:
    ///   - args: Godot command-line arguments, for example
    ///     `["--headless", "--path", projectPath]`.
    ///   - initHook: Invoked at each extension initialization level, after the
    ///     module-scope ``initHookCb`` compatibility hook.
    ///   - deinitHook: Invoked at each extension deinitialization level, after
    ///     the module-scope ``deinitHookCb`` compatibility hook.
    /// - Returns: The new instance, or `nil` when creation failed. A failed
    ///   creation leaves no caller-visible instance and requires no
    ///   compensating cleanup — do not attempt to destroy anything.
    ///
    /// Only one instance can exist per process. Finish startup by calling
    /// `start()` on the returned instance.
    public static func createInstance(
        args: [String],
        initHook: ((ExtensionInitializationLevel) -> ())? = nil,
        deinitHook: ((ExtensionInitializationLevel) -> ())? = nil
    ) -> GodotInstance? {
        let hooks = GodotRuntimeLifecycle.compose(initHook: initHook, deinitHook: deinitHook)
        var instance: UnsafeMutableRawPointer? = nil
        let argsWithCmd = [ Bundle.main.executablePath ?? "" ] + args
        withUnsafePtr(strings: argsWithCmd, callback: { cstr in
            pendingInitializationHooks = hooks
            instance = GodotRuntimeBridge.createInstance(Int32(argsWithCmd.count), cstr) { godotGetProcAddr, libraryPtr, extensionInitialization in
                guard let pendingInitializationHooks else { return 0 }
                return GodotRuntimeInitialization.initialize(
                    godotGetProcAddr: godotGetProcAddr,
                    libraryPtr: libraryPtr,
                    extensionInitialization: extensionInitialization,
                    hooks: pendingInitializationHooks
                )
            }
            pendingInitializationHooks = nil
        })
        guard let instance else { return nil }
        return getOrInitSwiftObject(nativeHandle: instance, ownership: .borrowed)
    }

    /// Destroys an embedded Godot instance created by this runtime.
    ///
    /// - Important: A successful instance must be destroyed exactly once.
    ///   Destroying an instance more than once is undefined behavior; the API
    ///   takes no handle it could make safe to pass again, so this contract is
    ///   the caller's responsibility.
    public static func destroyInstance(_ instance: GodotInstance) {
        guard let nativeHandle = instance.handle else {
            Wrapped.attemptToUseObjectFreedByGodot()
            return
        }
        GodotRuntimeBridge.destroyInstance(nativeHandle)
    }
}

// Courtesy of GPT-4
func withUnsafePtr (strings: [String], callback: (UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?)->()) {
    let cStrings: [UnsafeMutablePointer<Int8>?] = strings.map { string in
        // Convert Swift string to a C string (null-terminated)
        return strdup(string)
    }

    // Allocate memory for the array of C string pointers
    let cStringArray = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: cStrings.count + 1)
    cStringArray.initialize(from: cStrings, count: cStrings.count)

    // Add a null pointer at the end of the array to indicate its end
    cStringArray[cStrings.count] = nil

    callback (cStringArray)

    for i in 0..<strings.count {
        free(cStringArray[i])
    }
    cStringArray.deallocate()
}
