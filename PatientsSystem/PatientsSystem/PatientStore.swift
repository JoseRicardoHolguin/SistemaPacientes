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
    // Fuente de verdad completa (todos los doctores)
    @Published private(set) var allPatients: [Patient] = [] {
        didSet { saveToDisk() }
    }

    // Vista filtrada para el doctor actual
    @Published var patients: [Patient] = []

    private var cancellables: Set<AnyCancellable> = []
    private weak var session: SessionStore?

    init(session: SessionStore? = nil) {
        self.session = session
        loadFromDisk()
        bindSession()
    }

    func attachSession(_ session: SessionStore) {
        self.session = session
        bindSession()
        refilter()
    }

    private func bindSession() {
        session?.$currentDoctorId
            .sink { [weak self] _ in
                self?.refilter()
            }
            .store(in: &cancellables)
    }

    private func refilter() {
        guard let owner = session?.currentDoctorId else {
            patients = []
            return
        }
        patients = allPatients.filter { $0.ownerDoctorId == owner }
    }

    private func loadFromDisk() {
        do {
            let loaded: [Patient] = try PersistenceService.load([Patient].self, from: .patients)
            allPatients = loaded
        } catch {
            allPatients = []
        }
        refilter()
    }

    private func saveToDisk() {
        do {
            try PersistenceService.save(allPatients, to: .patients)
        } catch {
            // En un MVP, podemos imprimir; en producción, manejar error
            print("Error guardando pacientes: \(error)")
        }
    }

    func add(_ patient: Patient) {
        guard let owner = session?.currentDoctorId else { return }
        var p = patient
        p.ownerDoctorId = owner // forzamos el dueño actual
        allPatients.append(p)
        refilter()
    }

    func update(_ patient: Patient) {
        guard let owner = session?.currentDoctorId else { return }
        guard let idx = allPatients.firstIndex(where: { $0.id == patient.id }) else { return }
        var p = patient
        p.ownerDoctorId = owner // mantenemos el dueño actual
        allPatients[idx] = p
        refilter()
    }

    func remove(at offsets: IndexSet) {
        let ids = offsets.map { patients[$0].id }
        allPatients.removeAll { ids.contains($0.id) }
        refilter()
    }
}

