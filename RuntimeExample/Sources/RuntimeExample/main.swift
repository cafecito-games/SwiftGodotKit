import Foundation
import SwiftGodotRuntime

// A fresh macOS command-line consumer that links only the SwiftGodotRuntime
// product: no SwiftGodotKit UI sources, no copied libgodot header, module map,
// binary URL, or checksum. It exercises the complete headless lifecycle —
// create, start, confirm, a few main-loop iterations, destroy — and exits
// successfully only when every step passes.

guard
    let projectGodotFile = Bundle.module.url(
        forResource: "project",
        withExtension: "godot",
        subdirectory: "HeadlessProject")
else {
    fail("the headless project fixture is missing from the bundle")
}
let projectPath = projectGodotFile.deletingLastPathComponent().path

var initializationLevels: [String] = []
var deinitializationLevels: [String] = []

guard
    let instance = GodotRuntime.createInstance(
        args: ["--headless", "--path", projectPath],
        initHook: { level in initializationLevels.append(String(describing: level)) },
        deinitHook: { level in deinitializationLevels.append(String(describing: level)) }
    )
else {
    fail("GodotRuntime.createInstance returned nil; a failed creation needs no cleanup")
}

guard instance.start() else {
    GodotRuntime.destroyInstance(instance)
    fail("GodotInstance.start() returned false")
}

guard instance.isStarted() else {
    GodotRuntime.destroyInstance(instance)
    fail("GodotInstance.isStarted() returned false after start()")
}

var iterations = 0
while iterations < 10 && !instance.iteration() {
    iterations += 1
}

GodotRuntime.destroyInstance(instance)

print("RuntimeExample: created, started, ran \(iterations) iterations, and destroyed the headless instance")
print("RuntimeExample: initialization levels: \(initializationLevels)")
print("RuntimeExample: deinitialization levels: \(deinitializationLevels)")
exit(0)

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write("RuntimeExample: \(message)\n".data(using: .utf8)!)
    exit(1)
}
