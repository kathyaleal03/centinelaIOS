import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Bienvenido")
                            .font(.system(size: 36, weight: .bold))
                        HStack {
                            Text("a")
                                .font(.system(size: 22))
                            Text("Centinela")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color("AccentColor"))
                        }
                    }
                    Spacer()

                    // Illustration placeholder — replace with asset named "home_illustration" if available
                    Image(systemName: "map.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .foregroundColor(Color.blue.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Weather summary card
                // Weather card navigates to detailed weather screen
                NavigationLink(destination: WeatherDetailView()) {
                    HStack {
                        WeatherStatusView()
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }

                VStack(spacing: 18) {
                    // First action card
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                // Placeholder action: navigate to Report screen in the app
                                NotificationCenter.default.post(name: Notification.Name("OpenReport"), object: nil)
                            }) {
                                Text("Ingresar")
                                    .font(.headline)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }

                            Text("Realiza registros de los desastres naturales que encuentres en tu municipio")
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .lineLimit(3)
                        }
                        .padding()

                        Spacer()

                        // Right-side small illustration placeholder
                        Image(systemName: "person.3.sequence.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.trailing, 8)
                    }
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(18)
                    .shadow(radius: 4)

                    // Second action card
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Localiza tus refugios")
                                .foregroundColor(.white)
                                .font(.headline)

                            Button(action: {
                                NotificationCenter.default.post(name: Notification.Name("OpenRefuges"), object: nil)
                            }) {
                                Text("Ver refugios")
                                    .font(.headline)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 18)
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding()

                        Spacer()

                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.trailing, 8)
                    }
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(18)
                    .shadow(radius: 4)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
