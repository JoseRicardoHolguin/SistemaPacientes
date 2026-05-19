//
//  AuthStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import CryptoKit
import SwiftUI
import Combine

struct AuthUser: Codable, Equatable {
    let doctorId: UUID
    let passwordHash: String
}

final class AuthStore: SwiftUI.ObservableObject {
    // Publicamos algo para ayudar al compilador/observar cambios si hiciera falta
    @Published private(set) var usersCount: Int = 0

    private let defaults = UserDefaults.standard
    private let key = "auth.users" // almacena [String: AuthUser] serializado

    // username (lowercased) -> AuthUser
    private var users: [String: AuthUser] = [:] {
        didSet { usersCount = users.count }
    }

    init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: AuthUser].self, from: data) {
            users = decoded
        }
        usersCount = users.count
    }

    func register(username raw: String, password: String) throws -> UUID {
        let username = sanitize(raw)
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }
        guard users[username] == nil else {
            throw AuthError.usernameTaken
        }
        let doctorId = UUID()
        let hash = hashPassword(password)
        users[username] = AuthUser(doctorId: doctorId, passwordHash: hash)
        persist()
        return doctorId
    }

    func login(username raw: String, password: String) throws -> UUID {
        let username = sanitize(raw)
        guard let user = users[username] else { throw AuthError.userNotFound }
        let hash = hashPassword(password)
        guard user.passwordHash == hash else { throw AuthError.wrongPassword }
        return user.doctorId
    }

    func userExists(_ raw: String) -> Bool {
        users[sanitize(raw)] != nil
    }

    private func sanitize(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(users) {
            defaults.set(data, forKey: key)
        }
    }

    enum AuthError: LocalizedError {
        case invalidInput
        case usernameTaken
        case userNotFound
        case wrongPassword

        var errorDescription: String? {
            switch self {
            case .invalidInput: return "Usuario y contraseña son obligatorios."
            case .usernameTaken: return "El usuario ya existe."
            case .userNotFound: return "Usuario no encontrado."
            case .wrongPassword: return "Contraseña incorrecta."
            }
        }
    }
}
