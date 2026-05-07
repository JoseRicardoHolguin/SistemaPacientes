//
//  Patient.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import SwiftUI

enum PatientStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case nuevo = "Nuevo"
    case enCurso = "En curso"
    case finalizado = "Finalizado"

    var id: String { rawValue }
}

struct Patient: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var celular: String
    var estatus: PatientStatus
    var diagnostico: String
    var proximaCita: Date?
    var notas: String
    // Placeholder por SF Symbol cuando no hay imagen real
    var fotoSystemName: String?

    // Fotos adjuntas a notas
    var fotos: [Data] = []

    // Foto de perfil real (opcional)
    var profilePhotoData: Data? = nil

    static let example = Patient(
        nombre: "Juan Pérez",
        celular: "555-123-4567",
        estatus: .enCurso,
        diagnostico: "Revisión general",
        proximaCita: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        notas: "Paciente refiere dolor leve.",
        fotoSystemName: "person.crop.circle",
        fotos: [],
        profilePhotoData: nil
    )
}
