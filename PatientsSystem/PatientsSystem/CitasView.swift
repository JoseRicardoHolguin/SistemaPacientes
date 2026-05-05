//
//  CitasView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct CitasView: View {
    @State private var showingNewAppointment = false
    @State private var appointments: [Appointment] = [
        Appointment(titulo: "Consulta de control", fecha: Date().addingTimeInterval(3600 * 24)),
        Appointment(titulo: "Seguimiento", fecha: Date().addingTimeInterval(3600 * 48))
    ]

    var body: some View {
        List {
            ForEach(appointments) { appt in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appt.titulo)
                            .font(.headline)
                        Text(appt.fecha.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(.tint)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Citas")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewAppointment = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Agregar cita")
            }
        }
        .sheet(isPresented: $showingNewAppointment) {
            NavigationStack {
                NewAppointmentView { new in
                    appointments.append(new)
                }
                .navigationTitle("Nueva cita")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        appointments.remove(atOffsets: offsets)
    }
}

struct Appointment: Identifiable, Hashable {
    let id = UUID()
    var titulo: String
    var fecha: Date
}

private struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var titulo: String = ""
    @State private var fecha: Date = Date()

    var onSave: (Appointment) -> Void

    var body: some View {
        Form {
            Section("Detalle") {
                TextField("Título de la cita", text: $titulo)
                DatePicker("Fecha y hora", selection: $fecha, displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "es_MX"))
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    onSave(Appointment(titulo: titulo, fecha: fecha))
                    dismiss()
                }
                .disabled(titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CitasView()
    }
}
