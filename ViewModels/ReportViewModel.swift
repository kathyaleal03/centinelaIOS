//
//  ReportViewModel.swift
//  centinela SV
//
//  Created by Laura Leal on 25/10/25.
//

import Foundation
import UIKit

@MainActor
class ReportViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var lastPosted: Report?
    @Published var error: String?
    @Published var sending = false
    @Published var loadingReports = false // Track loading state for ranking view and other consumers
    // Optional date range filters (set by UI). When nil, that bound is ignored.
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil
    
    func postReport(report: Report, token: String?) {
        Task {
            await send(report: report, token: token)
        }
    }

    // New: post flexible payload matching backend
    func postReportPayload(_ payload: [String:Any], token: String?) {
        // Debug: print the exact JSON payload we'll send so you can verify fotoURL is present
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let s = String(data: data, encoding: .utf8) {
            print("[ReportViewModel] -> Payload JSON:\n\(s)")
        } else {
            print("[ReportViewModel] -> Payload could not be serialized for logging")
        }

        Task {
            await sendPayload(payload: payload, token: token)
        }
    }
    
    private func send(report: Report, token: String?) async {
        sending = true
        do {
            let res = try await APIService.shared.postReport(report: report, token: token)
            self.lastPosted = res
            self.error = nil
        } catch {
            self.error = "Error enviando reporte: \(error.localizedDescription)"
            self.lastPosted = nil
        }
        sending = false
    }

    // Fetch all reports (for map annotations)
    func fetchReports(token: String?) {
        Task {
            await loadReports(token: token)
        }
    }

    // Async refresh function to allow awaiting in views (e.g. Ranking)
    func refreshReports(token: String?) async {
        loadingReports = true
        defer { loadingReports = false }
        do {
            let list = try await APIService.shared.fetchReports(token: token)
            self.reports = list
            self.error = nil
            print("[ReportViewModel] -> Loaded \(list.count) reports (refreshReports)")
        } catch {
            self.error = "Error cargando reportes: \(error.localizedDescription)"
            self.reports = []
            print("[ReportViewModel] -> Failed to load reports: \(error)")
        }
    }

    private func loadReports(token: String?) async {
        loadingReports = true
        defer { loadingReports = false }
        do {
            let list = try await APIService.shared.fetchReports(token: token)
            self.reports = list
            self.error = nil
            print("[ReportViewModel] -> Loaded \(list.count) reports (loadReports)")
        } catch {
            self.error = "Error cargando reportes: \(error.localizedDescription)"
            self.reports = []
            print("[ReportViewModel] -> Failed to load reports: \(error)")
        }
    }

    /// Return reports filtered by optional date range and (optionally) by type.
    /// Results are sorted with most recent first when a fecha is available.
    func filteredReports(type: String = "Todos") -> [Report] {
        // Start with reports sorted by fecha (desc). If fecha missing, fall back to reporteId ordering (descending), else keep original order.
        let sorted = reports.sorted { a, b in
            if let da = a.fechaDate, let db = b.fechaDate {
                return da > db
            }
            if let ra = a.reporteId, let rb = b.reporteId {
                return ra > rb
            }
            return true
        }

        var filtered = sorted

        if let start = startDate {
            filtered = filtered.filter { ($0.fechaDate ?? Date.distantPast) >= Calendar.current.startOfDay(for: start) }
        }
        if let end = endDate {
            // include entire end day
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
            filtered = filtered.filter { ($0.fechaDate ?? Date.distantPast) <= endOfDay }
        }

        if type != "Todos" {
            filtered = filtered.filter { $0.tipo == type }
        }

        return filtered
    }

    private func sendPayload(payload: [String:Any], token: String?) async {
        sending = true
        do {
            let res = try await APIService.shared.postReportPayload(payload, token: token)
            self.lastPosted = res
            self.error = nil
        } catch {
            // Attempt a compatibility fallback: if payload has nested "usuario", try sending top-level "usuarioId"
            let errMsg = error.localizedDescription
            if let usuarioObj = payload["usuario"] as? [String:Any], let uid = usuarioObj["usuarioId"] {
                var alt = payload
                alt["usuarioId"] = uid
                alt.removeValue(forKey: "usuario")
                do {
                    let res2 = try await APIService.shared.postReportPayload(alt, token: token)
                    self.lastPosted = res2
                    self.error = nil
                    sending = false
                    return
                } catch {
                    self.error = "Error enviando reporte (fallback): \(error.localizedDescription)"
                    self.lastPosted = nil
                }
            } else {
                self.error = "Error enviando reporte: \(errMsg)"
                self.lastPosted = nil
            }
        }
        sending = false
    }
}
