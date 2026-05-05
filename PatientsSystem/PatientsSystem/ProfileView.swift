//
//  ProfileView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var nombre = "Dra. / Dr. Apellido"
    @State private var especialidad = "Especialidad"
    @State private var telefono = "555-000-0000"
    @State private var email = "doctor@clinica.com"
    @State private var bio = "Breve descripción del perfil profesional."

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.tint.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "stethoscope.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.tint)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Nombre", text: $nombre)
                            .font(.headline)
                        TextField("Especialidad", text: $especialidad)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Contacto") {
                TextField("Teléfono", text: $telefono)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Acerca de") {
                TextEditor(text: $bio)
                    .frame(minHeight: 120)
            }

            Section {
                Button(role: .destructive) {
                    // Acción de cerrar sesión futura
                } label: {
                    Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
