//
//  ProfileView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.isLoggedInBinding) private var isLoggedInBinding

    @State private var draft: DoctorProfile = DoctorProfile(
        nombre: "",
        especialidad: "",
        telefono: "",
        email: "",
        bio: "",
        profilePhotoData: nil
    )

    // Picker de foto de perfil del doctor
    @State private var profilePickerItem: PhotosPickerItem? = nil

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        if let data = draft.profilePhotoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.secondary.opacity(0.3)))
                        } else {
                            Circle()
                                .fill(.tint.opacity(0.12))
                                .frame(width: 72, height: 72)
                                .overlay {
                                    Image(systemName: "stethoscope.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.tint)
                                }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Nombre", text: $draft.nombre)
                            .font(.headline)
                        TextField("Especialidad", text: $draft.especialidad)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $profilePickerItem, matching: .images) {
                                Label("Cambiar foto", systemImage: "photo")
                            }
                            .onChange(of: profilePickerItem) { _, item in
                                guard let item else { return }
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self) {
                                        draft.profilePhotoData = data
                                    }
                                    profilePickerItem = nil
                                }
                            }

                            if draft.profilePhotoData != nil {
                                Button {
                                    draft.profilePhotoData = nil
                                } label: {
                                    Label("Quitar foto", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                        .buttonStyle(.borderless)
                        .padding(.top, 4)
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
                    // Guardamos por si hay cambios pendientes
                    profileStore.update(draft)
                    // Regresamos a la pantalla de inicio de sesión
                    isLoggedInBinding?.wrappedValue = false
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
            .environment(\.isLoggedInBinding, .constant(true))
    }
}
