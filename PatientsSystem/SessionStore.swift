//
//  SessionStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import Combine

final class SessionStore: ObservableObject {
    @Published var currentDoctorId: UUID? {
        didSet { persistCurrentDoctorId() }
    }

    private let defaults = UserDefaults.standard
    private let currentKey = "session.currentDoctorId"
    private let mapKey = "session.usernameToDoctorId"

    // username -> UUID string
    private var usernameMap: [String: String] = [:]

    init() {
        if let saved = defaults.string(forKey: currentKey) {
            currentDoctorId = UUID(uuidString: saved)
        } else {
            currentDoctorId = nil
        }
        if let data = defaults.data(forKey: mapKey),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            usernameMap = map
        }
    }

    func resolveDoctorId(for username: String) -> UUID {
        let key = username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = usernameMap[key], let id = UUID(uuidString: existing) {
            return id
        }
        let newId = UUID()
        usernameMap[key] = newId.uuidString
        persistMap()
        return newId
    }

    func logout() {
        currentDoctorId = nil
    }

    private func persistCurrentDoctorId() {
        if let id = currentDoctorId {
            defaults.set(id.uuidString, forKey: currentKey)
        } else {
            defaults.removeObject(forKey: currentKey)
        }
    }

    private func persistMap() {
        if let data = try? JSONEncoder().encode(usernameMap) {
            defaults.set(data, forKey: mapKey)
        }
    }
}

