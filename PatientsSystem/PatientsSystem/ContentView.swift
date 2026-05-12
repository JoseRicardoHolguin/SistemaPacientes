//
//  ContentView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var patientStore = PatientStore()
    @StateObject private var appointmentsStore = AppointmentsStore()
    @StateObject private var profileStore = ProfileStore()

    @State private var isLoggedIn = false
    @State private var selectedTab: Tab = .patients

    // Mantener referencias a los AnyCancellable del sincronizador
    @State private var cancellables: Set<AnyCancellable> = []

    enum Tab: Hashable {
        case appointments
        case patients
        case profile
    }

    var body: some View {
        Group {
            if isLoggedIn {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        CitasView()
                            .environmentObject(appointmentsStore)
                            .environmentObject(patientStore)
                            .environment(\.selectedTab, $selectedTab) // inyectamos binding
                    }
                    .tabItem {
                        Label("Citas", systemImage: "calendar")
                    }
                    .tag(Tab.appointments)

                    NavigationStack {
                        PatientsListView()
                            .environmentObject(patientStore)
                            .environment(\.selectedTab, $selectedTab)
                    }
                    .tabItem {
                        Label("Pacientes", systemImage: "person.3")
                    }
                    .tag(Tab.patients)

                    NavigationStack {
                        ProfileView()
                            .environmentObject(profileStore)
                            .environment(\.selectedTab, $selectedTab)
                    }
                    .tabItem {
                        Label("Perfil", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.profile)
                }
                .onAppear(perform: setupSync)
            } else {
                NavigationStack {
                    LoginView(onContinue: {
                        isLoggedIn = true
                    })
                    .navigationTitle("Inicio de sesión")
                }
            }
        }
    }

    private func setupSync() {
        guard cancellables.isEmpty else { return }

        patientStore.$patients
            .receive(on: DispatchQueue.main)
            .sink { [weak appointmentsStore] patients in
                guard let appointmentsStore else { return }

                let calendar = Calendar.current
                let today = Date()

                for patient in patients {
                    guard let next = patient.proximaCita,
                          calendar.isDate(next, inSameDayAs: today) else { continue }

                    let alreadyExists = appointmentsStore.appointments.contains {
                        $0.patientId == patient.id && calendar.isDate($0.fecha, inSameDayAs: today)
                    }

                    if !alreadyExists {
                        let newAppointment = Appointment(
                            titulo: patient.nombre.isEmpty ? "Consulta" : "Consulta de \(patient.nombre)",
                            fecha: next,
                            notas: nil,
                            estado: .pendiente,
                            patientId: patient.id
                        )
                        appointmentsStore.add(newAppointment)
                    }
                }

                // Limpieza opcional comentada por seguridad (ver explicación previa)
            }
            .store(in: &cancellables)
    }
}

#Preview {
    ContentView()
}
