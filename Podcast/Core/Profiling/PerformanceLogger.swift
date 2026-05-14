//
//  PerformanceLogger.swift
//  Podcast
//

import Foundation
import os

/// Logger centralizado para medir performance con os_signpost.
/// Aparece en Instruments cuando agregas el instrumento "os_signpost".
///
enum PerformanceLogger {
    
    // MARK: - Instances per category
    
    static let scroll = make(.scroll)
    static let rendering = make(.rendering)
    static let networking = make(.networking)
    static let persistence = make(.persistence)
    static let audio = make(.audio)
    
    private static func make(_ category: PerformanceCategory) -> OSSignposter {
        OSSignposter(subsystem: category.subsystem, category: category.rawValue)
    }
}

// MARK: - Convenience API

extension OSSignposter {
    
    /// Mide un bloque síncrono y reporta el tiempo a Instruments.
    @discardableResult
    func measure<T>(_ name: StaticString, _ block: () throws -> T) rethrows -> T {
        let state = beginInterval(name)
        defer { endInterval(name, state) }
        return try block()
    }
    
    /// Mide un bloque asíncrono y reporta el tiempo a Instruments.
    @discardableResult
    func measure<T>(_ name: StaticString, _ block: () async throws -> T) async rethrows -> T {
        let state = beginInterval(name)
        defer { endInterval(name, state) }
        return try await block()
    }
    
    /// Para mediciones manuales que no caben en un bloque (ej: una operación que arranca y termina en métodos distintos).
    /// Devuelve el estado que necesitas pasar a `end(_:state:)`.
    func begin(_ name: StaticString) -> OSSignpostIntervalState {
        beginInterval(name)
    }
    
    func end(_ name: StaticString, _ state: OSSignpostIntervalState) {
        endInterval(name, state)
    }
    
    /// Emite un evento puntual (no un intervalo). Útil para marcar eventos en el timeline.
    func event(_ name: StaticString, _ message: String = "") {
        emitEvent(name, "\(message)")
    }
}
