//
//  UserReportsHistoryView.swift
//  centinela SV
//
//  Created on 18/11/25.
//

import SwiftUI

// MARK: - User Reports History View
struct UserReportsHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let reports: [Report]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.4745, green: 0.8392, blue: 0.9765, alpha: 1.0)), Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0))],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if reports.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Sin reportes aún")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Tus reportes aparecerán aquí")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary card
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total de Reportes")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(reports.count)")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 8) {
                                        reportTypeBreakdown
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // Reports list
                            ForEach(reports) { report in
                                UserReportCard(report: report)
                            }
                        }
                        .padding()
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Mi Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var reportTypeBreakdown: some View {
        VStack(alignment: .trailing, spacing: 4) {
            let types = Dictionary(grouping: reports, by: { $0.tipo })
            ForEach(types.keys.sorted(), id: \.self) { tipo in
                HStack(spacing: 6) {
                    Text("\(types[tipo]?.count ?? 0)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(tipoColor(tipo))
                    Image(systemName: tipoIcon(tipo))
                        .font(.caption)
                        .foregroundColor(tipoColor(tipo))
                }
            }
        }
    }
    
    private func tipoIcon(_ tipo: String) -> String {
        switch tipo {
        case "Inundación": return "water.waves"
        case "Incendio": return "flame.fill"
        case "Sismo": return "waveform.path.ecg"
        case "Otro": return "exclamationmark.triangle.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
    
    private func tipoColor(_ tipo: String) -> Color {
        switch tipo {
        case "Inundación": return .blue
        case "Incendio": return .red
        case "Sismo": return .orange
        case "Otro": return .purple
        default: return .gray
        }
    }
}

// MARK: - User Report Card
struct UserReportCard: View {
    let report: Report
    
    var body: some View {
        NavigationLink(destination: ReportDetailView(report: report)) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(tipoColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: tipoIcon)
                        .font(.title3)
                        .foregroundColor(tipoColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.tipo)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !report.descripcion.isEmpty {
                        Text(report.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        if let fecha = report.fechaDate {
                            Label(formatDate(fecha), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !report.estado.isEmpty {
                            Text(report.estado)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(estadoColor(report.estado))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(estadoColor(report.estado).opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var tipoIcon: String {
        switch report.tipo {
        case "Inundación": return "water.waves"
        case "Incendio": return "flame.fill"
        case "Sismo": return "waveform.path.ecg"
        case "Otro": return "exclamationmark.triangle.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
    
    private var tipoColor: Color {
        switch report.tipo {
        case "Inundación": return .blue
        case "Incendio": return .red
        case "Sismo": return .orange
        case "Otro": return .purple
        default: return .gray
        }
    }
    
    private func estadoColor(_ estado: String) -> Color {
        switch estado.lowercased() {
        case "activo": return .green
        case "resuelto": return .blue
        case "en proceso": return .orange
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
