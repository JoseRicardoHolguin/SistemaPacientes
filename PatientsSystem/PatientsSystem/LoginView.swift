//
//  LoginView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct LoginView: View {
    var onContinue: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?
    @State private var appear = false

    enum Field {
        case user, pass
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente sutil
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

                // Marca minimalista
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

                // Tarjeta de login
                VStack(spacing: 16) {
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
                            .onSubmit {
                                focusedField = .pass
                            }
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contraseña")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        SecureField("••••••••", text: $password)
                            .focused($focusedField, equals: .pass)
                            .submitLabel(.go)
                            .onSubmit(continueAction)
                            .padding(12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button(action: continueAction) {
                        HStack {
                            Text("Entrar")
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

                    // Pie minimal
                    Text("Esta pantalla es de adorno por ahora")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func continueAction() {
        // Puedes validar campos si lo deseas; por ahora solo continúa
        onContinue()
    }

    private func hideKeyboard() {
        focusedField = nil
    }
}

#Preview {
    LoginView(onContinue: {})
}
