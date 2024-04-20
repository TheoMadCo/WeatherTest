import SwiftUI

struct ContentView: View {
    @State private var city: String = ""
    @State private var weatherData: WeatherData?
    @State private var weatherIcon: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            TextField("Enter city", text: $city, onCommit: fetchWeather)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let weatherData = weatherData {
                WeatherView(weatherData: weatherData, weatherIcon: weatherIcon)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func fetchWeather() {
        isLoading = true
        errorMessage = nil
        
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=14681310f305a9ea549bb12bc8abb35c&units=metric") else {
            print("Invalid URL")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                isLoading = false
            }
            
            guard let data = data, error == nil else {
                errorMessage = "Error: \(error?.localizedDescription ?? "Unknown error")"
                print(errorMessage ?? "Unknown error")
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(WeatherData.self, from: data) {
                DispatchQueue.main.async {
                    self.weatherData = decodedResponse
                    // Fetch weather icon
                    if let iconCode = decodedResponse.weather.first?.icon {
                        fetchWeatherIcon(iconCode: iconCode)
                    }
                }
            } else {
                errorMessage = "Failed to decode response"
                print(errorMessage ?? "Failed to decode response")
            }
        }.resume()
    }
    
    private func fetchWeatherIcon(iconCode: String) {
        guard let iconURL = URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png") else {
            print("Invalid icon URL")
            return
        }
        
        URLSession.shared.dataTask(with: iconURL) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching weather icon: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.weatherIcon = UIImage(data: data)
            }
        }.resume()
    }
}

struct WeatherView: View {
    let weatherData: WeatherData
    let weatherIcon: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(weatherData.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            if let weatherIcon = weatherIcon {
                Image(uiImage: weatherIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120) // Adjusted size for the weather icon
            }
            
            Text("\(Int(weatherData.main.temp))°C")
                .font(.title)
                .fontWeight(.semibold)
            
            Text(weatherData.weather.first?.description.capitalized ?? "")
                .font(.headline)
                .foregroundColor(.gray)
            
            Spacer() // Ensures elements are vertically centered and card expands vertically
        }
        .padding()
        .frame(maxWidth: .infinity) // Card expands horizontally
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .shadow(radius: 5)
        )
        .padding()
    }
}

struct WeatherData: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
}

struct Weather: Codable {
    let description: String
    let icon: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
