//
//  Appointment.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation

enum AppointmentStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case pendiente = "Pendiente"
    case confirmada = "Confirmada"
    case realizada = "Realizada"
    case cancelada = "Cancelada"

    var id: String { rawValue }
}

struct Appointment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var titulo: String
    var fecha: Date
    var notas: String?
    var estado: AppointmentStatus
    var patientId: UUID?

    static let example = Appointment(
        titulo: "Consulta de control",
        fecha: Date().addingTimeInterval(3600 * 24),
        notas: "Revisar radiografías",
        estado: .pendiente,
        patientId: nil
    )
}
