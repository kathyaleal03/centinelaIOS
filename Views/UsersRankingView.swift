//
//  UsersRankingView.swift
//  centinela SV
//
//  Created on 20/11/25.
//

import SwiftUI

struct UsersRankingView: View {
    @EnvironmentObject var reportVM: ReportViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var initialLoadAttempted = false
    
    // Gather user stats from reports (>=1 report)
    private var userStats: [(userId: Int, userName: String, reportCount: Int, title: UserTitle?)] {
        guard !reportVM.reports.isEmpty else { return [] }
        let grouped = Dictionary(grouping: reportVM.reports.compactMap { r -> (Int, Report)? in
            // Use top-level usuarioId or nested usuario.id (mapped from usuarioId)
            guard let uid = r.usuarioId ?? r.usuario?.id else { return nil }
            return (uid, r)
        }, by: { $0.0 })

        var stats: [(userId: Int, userName: String, reportCount: Int, title: UserTitle?)] = []
        for (uid, tuples) in grouped {
            let reports = tuples.map { $0.1 }
            let count = reports.count
            let name = reports.first(where: { ($0.usuario?.nombre ?? "").isEmpty == false })?.usuario?.nombre ?? "Usuario #\(uid)"
            let title: UserTitle? = count >= 5 ? .estrella : (count >= 3 ? .fiable : nil)
            stats.append((userId: uid, userName: name, reportCount: count, title: title))
        }
        let sorted = stats.sorted { a, b in
            if a.reportCount != b.reportCount { return a.reportCount > b.reportCount }
            return a.userName < b.userName
        }
        return sorted
    }
    
    // Users that have earned titles (>=3 reports)
    private var rankedUsers: [(userId: Int, userName: String, reportCount: Int, title: UserTitle?)] {
        userStats.filter { $0.title != nil }
    }

    // Active users ("más de un reporte") threshold: >=2 reports
    private var activeUsers: [(userId: Int, userName: String, reportCount: Int, title: UserTitle?)] {
        userStats.filter { $0.reportCount >= 2 }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Weather-themed gradient background
                LinearGradient(
                    colors: [Color(#colorLiteral(red: 0.4745, green: 0.8392, blue: 0.9765, alpha: 1.0)), Color(#colorLiteral(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0))],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 18) {
                        // Loading & empty states
                        if reportVM.loadingReports {
                            ProgressView("Cargando reportes...")
                                .tint(.white)
                                .padding(.top, 8)
                        }
                        if !reportVM.loadingReports && reportVM.reports.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text("No se encontraron reportes para generar el ranking todavía.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                if let err = reportVM.error {
                                    Text(err)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                        }
                        // Header stats (always visible)
                        VStack(spacing: 16) {
                            HStack(spacing: 24) {
                                statBlock(value: rankedUsers.count, titleTop: "Usuarios", titleBottom: "Con Título", color: .blue)
                                Divider().frame(height: 60)
                                statBlock(value: rankedUsers.filter { $0.title == .estrella }.count, titleTop: "Usuarios", titleBottom: "Estrella", color: .yellow)
                                Divider().frame(height: 60)
                                statBlock(value: rankedUsers.filter { $0.title == .fiable }.count, titleTop: "Usuarios", titleBottom: "Fiables", color: .blue)
                            }
                            if rankedUsers.isEmpty {
                                Text("Aún no hay usuarios con título. ¡Crea más reportes para subir de nivel!")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Titled users section
                        if !rankedUsers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                                    Text("Usuarios con Título")
                                        .font(.headline)
                                }
                                ForEach(Array(rankedUsers.enumerated()), id: \.element.userId) { index, user in
                                    UserRankCard(
                                        rank: index + 1,
                                        userId: user.userId,
                                        userName: user.userName,
                                        reportCount: user.reportCount,
                                        title: user.title
                                    )
                                }
                            }
                        }

                        // Active users (>=2 reports) section (exclude already titled if also desired?)
                        let activeButNotTitled = activeUsers.filter { $0.title == nil }
                        if !activeButNotTitled.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.3.fill").foregroundColor(.blue)
                                    Text("Usuarios Activos (2+ reportes)")
                                        .font(.headline)
                                }
                                ForEach(activeButNotTitled, id: \.userId) { user in
                                    ActiveUserRow(userName: user.userName, count: user.reportCount)
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Ranking de Usuarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Single initial refresh using auth token
                if !initialLoadAttempted {
                    initialLoadAttempted = true
                    Task {
                        print("[UsersRankingView] -> Initial refreshReports with token present? \(authVM.token != nil)")
                        await reportVM.refreshReports(token: authVM.token)
                    }
                }
            }
            .onChange(of: reportVM.error) { newErr in
                if let e = newErr { print("[UsersRankingView] -> ReportVM error: \(e)") }
            }
        }
    }
}

// MARK: - User Title Enum
enum UserTitle {
    case fiable
    case estrella
    
    var name: String {
        switch self {
        case .fiable: return "Usuario Fiable"
        case .estrella: return "Usuario Estrella"
        }
    }
    
    var icon: String {
        switch self {
        case .fiable: return "checkmark.shield.fill"
        case .estrella: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fiable: return .blue
        case .estrella: return .yellow
        }
    }
}

// MARK: - User Rank Card
struct UserRankCard: View {
    let rank: Int
    let userId: Int
    let userName: String
    let reportCount: Int
    let title: UserTitle?
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank medal
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 50, height: 50)
                
                if rank <= 3 {
                    Image(systemName: "medal.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 6) {
                Text(userName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    if let title = title {
                        HStack(spacing: 4) {
                            Image(systemName: title.icon)
                                .font(.caption)
                                .foregroundColor(title.color)
                            Text(title.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(title.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(title.color.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Report count
            VStack(spacing: 4) {
                Text("\(reportCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text(reportCount == 1 ? "Reporte" : "Reportes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
}

// MARK: - Helpers UI Components
private struct ActiveUserRow: View {
    let userName: String
    let count: Int
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(count) \(count == 1 ? "reporte" : "reportes")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right.circle")
                .foregroundColor(.blue)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

private extension UsersRankingView {
    func statBlock(value: Int, titleTop: String, titleBottom: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(color)
            Text(titleTop)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(titleBottom)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
