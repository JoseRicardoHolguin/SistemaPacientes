//
//  ContentView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var session = SessionStore()
    @StateObject private var auth = AuthStore()

    @StateObject private var patientStore = PatientStore()
    @StateObject private var appointmentsStore = AppointmentsStore()
    @StateObject private var profileStore = ProfileStore()

    @State private var selectedTab: Tab = .patients
    @State private var cancellables: Set<AnyCancellable> = []

    // Gestión de inactividad
    @Environment(\.scenePhase) private var scenePhase
    @State private var idleTimer: Timer?
    @State private var warningTimer: Timer?
    @State private var showIdleWarning = false

    enum Tab: Hashable { case appointments, patients, profile }

    var body: some View {
        Group {
            if session.currentDoctorId != nil {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        CitasView()
                            .environmentObject(appointmentsStore)
                            .environmentObject(patientStore)
                            .environment(\.selectedTab, $selectedTab)
                    }
                    .tabItem { Label("Citas", systemImage: "calendar") }
                    .tag(Tab.appointments)
                    .onAppear { resetIdleTimers() }

                    NavigationStack {
                        PatientsListView()
                            .environmentObject(patientStore)
                            .environment(\.selectedTab, $selectedTab)
                    }
                    .tabItem { Label("Pacientes", systemImage: "person.3") }
                    .tag(Tab.patients)
                    .onAppear { resetIdleTimers() }

                    NavigationStack {
                        ProfileView()
                            .environmentObject(profileStore)
                            .environment(\.selectedTab, $selectedTab)
                            .environment(\.isLoggedInBinding, Binding(
                                get: { session.currentDoctorId != nil },
                                set: { newValue in if !newValue { session.logout() } }
                            ))
                    }
                    .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
                    .tag(Tab.profile)
                    .onAppear { resetIdleTimers() }
                }
                .onAppear {
                    // Adjuntar sesión a stores
                    patientStore.attachSession(session)
                    appointmentsStore.attachSession(session)
                    profileStore.attachSession(session)
                    setupSync()

                    // Inicia control de inactividad
                    startIdleTimers()
                }
                .onDisappear {
                    cancelIdleTimers()
                }
                // Cambiar de tab es actividad
                .onChange(of: selectedTab) { _, _ in
                    resetIdleTimers()
                }
                // Cambios de estado de la escena
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        // Volvió a primer plano: reinicia timers
                        resetIdleTimers()
                    case .inactive, .background:
                        // Por seguridad, cierra sesión al ir a background
                        session.logout()
                        cancelIdleTimers()
                    @unknown default:
                        break
                    }
                }
                // Alerta de advertencia antes de cerrar por inactividad
                .alert("Sesión por expirar", isPresented: $showIdleWarning) {
                    Button("Cerrar sesión", role: .destructive) {
                        session.logout()
                        cancelIdleTimers()
                    }
                    Button("Seguir conectado") {
                        // Usuario indica actividad: reiniciar timers
                        resetIdleTimers()
                    }
                } message: {
                    Text("No detectamos actividad. La sesión se cerrará en 10 segundos.")
                }
            } else {
                NavigationStack {
                    LoginView(
                        onLogin: { username, password in
                            do {
                                let id = try auth.login(username: username, password: password)
                                session.currentDoctorId = id
                            } catch {
                                print("Login error: \(error.localizedDescription)")
                            }
                        },
                        onRegister: { username, password in
                            do {
                                let id = try auth.register(username: username, password: password)
                                session.currentDoctorId = id
                            } catch {
                                print("Register error: \(error.localizedDescription)")
                            }
                        }
                    )
                    .navigationTitle("Acceso")
                    .environment(\.isLoggedInBinding, Binding(
                        get: { session.currentDoctorId != nil },
                        set: { newValue in if !newValue { session.logout() } }
                    ))
                }
            }
        }
    }

    // MARK: - Inactivity timers

    // 5 minutos total, avisar 10 s antes
    private let totalTimeout: TimeInterval = 300
    private let warningLeadTime: TimeInterval = 10

    private func startIdleTimers() {
        cancelIdleTimers()
        guard session.currentDoctorId != nil else { return }

        // Programa la advertencia
        let warningInterval = max(0, totalTimeout - warningLeadTime)
        warningTimer = Timer.scheduledTimer(withTimeInterval: warningInterval, repeats: false) { _ in
            // Mostrar alerta de advertencia
            showIdleWarning = true
        }

        // Programa el cierre
        idleTimer = Timer.scheduledTimer(withTimeInterval: totalTimeout, repeats: false) { _ in
            session.logout()
            cancelIdleTimers()
        }
    }

    private func resetIdleTimers() {
        guard session.currentDoctorId != nil else { return }
        showIdleWarning = false
        startIdleTimers()
    }

    private func cancelIdleTimers() {
        warningTimer?.invalidate()
        idleTimer?.invalidate()
        warningTimer = nil
        idleTimer = nil
        showIdleWarning = false
    }

    // MARK: - Existing sync

    private func setupSync() {
        guard cancellables.isEmpty else { return }

        patientStore.$patients
            .receive(on: DispatchQueue.main)
            .sink { [weak appointmentsStore, weak session] patients in
                guard let appointmentsStore,
                      let owner = session?.currentDoctorId else { return }

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
                            ownerDoctorId: owner,
                            titulo: patient.nombre.isEmpty ? "Consulta" : "Consulta de \(patient.nombre)",
                            fecha: next,
                            notas: nil,
                            estado: .pendiente,
                            patientId: patient.id
                        )
                        appointmentsStore.add(newAppointment)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

#Preview {
    ContentView()
}

