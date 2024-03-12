//
//  ViewController.swift
//  Weather
//
//  Created by Bhuwan Malla on 2024-03-11.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var weatherImage: UIImageView!
    
    @IBOutlet weak var weatherCondition: UILabel!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    
    var isCelsius = true
    
    var locationData = ""
    var temp_C : Float = 0.0
    var temp_f : Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        weatherImage.image = UIImage(systemName: "cloud.hail.fill")
        locationManager.delegate = self
        locationTextField.delegate = self
         
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: locationTextField.text)
        return true
    }
    
    
    private func displayCustomWeatherImage(code: Int){
       
        let customImageColor = UIImage.SymbolConfiguration(paletteColors: [.systemGray, .systemYellow])
        
        weatherImage.preferredSymbolConfiguration = customImageColor
        weatherImage.image = UIImage(systemName: "cloud.sun.fill")
        
        switch code {
        case 1000:
            print("Sunnny")
            weatherImage.image = UIImage(systemName: "cloud.sun.fill")
        case 1003:
            print("Partly Cloudy")
            weatherImage.image = UIImage(systemName: "cloud.fill")
        case 1006:
            print("Cloudy")
            weatherImage.image = UIImage(systemName: "cloud")
        case 1030:
            print("Mist") 
            weatherImage.image = UIImage(systemName: "sun.haze.circle.fill")
        case 1063...1087:
            print("Patchy rain/snow/sleet/freezing drizzle")
            weatherImage.image = UIImage(systemName: "cloud.snow.fill")
        case 1180:
            print("Patchy light rain")
            weatherImage.image = UIImage(systemName: "sun.rain")
        case 1261...1264:
            print("Light to torrential rain showers")
            weatherImage.image = UIImage(systemName: "cloud.moon.rain")
        default:
            print("Sunny")
            weatherImage.image = UIImage(systemName: "cloud.hail.fill")
        }
        
    }
    
    @IBAction func toggleButton(_ sender: UISwitch) {
        isCelsius.toggle()
        
        if let locationTextField = locationTextField.text{
            print(locationTextField)
        }
        
        DispatchQueue.main.async {
            if self.isCelsius{
                self.locationLabel.text = self.locationData
                self.temperatureLabel.text = "\(self.temp_C) C"
            }else{
                self.locationLabel.text = self.locationData
                self.temperatureLabel.text = "\(self.temp_f) F"
            }
        }
}
    
    @IBAction func currentLocationButton(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @IBAction func searchButton(_ sender: UIButton) {
        loadWeather(search: locationTextField.text)
    }
    
    private func loadWeather(search: String?){
        guard let search = search else {
            return
        }
        
        // Step 1 Get URL
        guard let url = getURL(query: search) else{
            print("Could not get the url")
            return
        }
        
        // Step 2: Create URL Session
        let session = URLSession.shared
        
        // Step 3: Create task for session
        let dataTask = session.dataTask(with: url) { data, response, error in
            // Network call finished
            // print("Network call finished")
             
            guard error == nil else {
                print("Error found")
                return
            }
            
            guard let data = data else {
                print("data not found")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data){
//                print(weatherResponse.location.name)
//                print(weatherResponse.current.temp_c)
                
                DispatchQueue.main.async {
                    
                    let temperature = self.isCelsius ? "\(weatherResponse.current.temp_c) C" : "\(weatherResponse.current.temp_f) F"
                    self.locationLabel.text = weatherResponse.location.name
                    self.temperatureLabel.text = temperature
                    self.weatherCondition.text = weatherResponse.current.condition.text
                    self.displayCustomWeatherImage(code: weatherResponse.current.condition.code)
                    
                    self.locationData = weatherResponse.location.name
                    self.temp_C = weatherResponse.current.temp_c
                    self.temp_f = weatherResponse.current.temp_f
                }
            }
        }
        // Step 4: Start the task
        dataTask.resume()
        
    }
    
    private func getURL(query: String) -> URL? {
        let url = "https://api.weatherapi.com/v1/current.json?key=41611fa4425e403fb56224419241203&q=\(query)&aqi=no"
        
        // used to combining two character set
        //        guard let url = "https://api.weatherapi.com/v1/current.json?key=41611fa4425e403fb56224419241203&q=\(query)&aqi=no".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        //
        //            return nil
        //        }
        
        return URL(string: url)
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        //Decode the data
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do{
            weather =  try decoder.decode(WeatherResponse.self, from: data)
        }catch{
            print("Error Decoding")
        }
        
        return weather
    }
    
    
    struct WeatherResponse: Decodable {
        let location: Location
        let current: Weather
    }
    
    struct Location: Decodable {
        let name: String
        let country: String
    }
    
    struct Weather: Decodable{
        let temp_c: Float
        let temp_f: Float
        let condition: WeatherCondition
    }
    
    struct WeatherCondition: Decodable {
        let text: String
        let code: Int
    }
}

extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            print(latitude)
            print(longitude)
            let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemark = placemarks?.first {
                        if let city = placemark.locality {
                            print("City: \(city)")
                            self.loadWeather(search: city)
                        } else {
                            print("City not found")
                        }
                    } else {
                        print("Placemark not found")
                    }
                }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while fetching data")
    }

    
}
