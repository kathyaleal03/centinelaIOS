import SwiftUI

struct HomeView: View {
    @StateObject private var alertsVM = AlertsViewModel()
    @EnvironmentObject var reportsVM: ReportViewModel
    @StateObject private var emergVM = EmergenciaViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("region") var userRegion: String = ""
    @State private var showRanking = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CENTINELA")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            HStack(spacing: 8) {
                                if let name = authVM.user?.nombre, !name.isEmpty {
                                    Text("Hola, \(name)")
                                }
                                Text(Date(), style: .date)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Weather summary
                        NavigationLink(destination: WeatherDetailView()) {
                            WeatherStatusView()
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(CardBackground())
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(SectionHeaderOverlay(icon: "thermometer.sun", title: "Clima Actual"))
                                .padding(.horizontal)
                        }

                        // Risk levels
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(icon: "exclamationmark.triangle", title: "Niveles de Riesgo")
                            HStack(spacing: 12) {
                                legendPill(color: .green, text: "Verde")
                                legendPill(color: .yellow, text: "Amarillo")
                                legendPill(color: .orange, text: "Naranja")
                                legendPill(color: .red, text: "Rojo")
                            }
                            Text("Indicadores operativos de la situación actual")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(CardBackground())
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Metrics summary
                        HStack(spacing: 16) {
                            metricBlock(count: alertsVM.alertas.count, label: "Alertas", systemIcon: "bell.fill", color: .orange)
                            metricBlock(count: reportsVM.reports.count, label: "Reportes", systemIcon: "doc.text.fill", color: .blue)
                            metricBlock(count: emergVM.emergencias.count, label: "Emergencias", systemIcon: "phone.fill", color: .red)
                        }
                        .padding(.horizontal)

                        // Recent vertical lists
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(icon: "clock.arrow.circlepath", title: "Actividad Reciente")
                            recentList(title: "Últimas Alertas", items: latestAlerts())
                            Divider()
                            recentList(title: "Últimos Reportes", items: latestReports())
                            Divider()
                            recentList(title: "Últimas Emergencias", items: latestEmergencias())
                        }
                        .padding(16)
                        .background(CardBackground())
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Ranking access compact
                        if !reportsVM.reports.isEmpty {
                            NavigationLink(destination: UsersRankingView().environmentObject(reportsVM)) {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .font(.title3)
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ranking de Usuarios")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Ver usuarios destacados")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity)
                                .background(CardBackground())
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 12)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Text("Inicio").font(.headline) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showRanking = true }) { Image(systemName: "trophy") }
                        .disabled(reportsVM.reports.isEmpty)
                }
            }
            .sheet(isPresented: $showRanking) {
                UsersRankingView()
                    .environmentObject(reportsVM)
                    .environmentObject(authVM)
            }
        }
        .onAppear {
            alertsVM.loadAll()
            reportsVM.fetchReports(token: nil)
            emergVM.loadAll()
        }
    }
}

// MARK: - Helpers for HomeView UI
extension HomeView {
    func legendPill(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text).font(.caption).fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }

    func recentList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            if items.isEmpty {
                Text("Sin datos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(items.prefix(5).enumerated()), id: \.0) { _, line in
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 3)
                            .cornerRadius(1)
                        Text(line)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
        }
    }

    func latestAlerts() -> [String] {
        let regionModel = Region.from(name: userRegion) ?? .norte
        let filtered = alertsVM.alertas.filter { $0.region?.regionId == regionModel.id }
        return filtered.prefix(3).map { a in
            var s = (a.titulo ?? "-")
            if let nivel = a.nivel { s += " (\(nivel))" }
            return s
        }
    }

    func latestReports() -> [String] {
        return reportsVM.reports.sorted(by: { a,b in
            (a.fechaDate ?? Date.distantPast) > (b.fechaDate ?? Date.distantPast)
        }).prefix(3).map { r in
            let t = r.tipo
            let short = String(r.descripcion.prefix(40))
            return "\(t): \(short)"
        }
    }

    func latestEmergencias() -> [String] {
        return emergVM.emergencias.sorted(by: { a,b in
            (a.createdAt ?? Date.distantPast) > (b.createdAt ?? Date.distantPast)
        }).prefix(3).map { e in
            let m = e.mensaje ?? "(sin mensaje)"
            return String(m.prefix(60))
        }
    }

    func metricBlock(count: Int, label: String, systemIcon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(CardBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func SectionTitle(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Visual helper views
struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

struct SectionHeaderOverlay: View {
    let icon: String
    let title: String
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
