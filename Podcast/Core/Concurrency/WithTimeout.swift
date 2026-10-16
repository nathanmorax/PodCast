//
//  WithTimeout.swift
//  Podcast
//

import Foundation

enum TimeoutError: Error {
    case timedOut
}

/// Ejecuta una operación async con un timeout.
/// Si pasa el tiempo límite, lanza TimeoutError.timedOut.
func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Tarea principal
        group.addTask {
            try await operation()
        }
        
        // Tarea del timer
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError.timedOut
        }
        
        // La primera que termine gana
        guard let result = try await group.next() else {
            throw TimeoutError.timedOut
        }
        
        group.cancelAll()
        return result
    }
}
