//
//  GodotRuntimeBridge.swift
//  SwiftGodotRuntime
//
//  The libgodot C boundary for instance creation and destruction.
//

import Foundation
import SwiftGodot
import libgodot

/// Indirection over the libgodot C boundary and the SwiftGodot module
/// registration it triggers. Production paths use the real engine functions;
/// tests replace these seams to exercise failure modes the real engine cannot
/// produce deterministically.
enum GodotRuntimeBridge {
    static var createInstance: (
        Int32,
        UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?,
        LGDExtensionInitializationFunction?
    ) -> UnsafeMutableRawPointer? = { argumentCount, arguments, initialization in
        libgodot.libgodot_create_godot_instance(argumentCount, arguments, initialization)
    }

    static var destroyInstance: (UnsafeMutableRawPointer) -> Void = { instance in
        libgodot.libgodot_destroy_godot_instance(instance)
    }

    static var registerSwiftModule: (
        _ godotGetProcAddrPtr: OpaquePointer,
        _ libraryPtr: OpaquePointer,
        _ extensionPtr: OpaquePointer,
        _ initialize: @escaping (ExtensionInitializationLevel) -> Void,
        _ deinitialize: @escaping (ExtensionInitializationLevel) -> Void,
        _ minimumInitializationLevel: ExtensionInitializationLevel
    ) -> Void = { godotGetProcAddrPtr, libraryPtr, extensionPtr, initialize, deinitialize, minimumInitializationLevel in
        initializeSwiftModule(
            godotGetProcAddrPtr,
            libraryPtr,
            extensionPtr,
            initHook: initialize,
            deInitHook: deinitialize,
            minimumInitializationLevel: minimumInitializationLevel
        )
    }
}

/// The composed hooks for the instance currently being created.
///
/// libgodot invokes the creation callback synchronously on the thread that is
/// creating the instance, while `GodotRuntime.createInstance(args:initHook:deinitHook:)`
/// holds exclusive control of this value, and a C function pointer cannot carry
/// captured context. The value is cleared before creation returns.
nonisolated(unsafe) var pendingInitializationHooks: GodotRuntimeLifecycle.Hooks?

/// The fail-closed gate every embedded initialization passes through.
///
/// libgodot must supply the procedure-address lookup, the class-library
/// pointer, and the initialization record. When any of them is absent the
/// extension refuses to initialize, `libgodot_create_godot_instance` fails,
/// and creation surfaces no instance to the caller.
enum GodotRuntimeInitialization {
    static func initialize(
        godotGetProcAddr: LGDExtensionInterfaceGetProcAddress?,
        libraryPtr: LGDExtensionClassLibraryPtr?,
        extensionInitialization: OpaquePointer?,
        hooks: GodotRuntimeLifecycle.Hooks
    ) -> LGDExtensionBool {
        guard let godotGetProcAddr, let libraryPtr, let extensionInitialization else {
            return 0
        }
        GodotRuntimeBridge.registerSwiftModule(
            unsafeBitCast(godotGetProcAddr, to: OpaquePointer.self),
            unsafeBitCast(libraryPtr, to: OpaquePointer.self),
            extensionInitialization,
            hooks.initialize,
            hooks.deinitialize,
            .core
        )
        return 1
    }
}
