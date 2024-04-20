import SwiftUI

struct ContentView: View {
    @State private var city: String = ""
    @State private var weatherData: WeatherData?
    @State private var weatherIcon: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            VStack {
                Text("Weather App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                TextField("Enter city", text: $city, onCommit: fetchWeather) // <- Call fetchWeather() on commit
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                if let weatherData = weatherData {
                    WeatherView(weatherData: weatherData, weatherIcon: weatherIcon)
                }
                
                Spacer()
            }
        }
    }
    
    private func fetchWeather() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(ApiKey.value)&units=metric") else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                isLoading = false
            }
            
            guard let data = data, error == nil else {
                errorMessage = "Error: \(error?.localizedDescription ?? "Unknown error")"
                return
            }
            
            if let decodedResponse = try? JSONDecoder().decode(WeatherData.self, from: data) {
                DispatchQueue.main.async {
                    self.weatherData = decodedResponse
                    if let iconCode = decodedResponse.weather.first?.icon {
                        fetchWeatherIcon(iconCode: iconCode)
                    }
                }
            } else {
                errorMessage = "Failed to decode response"
            }
        }.resume()
    }
    
    private func fetchWeatherIcon(iconCode: String) {
        guard let iconURL = URL(string: "https://openweathermap.org/img/wn/\(iconCode)@2x.png") else {
            return
        }
        
        URLSession.shared.dataTask(with: iconURL) { data, response, error in
            guard let data = data, error == nil else {
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
    @State private var showDetails = false
    @State private var detailedWeather: DetailedWeather?
    
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
                    .frame(width: 120, height: 120)
            }
            
            Text("\(Int(weatherData.main.temp))°C")
                .font(.title)
                .fontWeight(.semibold)
            
            Text(weatherData.weather.first?.description.capitalized ?? "")
                .font(.headline)
                .foregroundColor(.gray)
            
            if showDetails {
                if let detailedWeather = detailedWeather {
                    WeatherDetailsView(detailedWeather: detailedWeather)
                } else {
                    Text("Loading...")
                        .foregroundColor(.gray)
                }
            }
            
            Button(showDetails ? "Hide more details" : "Show more details") {
                if showDetails {
                    showDetails = false
                } else {
                    fetchDetailedWeather()
                }
            }
            .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .shadow(radius: 5)
        )
        .padding()
    }
    
    private func fetchDetailedWeather() {
        guard let city = weatherData.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=14681310f305a9ea549bb12bc8abb35c&units=metric") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            if let detailedWeather = try? JSONDecoder().decode(DetailedWeather.self, from: data) {
                DispatchQueue.main.async {
                    self.detailedWeather = detailedWeather
                    self.showDetails = true
                }
            }
        }.resume()
    }
}

struct WeatherDetailsView: View {
    let detailedWeather: DetailedWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Humidity: \(detailedWeather.main.humidity)%")
            Text("Wind Speed: \(detailedWeather.wind.speed) m/s")
            Text("Pressure: \(detailedWeather.main.pressure) hPa")
            Text("Visibility: \(detailedWeather.visibility / 1000) km")
            Text("Sunrise: \(formatTime(timestamp: detailedWeather.sys.sunrise))")
            Text("Sunset: \(formatTime(timestamp: detailedWeather.sys.sunset))")
        }
    }
    
    private func formatTime(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}

struct WeatherData: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
    let pressure: Int
}

struct Weather: Codable {
    let description: String
    let icon: String
}

struct DetailedWeather: Codable {
    let main: Main
    let wind: Wind
    let visibility: Int
    let sys: Sys
    
    struct Sys: Codable {
        let sunrise: Int
        let sunset: Int
    }
}

struct Wind: Codable {
    let speed: Double
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
