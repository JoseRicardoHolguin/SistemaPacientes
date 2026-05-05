//
//  AppointmentsStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import Combine

final class AppointmentsStore: ObservableObject {
    @Published var appointments: [Appointment] = [
        .example,
        Appointment(
            titulo: "Limpieza dental",
            fecha: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
            notas: "Paciente nervioso, explicar procedimiento",
            estado: .confirmada,
            patientId: nil
        )
    ]

    func add(_ appointment: Appointment) {
        appointments.append(appointment)
    }

    func update(_ appointment: Appointment) {
        guard let idx = appointments.firstIndex(where: { $0.id == appointment.id }) else { return }
        appointments[idx] = appointment
    }

    // Versión independiente de SwiftUI
    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            appointments.remove(at: index)
        }
    }

    func appointments(onSameDayAs date: Date) -> [Appointment] {
        let cal = Calendar.current
        return appointments.filter { cal.isDate($0.fecha, inSameDayAs: date) }
    }
}
