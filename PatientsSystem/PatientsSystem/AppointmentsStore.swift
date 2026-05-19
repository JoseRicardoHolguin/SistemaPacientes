//
//  AppointmentsStore.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import Foundation
import Combine

final class AppointmentsStore: ObservableObject {
    // Fuente de verdad completa (todos los doctores)
    @Published private(set) var allAppointments: [Appointment] = [] {
        didSet { saveToDisk() }
    }

    // Vista filtrada para el doctor actual
    @Published var appointments: [Appointment] = []

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
            appointments = []
            return
        }
        appointments = allAppointments.filter { $0.ownerDoctorId == owner }
    }

    private func loadFromDisk() {
        do {
            let loaded: [Appointment] = try PersistenceService.load([Appointment].self, from: .appointments)
            allAppointments = loaded
        } catch {
            allAppointments = []
        }
        refilter()
    }

    private func saveToDisk() {
        do {
            try PersistenceService.save(allAppointments, to: .appointments)
        } catch {
            print("Error guardando citas: \(error)")
        }
    }

    func add(_ appointment: Appointment) {
        guard let owner = session?.currentDoctorId else { return }
        var a = appointment
        a.ownerDoctorId = owner // forzamos el dueño actual
        allAppointments.append(a)
        refilter()
    }

    func update(_ appointment: Appointment) {
        guard let owner = session?.currentDoctorId else { return }
        guard let idx = allAppointments.firstIndex(where: { $0.id == appointment.id }) else { return }
        var a = appointment
        a.ownerDoctorId = owner // mantenemos el dueño actual
        allAppointments[idx] = a
        refilter()
    }

    func remove(at offsets: IndexSet) {
        let ids = offsets.map { appointments[$0].id }
        allAppointments.removeAll { ids.contains($0.id) }
        refilter()
    }

    func appointments(onSameDayAs date: Date) -> [Appointment] {
        let cal = Calendar.current
        return appointments.filter { cal.isDate($0.fecha, inSameDayAs: date) }
    }
}

