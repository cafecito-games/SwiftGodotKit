import XCTest
@testable import SwiftGodotRuntime
import SwiftGodot
import libgodot

@MainActor
final class GodotRuntimeTests: XCTestCase {
    private var restoreCreateInstance: (() -> Void)!
    private var restoreDestroyInstance: (() -> Void)!
    private var restoreRegisterSwiftModule: (() -> Void)!

    override func setUp() {
        super.setUp()
        let currentCreateInstance = GodotRuntimeBridge.createInstance
        let currentDestroyInstance = GodotRuntimeBridge.destroyInstance
        let currentRegisterSwiftModule = GodotRuntimeBridge.registerSwiftModule
        restoreCreateInstance = { GodotRuntimeBridge.createInstance = currentCreateInstance }
        restoreDestroyInstance = { GodotRuntimeBridge.destroyInstance = currentDestroyInstance }
        restoreRegisterSwiftModule = { GodotRuntimeBridge.registerSwiftModule = currentRegisterSwiftModule }
    }

    override func tearDown() {
        initHookCb = nil
        deinitHookCb = nil
        restoreCreateInstance()
        restoreDestroyInstance()
        restoreRegisterSwiftModule()
        super.tearDown()
    }

    func testCreateInstancePrependsExecutablePathAndNullTerminatesArguments() {
        var capturedArguments: [String?] = []
        var capturedArgumentCount = 0
        var terminatorIsNull = false
        GodotRuntimeBridge.createInstance = { argumentCount, arguments, _ in
            capturedArgumentCount = Int(argumentCount)
            guard let arguments else { return nil }
            for index in 0..<Int(argumentCount) {
                capturedArguments.append(arguments[index].map { String(cString: $0) })
            }
            terminatorIsNull = arguments[Int(argumentCount)] == nil
            return nil
        }

        XCTAssertNil(GodotRuntime.createInstance(args: ["--headless", "--path", "/tmp/project"]))
        XCTAssertEqual(capturedArgumentCount, 4)
        XCTAssertEqual(capturedArguments.first ?? "", Bundle.main.executablePath ?? "")
        XCTAssertEqual(Array(capturedArguments.dropFirst()), ["--headless", "--path", "/tmp/project"])
        XCTAssertTrue(terminatorIsNull)
    }

    func testCreationFailureReturnsNilAndRequiresNoCleanup() {
        var destroyInstanceCalls = 0
        GodotRuntimeBridge.createInstance = { _, _, _ in nil }
        GodotRuntimeBridge.destroyInstance = { _ in destroyInstanceCalls += 1 }

        XCTAssertNil(GodotRuntime.createInstance(args: ["--headless"]))
        XCTAssertEqual(destroyInstanceCalls, 0, "failed creation must not require compensating destruction")
    }

    func testInitializationCallbackRefusesWhenRequiredPointersAreAbsent() {
        var registerSwiftModuleCalls = 0
        GodotRuntimeBridge.registerSwiftModule = { _, _, _, _, _, _ in
            registerSwiftModuleCalls += 1
        }
        var callbackResult: LGDExtensionBool? = nil
        GodotRuntimeBridge.createInstance = { _, _, initialization in
            callbackResult = initialization?(nil, nil, nil)
            return nil
        }

        XCTAssertNil(GodotRuntime.createInstance(args: []))
        XCTAssertEqual(callbackResult, 0, "the initialization callback must refuse when libgodot supplies no required pointer")
        XCTAssertEqual(registerSwiftModuleCalls, 0)
    }

    func testInitializationFailsClosedForEachMissingPointer() {
        var registerSwiftModuleCalls = 0
        GodotRuntimeBridge.registerSwiftModule = { _, _, _, _, _, _ in
            registerSwiftModuleCalls += 1
        }
        let getProcAddress: LGDExtensionInterfaceGetProcAddress? = absentGetProcAddress
        let libraryPointer = UnsafeMutableRawPointer(bitPattern: 0x1)
        let initializationRecord = OpaquePointer(UnsafeMutableRawPointer(bitPattern: 0x2)!)
        let hooks = GodotRuntimeLifecycle.compose(initHook: nil, deinitHook: nil)

        func assertInitializationFails(
            godotGetProcAddr: LGDExtensionInterfaceGetProcAddress?,
            libraryPtr: LGDExtensionClassLibraryPtr?,
            extensionInitialization: OpaquePointer?
        ) {
            let result = GodotRuntimeInitialization.initialize(
                godotGetProcAddr: godotGetProcAddr,
                libraryPtr: libraryPtr,
                extensionInitialization: extensionInitialization,
                hooks: hooks
            )
            XCTAssertEqual(result, 0, "initialization must fail closed unless every required pointer is present")
        }

        assertInitializationFails(godotGetProcAddr: nil, libraryPtr: nil, extensionInitialization: nil)
        assertInitializationFails(godotGetProcAddr: nil, libraryPtr: nil, extensionInitialization: initializationRecord)
        assertInitializationFails(godotGetProcAddr: nil, libraryPtr: libraryPointer, extensionInitialization: nil)
        assertInitializationFails(godotGetProcAddr: nil, libraryPtr: libraryPointer, extensionInitialization: initializationRecord)
        assertInitializationFails(godotGetProcAddr: getProcAddress, libraryPtr: nil, extensionInitialization: nil)
        assertInitializationFails(godotGetProcAddr: getProcAddress, libraryPtr: nil, extensionInitialization: initializationRecord)
        assertInitializationFails(godotGetProcAddr: getProcAddress, libraryPtr: libraryPointer, extensionInitialization: nil)
        XCTAssertEqual(registerSwiftModuleCalls, 0)
    }

    func testInitializationRegistersComposedHooksThroughOneAuthority() {
        final class HookRecorder {
            var invocations: [String] = []
        }
        let recorder = HookRecorder()
        initHookCb = { level in recorder.invocations.append("compatibility-init:\(level)") }
        deinitHookCb = { level in recorder.invocations.append("compatibility-deinit:\(level)") }

        var registerSwiftModuleCalls = 0
        var registeredInitialize: ((ExtensionInitializationLevel) -> Void)?
        var registeredDeinitialize: ((ExtensionInitializationLevel) -> Void)?
        var registeredMinimumLevel: ExtensionInitializationLevel?
        GodotRuntimeBridge.registerSwiftModule = { _, _, _, initialize, deinitialize, minimumLevel in
            registerSwiftModuleCalls += 1
            registeredInitialize = initialize
            registeredDeinitialize = deinitialize
            registeredMinimumLevel = minimumLevel
        }

        let getProcAddress: LGDExtensionInterfaceGetProcAddress? = absentGetProcAddress
        let libraryPointer = UnsafeMutableRawPointer(bitPattern: 0x1)
        let initializationRecord = OpaquePointer(UnsafeMutableRawPointer(bitPattern: 0x2)!)

        let result = GodotRuntimeInitialization.initialize(
            godotGetProcAddr: getProcAddress,
            libraryPtr: libraryPointer,
            extensionInitialization: initializationRecord,
            hooks: GodotRuntimeLifecycle.compose(
                initHook: { level in recorder.invocations.append("scoped-init:\(level)") },
                deinitHook: { level in recorder.invocations.append("scoped-deinit:\(level)") }
            )
        )

        XCTAssertEqual(result, 1)
        XCTAssertEqual(registerSwiftModuleCalls, 1)
        XCTAssertEqual(registeredMinimumLevel, .core)

        registeredInitialize?(.scene)
        registeredDeinitialize?(.core)
        XCTAssertEqual(recorder.invocations, [
            "compatibility-init:scene",
            "scoped-init:scene",
            "compatibility-deinit:core",
            "scoped-deinit:core",
        ])
    }

    func testCompatibilityCreateDelegatesToRuntimeBoundary() {
        var createInstanceCalls = 0
        var destroyInstanceCalls = 0
        GodotRuntimeBridge.createInstance = { _, _, _ in
            createInstanceCalls += 1
            return nil
        }
        GodotRuntimeBridge.destroyInstance = { _ in destroyInstanceCalls += 1 }

        XCTAssertNil(GodotInstance.create(args: ["--headless"]))
        XCTAssertEqual(createInstanceCalls, 1, "GodotInstance.create must delegate to the runtime boundary")
        XCTAssertEqual(destroyInstanceCalls, 0)
    }
}

private func absentGetProcAddress(functionName: UnsafePointer<CChar>?) -> LGDExtensionInterfaceFunctionPtr? {
    nil
}
