//
//  SwiftGodotKit.swift
//  SwiftGodotKit
//
//  Compatibility surface for the instance lifecycle boundary, which now lives
//  in the SwiftGodotRuntime target.
//

import Foundation
import OSLog

// The instance lifecycle boundary moved to the SwiftGodotRuntime target.
// Re-export it so existing `import SwiftGodotKit` consumers keep compiling
// without importing another module. The runtime keeps the single
// implementation; this module adds no duplicate declarations.
@_exported import SwiftGodotRuntime

let logger = Logger(subsystem: "games.cafecito.swiftgodotkit", category: "general")
