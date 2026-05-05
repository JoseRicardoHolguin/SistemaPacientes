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
}

final class ProfileStore: ObservableObject {
    @Published var profile = DoctorProfile(
        nombre: "Dra. / Dr. Apellido",
        especialidad: "Odontología",
        telefono: "555-000-0000",
        email: "doctor@clinica.com",
        bio: "Breve descripción del perfil profesional."
    )

    func update(_ newProfile: DoctorProfile) {
        profile = newProfile
    }
}
