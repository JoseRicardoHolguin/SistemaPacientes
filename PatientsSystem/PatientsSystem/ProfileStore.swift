//
//  ProfileStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import Combine

struct DoctorProfile: Codable, Equatable {
    var id: UUID = UUID()
    var nombre: String
    var especialidad: String
    var telefono: String
    var email: String
    var bio: String
    var profilePhotoData: Data? = nil
}

final class ProfileStore: ObservableObject {
    // Perfil visible del doctor actual
    @Published private(set) var profile: DoctorProfile = DoctorProfile(
        nombre: "Dra. / Dr.",
        especialidad: "",
        telefono: "",
        email: "",
        bio: "",
        profilePhotoData: nil
    )

    // Todos los perfiles por doctorId
    private var profilesByDoctor: [UUID: DoctorProfile] = [:] {
        didSet { saveToDisk() }
    }

    private var cancellables: Set<AnyCancellable> = []
    private weak var session: SessionStore?

    init(session: SessionStore? = nil) {
        self.session = session
        loadFromDisk()
        bindSession()
        refocusToCurrentDoctor()
    }

    func attachSession(_ session: SessionStore) {
        self.session = session
        bindSession()
        refocusToCurrentDoctor()
    }

    func update(_ newProfile: DoctorProfile) {
        guard let owner = session?.currentDoctorId else {
            // Sin sesión, solo actualiza el publicado (no persistimos)
            profile = newProfile
            return
        }
        profilesByDoctor[owner] = newProfile
        profile = newProfile
    }

    // MARK: - Private

    private func bindSession() {
        session?.$currentDoctorId
            .sink { [weak self] _ in
                self?.refocusToCurrentDoctor()
            }
            .store(in: &cancellables)
    }

    private func refocusToCurrentDoctor() {
        guard let owner = session?.currentDoctorId else {
            // Sin sesión: perfil por defecto
            profile = DoctorProfile(
                nombre: "Dra. / Dr.",
                especialidad: "",
                telefono: "",
                email: "",
                bio: "",
                profilePhotoData: nil
            )
            return
        }
        if let saved = profilesByDoctor[owner] {
            profile = saved
        } else {
            // Crear perfil base para este doctor y persistir
            let fresh = DoctorProfile(
                id: owner,
                nombre: "Dra. / Dr.",
                especialidad: "",
                telefono: "",
                email: "",
                bio: "",
                profilePhotoData: nil
            )
            profilesByDoctor[owner] = fresh
            profile = fresh
        }
    }

    private func loadFromDisk() {
        do {
            let loaded: [UUID: DoctorProfile] = try PersistenceService.load([UUID: DoctorProfile].self, from: .profiles)
            profilesByDoctor = loaded
        } catch {
            profilesByDoctor = [:]
        }
    }

    private func saveToDisk() {
        do {
            try PersistenceService.save(profilesByDoctor, to: .profiles)
        } catch {
            print("Error guardando perfiles: \(error)")
        }
    }
}

