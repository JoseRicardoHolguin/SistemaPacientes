//
//  ContentView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = PatientStore()
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
                    }
                    .tabItem {
                        Label("Citas", systemImage: "calendar")
                    }
                    .tag(Tab.appointments)

                    NavigationStack {
                        PatientsListView()
                            .environmentObject(store)
                    }
                    .tabItem {
                        Label("Pacientes", systemImage: "person.3")
                    }
                    .tag(Tab.patients)

                    NavigationStack {
                        ProfileView()
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
