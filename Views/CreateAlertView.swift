import SwiftUI

struct CreateAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var titulo: String = ""
    @State private var descripcion: String = ""
    @State private var nivel: String = "alto"

    var onCreate: (String, String, String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Título")) {
                    TextField("Título", text: $titulo)
                }
                Section(header: Text("Descripción")) {
                    TextEditor(text: $descripcion).frame(height: 140)
                }
                Section(header: Text("Nivel")) {
                    Picker("Nivel", selection: $nivel) {
                        Text("Alto").tag("alto")
                        Text("Medio").tag("medio")
                        Text("Bajo").tag("bajo")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Crear alerta")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        onCreate(titulo, descripcion, nivel)
                    }.disabled(titulo.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct CreateAlertView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAlertView { _,_,_ in }
    }
}
