from flask import Flask, request, jsonify, json
import requests

app = Flask(__name__)

LOCATION_SERVICE_URL = "http://location-service-service.app.svc.cluster.local:5001/api/location"
WEATHER_SERVICE_URL = "http://weather-service-service.app.svc.cluster.local:5002/api/weatherData"

# LOCATION_SERVICE_URL = "http://localhost:5001/api/location"
# WEATHER_SERVICE_URL = "http://localhost:5002/api/weatherData"

# curl "http://localhost:5003/api/agg_data?address=New+York"

@app.route('/api/agg_data', methods=['GET'])
def agg_data():
    address = request.args.get('address')
    if not address:
        return jsonify({"error": "Address parameter is required"}), 400

    print(address)
    # Fetch coordinates from Location Service
    location_response = requests.get(f"{LOCATION_SERVICE_URL}?address={address}")
    location_data = location_response.json()


    print(location_data)
    if 'error' in location_data:
        return jsonify(location_data), location_response.status_code

    lat, lon = location_data["latitude"], location_data["longitude"]

    print(lat, lon)
    # Fetch weather data from Weather Service
    weather_response = requests.get(f"{WEATHER_SERVICE_URL}?lat={lat}&lon={lon}")
    weather_data = weather_response.json()
    # print(weather_data)
    # dict = json.loads(weather_data)
    weather_data['address'] = address
    weather_data['latitude'] = lat
    weather_data['longitude'] = lon

    # weather_data = json.dumps(dict)
    print(weather_data)

    if 'error' in weather_data:
        return jsonify(weather_data), weather_response.status_code

    response = jsonify(weather_data)
    response.headers.add('Access-Control-Allow-Origin', '*')
    print(response)
    return response

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5003)
