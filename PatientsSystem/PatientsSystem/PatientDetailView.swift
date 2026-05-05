//
//  PatientDetailView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct PatientDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Patient
    var onSave: (Patient) -> Void

    init(patient: Patient, onSave: @escaping (Patient) -> Void) {
        self._draft = State(initialValue: patient)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Identificación") {
                TextField("Nombre", text: $draft.nombre)
                TextField("Celular", text: $draft.celular)
                    .keyboardType(.phonePad)

                Picker("Estatus", selection: $draft.estatus) {
                    ForEach(PatientStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Clínico") {
                TextField("Diagnóstico", text: $draft.diagnostico, axis: .vertical)
                    .lineLimit(1...3)

                DatePicker("Próxima cita",
                           selection: Binding(
                            get: { draft.proximaCita ?? Date() },
                            set: { draft.proximaCita = $0 }),
                           displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "es_MX"))
                    .tint(.accentColor)

                Toggle("Sin fecha definida", isOn: Binding(
                    get: { draft.proximaCita == nil },
                    set: { noDate in draft.proximaCita = noDate ? nil : Date() }
                ))
            }

            Section("Notas") {
                TextEditor(text: $draft.notas)
                    .frame(minHeight: 120)
            }

            Section("Foto") {
                Picker("Icono", selection: Binding(
                    get: { draft.fotoSystemName ?? "person.crop.circle" },
                    set: { draft.fotoSystemName = $0 }
                )) {
                    Image(systemName: "person.crop.circle").tag("person.crop.circle")
                    Image(systemName: "person.crop.circle.fill").tag("person.crop.circle.fill")
                    Image(systemName: "person").tag("person")
                    Image(systemName: "person.fill").tag("person.fill")
                }
                .pickerStyle(.menu)
            }
        }
        .navigationTitle(draft.nombre.isEmpty ? "Paciente" : draft.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    onSave(draft)
                    dismiss()
                }
                .disabled(draft.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PatientDetailView(patient: .example) { _ in }
    }
}
