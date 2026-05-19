//
//  LoginView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct LoginView: View {
    // Callbacks hacia el host (ContentView)
    var onLogin: (_ username: String, _ password: String) -> Void
    var onRegister: (_ username: String, _ password: String) -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirm: String = ""
    @State private var selectedTab: Tab = .login
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?
    @State private var appear = false

    enum Field { case user, pass, confirm }
    enum Tab: String, CaseIterable, Identifiable {
        case login = "Iniciar sesión"
        case register = "Registrarse"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 20)

                header

                VStack(spacing: 16) {
                    Picker("", selection: $selectedTab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    formFields

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(action: primaryAction) {
                        HStack {
                            Text(selectedTab == .login ? "Entrar" : "Crear cuenta")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
                )
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .onAppear { appear = true }
        .onTapGesture { hideKeyboard() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.tint)
            }
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appear)

            Text("Administración de Pacientes")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.05), value: appear)
        }
    }

    @ViewBuilder
    private var formFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Usuario")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField("tu.usuario", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .focused($focusedField, equals: .user)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .pass }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                SecureField("••••••••", text: $password)
                    .focused($focusedField, equals: .pass)
                    .submitLabel(selectedTab == .login ? .go : .next)
                    .onSubmit {
                        if selectedTab == .login { primaryAction() }
                        else { focusedField = .confirm }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if selectedTab == .register {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirmar contraseña")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    SecureField("••••••••", text: $confirm)
                        .focused($focusedField, equals: .confirm)
                        .submitLabel(.go)
                        .onSubmit(primaryAction)
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func primaryAction() {
        errorMessage = nil
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass = password

        guard !user.isEmpty, !pass.isEmpty else {
            errorMessage = "Usuario y contraseña son obligatorios."
            return
        }

        switch selectedTab {
        case .login:
            onLogin(user, pass)
        case .register:
            guard pass == confirm else {
                errorMessage = "Las contraseñas no coinciden."
                return
            }
            onRegister(user, pass)
        }
    }

    private func hideKeyboard() {
        focusedField = nil
    }
}

#Preview {
    LoginView(
        onLogin: { _, _ in },
        onRegister: { _, _ in }
    )
}

