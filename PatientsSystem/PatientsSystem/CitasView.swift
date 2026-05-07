//
//  CitasView.swift
//  PatientsSystem
//
//  Created by ITIT on 05/05/26.
//

import SwiftUI

struct CitasView: View {
    @EnvironmentObject var appointmentsStore: AppointmentsStore
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.selectedTab) private var selectedTab

    @State private var showingNewAppointment = false
    @State private var searchText = ""

    private var todaysAppointments: [Appointment] {
        let base = appointmentsStore.appointments(onSameDayAs: Date())
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return base.sorted { $0.fecha < $1.fecha }
        }
        return base.filter { appt in
            let patientName = appt.patientId.flatMap { id in
                patientStore.patients.first(where: { $0.id == id })?.nombre
            } ?? ""
            return appt.titulo.localizedCaseInsensitiveContains(searchText)
                || (appt.notas ?? "").localizedCaseInsensitiveContains(searchText)
                || patientName.localizedCaseInsensitiveContains(searchText)
                || appt.estado.rawValue.localizedCaseInsensitiveContains(searchText)
        }
        .sorted { $0.fecha < $1.fecha }
    }

    var body: some View {
        List {
            if todaysAppointments.isEmpty {
                ContentUnavailableView("Sin citas hoy",
                                       systemImage: "calendar.badge.exclamationmark",
                                       description: Text("No hay citas programadas para hoy."))
            } else {
                ForEach(todaysAppointments) { appt in
                    NavigationLink {
                        AppointmentDetailView(appointment: appt)
                    } label: {
                        AppointmentRow(appointment: appt,
                                       patient: appt.patientId.flatMap { id in
                                           patientStore.patients.first(where: { $0.id == id })
                                       })
                    }
                }
                .onDelete(perform: appointmentsStore.remove)
            }
        }
        .navigationTitle("Citas de hoy")
        .searchable(text: $searchText, prompt: "Buscar por paciente, título, estado…")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    selectedTab?.wrappedValue = .patients
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Regresar")
            }
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
                NewAppointmentView()
                    .environmentObject(appointmentsStore)
                    .environmentObject(patientStore)
                    .navigationTitle("Nueva cita")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct AppointmentRow: View {
    let appointment: Appointment
    let patient: Patient?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                // Título: nombre del paciente o "Sin asignar"
                Text((patient?.nombre.isEmpty == false ? patient!.nombre : "Sin asignar"))
                    .font(.headline)

                // Subtítulo: hora
                HStack(spacing: 8) {
                    Text(appointment.fecha.formatted(date: .omitted, time: .shortened))
                    Text("• \(appointment.titulo)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(appointment.estado.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(color(for: appointment.estado).opacity(0.15))
                )
                .foregroundStyle(color(for: appointment.estado))
        }
        .padding(.vertical, 4)
    }

    private func color(for status: AppointmentStatus) -> Color {
        switch status {
        case .pendiente: return .orange
        case .confirmada: return .blue
        case .realizada: return .green
        case .cancelada: return .red
        }
    }
}

private struct AppointmentDetailView: View {
    @EnvironmentObject var appointmentsStore: AppointmentsStore
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Appointment

    init(appointment: Appointment) {
        _draft = State(initialValue: appointment)
    }

    var body: some View {
        Form {
            Section("Información") {
                TextField("Título", text: $draft.titulo)
                Picker("Estado", selection: $draft.estado) {
                    ForEach(AppointmentStatus.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                DatePicker("Fecha y hora",
                           selection: $draft.fecha,
                           displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "es_MX"))
            }

            Section("Paciente") {
                Picker("Asignar a", selection: Binding(
                    get: { draft.patientId ?? UUID?.none as UUID? },
                    set: { draft.patientId = $0 }
                )) {
                    Text("Sin asignar").tag(UUID?.none as UUID?)
                    ForEach(patientStore.patients) { p in
                        Text(p.nombre.isEmpty ? "Sin nombre" : p.nombre).tag(Optional(p.id))
                    }
                }
            }

            Section("Notas") {
                TextEditor(text: Binding(
                    get: { draft.notas ?? "" },
                    set: { draft.notas = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 120)
            }
        }
        .navigationTitle("Cita")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    appointmentsStore.update(draft)
                    dismiss()
                }
                .disabled(draft.titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct NewAppointmentView: View {
    @EnvironmentObject var appointmentsStore: AppointmentsStore
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.dismiss) private var dismiss

    @State private var titulo: String = ""
    @State private var fecha: Date = Date()
    @State private var estado: AppointmentStatus = .pendiente
    @State private var notas: String = ""
    @State private var patientId: UUID? = nil

    var body: some View {
        Form {
            Section("Información") {
                TextField("Título", text: $titulo)
                Picker("Estado", selection: $estado) {
                    ForEach(AppointmentStatus.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                DatePicker("Fecha y hora",
                           selection: $fecha,
                           displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "es_MX"))
            }

            Section("Paciente") {
                Picker("Asignar a", selection: $patientId) {
                    Text("Sin asignar").tag(UUID?.none as UUID?)
                    ForEach(patientStore.patients) { p in
                        Text(p.nombre.isEmpty ? "Sin nombre" : p.nombre).tag(Optional(p.id))
                    }
                }
            }

            Section("Notas") {
                TextEditor(text: $notas)
                    .frame(minHeight: 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    let appt = Appointment(
                        titulo: titulo,
                        fecha: fecha,
                        notas: notas.isEmpty ? nil : notas,
                        estado: estado,
                        patientId: patientId
                    )
                    appointmentsStore.add(appt)
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
            .environmentObject(AppointmentsStore())
            .environmentObject(PatientStore())
    }
}
