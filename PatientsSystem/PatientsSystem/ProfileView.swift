//
//  ProfileView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @Environment(\.selectedTab) private var selectedTab
    @State private var draft: DoctorProfile = DoctorProfile(
        nombre: "",
        especialidad: "",
        telefono: "",
        email: "",
        bio: ""
    )

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
                        TextField("Nombre", text: $draft.nombre)
                            .font(.headline)
                        TextField("Especialidad", text: $draft.especialidad)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Contacto") {
                TextField("Teléfono", text: $draft.telefono)
                    .keyboardType(.phonePad)
                TextField("Email", text: $draft.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Acerca de") {
                TextEditor(text: $draft.bio)
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
        .onAppear {
            draft = profileStore.profile
        }
        .toolbar {
            // Flecha personalizada porque esta vista es raíz
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    selectedTab?.wrappedValue = .patients
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Regresar")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    profileStore.update(draft)
                }
                .disabled(draft.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(ProfileStore())
    }
}
