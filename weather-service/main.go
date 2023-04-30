package main

import (
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"

    "github.com/gorilla/mux"
)

const (
    weatherURL = "https://api.open-meteo.com/v1/forecast?latitude=%v&longitude=%v&current_weather=true"
)

type WeatherResponse struct {
    Temperature   float64 `json:"temperature"`
    Windspeed     float64 `json:"windspeed"`
    Winddirection float64 `json:"winddirection"`
}

// curl http://localhost:5002/api/weatherData?lat=37.7749&lon=-122.4194


func main() {
    r := mux.NewRouter()
    r.HandleFunc("/api/weatherData", getWeatherData).Methods("GET")
    http.ListenAndServe(":5002", r)
}

func getWeatherData(w http.ResponseWriter, r *http.Request) {
    lat := r.URL.Query().Get("lat")
    lon := r.URL.Query().Get("lon")

	fmt.Println(lat, lon)

    url := fmt.Sprintf(weatherURL, lat, lon)
    resp, err := http.Get(url)
    if err != nil {
        http.Error(w, "Unable to fetch weather data", http.StatusInternalServerError)
        return
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        http.Error(w, "Unable to read weather data", http.StatusInternalServerError)
        return
    }

    var weatherData map[string]interface{}
    if err := json.Unmarshal(body, &weatherData); err != nil {
        http.Error(w, "Unable to parse weather data", http.StatusInternalServerError)
        return
    }

	fmt.Println(weatherData)

    // Extract required weather information from the API response
    currentWeather := weatherData["current_weather"].(map[string]interface{})
    temperature := currentWeather["temperature"].(float64)
    windspeed := currentWeather["windspeed"].(float64)
    winddirection := currentWeather["winddirection"].(float64)

    response := WeatherResponse{
        Temperature:   temperature,
        Windspeed:     windspeed,
        Winddirection: winddirection,
    }

	fmt.Println(response)

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
