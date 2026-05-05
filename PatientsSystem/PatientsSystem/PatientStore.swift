//
//  PatientStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import Combine
import SwiftUI

final class PatientStore: ObservableObject {
    @Published var patients: [Patient] = [
        .example,
        Patient(
            nombre: "María López",
            celular: "555-987-6543",
            estatus: .nuevo,
            diagnostico: "Primera consulta",
            proximaCita: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            notas: "Traer estudios previos.",
            fotoSystemName: "person.crop.circle.fill"
        ),
        Patient(
            nombre: "Carlos Ruiz",
            celular: "555-111-2222",
            estatus: .finalizado,
            diagnostico: "Tratamiento concluido",
            proximaCita: nil,
            notas: "Dar seguimiento por teléfono.",
            fotoSystemName: "person.crop.circle"
        )
    ]

    func add(_ patient: Patient) {
        patients.append(patient)
    }

    func update(_ patient: Patient) {
        guard let idx = patients.firstIndex(where: { $0.id == patient.id }) else { return }
        patients[idx] = patient
    }

    func remove(at offsets: IndexSet) {
        patients.remove(atOffsets: offsets)
    }
}
