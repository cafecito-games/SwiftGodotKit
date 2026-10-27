//
//  GodotInstance.swift
//  SwiftGodotRuntime
//
//  The instance lifecycle boundary moved from SwiftGodotKit, preserved with
//  its original names for source compatibility.
//

import SwiftGodot

@MainActor
extension GodotInstance {
    /// Creates the embedded Godot instance for this process.
    ///
    /// Compatibility entry point preserved from the original `SwiftGodotKit`
    /// boundary: it creates the instance through ``GodotRuntime`` and applies
    /// the module-scope ``initHookCb``/``deinitHookCb`` compatibility hooks.
    /// Prefer the scoped per-instance hooks on
    /// ``GodotRuntime.createInstance(args:initHook:deinitHook:)``.
    public static func create(args: [String]) -> GodotInstance? {
        GodotRuntime.createInstance(args: args)
    }

    /// Destroys an embedded Godot instance. Destroying the same instance more
    /// than once is undefined behavior; see
    /// ``GodotRuntime.destroyInstance(_:)``.
    public static func destroy(instance: GodotInstance) {
        GodotRuntime.destroyInstance(instance)
    }
}
