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
    @State private var showAll = false // Toggle para ver historial completo

    private var todaysAppointmentsBase: [Appointment] {
        appointmentsStore.appointments(onSameDayAs: Date())
    }

    private var filteredAppointments: [Appointment] {
        let base: [Appointment]
        if showAll {
            base = appointmentsStore.appointments
        } else {
            base = todaysAppointmentsBase
        }

        let sorted = base.sorted { $0.fecha < $1.fecha }

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sorted }

        return sorted.filter { appt in
            let patientName = appt.patientId.flatMap { id in
                patientStore.patients.first(where: { $0.id == id })?.nombre
            } ?? ""
            return appt.titulo.localizedCaseInsensitiveContains(trimmed)
                || (appt.notas ?? "").localizedCaseInsensitiveContains(trimmed)
                || patientName.localizedCaseInsensitiveContains(trimmed)
                || appt.estado.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        List {
            if filteredAppointments.isEmpty {
                ContentUnavailableView(showAll ? "Sin citas" : "Sin citas hoy",
                                       systemImage: "calendar.badge.exclamationmark",
                                       description: Text(showAll ? "No hay citas registradas." : "No hay citas programadas para hoy."))
            } else {
                ForEach(filteredAppointments) { appt in
                    NavigationLink {
                        AppointmentFullDetailView(appointment: appt)
                            .environmentObject(appointmentsStore)
                            .environmentObject(patientStore)
                    } label: {
                        AppointmentRow(appointment: appt,
                                       patient: appt.patientId.flatMap { id in
                                           patientStore.patients.first(where: { $0.id == id })
                                       })
                    }
                }
                .onDelete(perform: deleteAppointments)
            }
        }
        .navigationTitle(showAll ? "Citas" : "Citas de hoy")
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
            ToolbarItem(placement: .navigationBarLeading) {
                Toggle(isOn: $showAll) {
                    Text("Todas")
                }
                .toggleStyle(.switch)
                .accessibilityLabel("Mostrar todas las citas")
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

    // Mapea índices de la lista filtrada al arreglo real del store para evitar crashes
    private func deleteAppointments(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredAppointments[$0].id }
        appointmentsStore.appointments.removeAll { appt in
            itemsToDelete.contains(appt.id)
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
                Text(patient?.nombre.nonEmpty ?? "Sin asignar")
                    .font(.headline)

                // Subtítulo: hora + título de la cita
                HStack(spacing: 8) {
                    Text(appointment.fecha.formatted(date: .abbreviated, time: .shortened))
                    if !appointment.titulo.isEmpty {
                        Text("• \(appointment.titulo)")
                    }
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

// Vista de detalle enriquecido: datos de la cita, historial del paciente y fotos del paciente
private struct AppointmentFullDetailView: View {
    @EnvironmentObject var appointmentsStore: AppointmentsStore
    @EnvironmentObject var patientStore: PatientStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Appointment
    private let patient: Patient?

    init(appointment: Appointment, patient: Patient? = nil) {
        _draft = State(initialValue: appointment)
        self.patient = patient
    }

    private var linkedPatient: Patient? {
        if let p = patient { return p }
        guard let id = draft.patientId else { return nil }
        return patientStore.patients.first(where: { $0.id == id })
    }

    private var patientHistory: [Appointment] {
        guard let pid = draft.patientId else { return [] }
        return appointmentsStore.appointments
            .filter { $0.patientId == pid }
            .sorted { $0.fecha > $1.fecha }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Encabezado: Paciente + fecha/estado
                headerSection

                // Información editable de la cita
                infoSection

                // Historial de citas del paciente
                historySection

                // Fotos del paciente (solo lectura)
                photosSection
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
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

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let data = linkedPatient?.profilePhotoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Image(systemName: linkedPatient?.fotoSystemName ?? "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text((linkedPatient?.nombre ?? "").nonEmpty ?? "Sin asignar")
                        .font(.headline)
                    Text(draft.fecha.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(draft.estado.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(color(for: draft.estado).opacity(0.15)))
                    .foregroundStyle(color(for: draft.estado))
            }
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                Text("Información de la cita")
                    .font(.title3.weight(.semibold))

                TextField("Título", text: $draft.titulo)
                    .textFieldStyle(.roundedBorder)

                Picker("Estado", selection: $draft.estado) {
                    ForEach(AppointmentStatus.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)

                DatePicker("Fecha y hora",
                           selection: $draft.fecha,
                           displayedComponents: [.date, .hourAndMinute])
                    .environment(\.locale, Locale(identifier: "es_MX"))

                // Asignar/ cambiar paciente
                Picker("Paciente", selection: Binding<UUID?>(
                    get: { draft.patientId },
                    set: { draft.patientId = $0 }
                )) {
                    Text("Sin asignar").tag(UUID?.none)
                    ForEach(patientStore.patients) { p in
                        Text(p.nombre.isEmpty ? "Sin nombre" : p.nombre).tag(Optional(p.id))
                    }
                }

                // Notas / Tratamiento (reutilizamos notas)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notas / Tratamiento")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextEditor(text: Binding(
                        get: { draft.notas ?? "" },
                        set: { draft.notas = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.2))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historial de citas")
                .font(.title3.weight(.semibold))

            if patientHistory.isEmpty {
                Text("Sin historial.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(patientHistory) { appt in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appt.fecha.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.semibold))
                            Text(appt.titulo)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(appt.estado.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(color(for: appt.estado).opacity(0.12)))
                            .foregroundStyle(color(for: appt.estado))
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fotografías del paciente")
                .font(.title3.weight(.semibold))

            if let images = linkedPatient?.fotos, !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { _, data in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Sin fotografías.")
                    .foregroundStyle(.secondary)
            }
        }
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
                    Text("Sin asignar").tag(UUID?.none)
                    ForEach(patientStore.patients) { p in
                        Text(p.nombre.isEmpty ? "Sin nombre" : p.nombre).tag(Optional(p.id))
                    }
                }
            }

            Section("Notas / Tratamiento") {
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

// Pequeña ayuda para strings opcionales vacíos
private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

#Preview {
    NavigationStack {
        CitasView()
            .environmentObject(AppointmentsStore())
            .environmentObject(PatientStore())
    }
}
