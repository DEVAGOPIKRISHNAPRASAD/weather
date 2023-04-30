from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

GOOGLE_API_KEY = 'AIzaSyBSpg7YsdAmHndPOAoq_Pe_vy0JdwmkLzo'

# curl -X GET "http://localhost:5001/api/location?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA"

def get_geocode(address):
    geocode_url = f'https://maps.googleapis.com/maps/api/geocode/json?address={address}&key={GOOGLE_API_KEY}'
    response = requests.get(geocode_url)
    data = response.json()
    print(data)
    if data['status'] == 'OK':
        location = data['results'][0]['geometry']['location']
        return location['lat'], location['lng']
    else:
        return None

@app.route('/api/location', methods=['GET'])
def location():
    address = request.args.get('address')
    if not address:
        return jsonify({"error": "Address parameter is required"}), 400

    print(address)
    coordinates = get_geocode(address)
    print(coordinates)
    if coordinates:
        return jsonify({
            "latitude": coordinates[0], 
            "longitude": coordinates[1]
        })
    else:
        return jsonify({"error": "Unable to get coordinates for the given address"}), 404

if __name__ == '__main__':
    app.run(debug=True, port=5001)
