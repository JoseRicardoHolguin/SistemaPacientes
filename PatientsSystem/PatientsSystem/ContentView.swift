//
//  ContentView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var patientStore = PatientStore()
    @StateObject private var appointmentsStore = AppointmentsStore()
    @StateObject private var profileStore = ProfileStore()

    @State private var isLoggedIn = false
    @State private var selectedTab: Tab = .patients

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
}

#Preview {
    ContentView()
}

