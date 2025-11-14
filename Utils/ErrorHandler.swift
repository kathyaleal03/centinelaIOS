//
//  ErrorHandler.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation

struct ErrorHandler {
    static func message(from error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL: return "URL inválida"
            case .requestFailed(let msg): return "Error servidor: \(msg)"
            case .decodingError(_): return "Error procesando datos"
            }
        }
        return error.localizedDescription
    }
}
