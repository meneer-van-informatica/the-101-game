import requests

# Basis URL van je lampen API
BASE_URL = "http://192.168.2.23/api/wazqsRfcoHTSZwmbVgb2ZXDXtKPgFuSc2zDeUNfQ/lights/"

# Functie om de kleur van een lamp in te stellen
def set_light_color(light_id, color):
    color_map = {
        "green": "#00FF00",
        "red": "#FF0000",
        "blue": "#0000FF"
    }

    if color not in color_map:
        print(f"Fout: Kleur {color} is niet ondersteund.")
        return

    color_code = color_map[color.lower()]

    body = {
        "on": True,
        "rgb": color_code
    }

    # API-aanroep om de kleur in te stellen
    url = f"{BASE_URL}{light_id}/state"
    response = requests.put(url, json=body)

    if response.status_code == 200:
        print(f"Licht {light_id} op kleur {color} gezet.")
    else:
        print(f"Fout bij het instellen van licht {light_id}: {response.status_code} - {response.text}")

# Functie om de lamp aan of uit te zetten
def toggle_light(light_id, state):
    body = {"on": state}
    url = f"{BASE_URL}{light_id}/state"
    response = requests.put(url, json=body)

    if response.status_code == 200:
        print(f"Licht {light_id} {'AAN' if state else 'UIT'}")
    else:
        print(f"Fout bij het {('aanzetten' if state else 'uitzetten')} van licht {light_id}: {response.status_code} - {response.text}")

# Voorbeeld van lichten aansteken en kleuren veranderen
toggle_light(4, True)  # Zet licht 4 aan
set_light_color(4, "green")  # Zet licht 4 op groen

toggle_light(5, False)  # Zet licht 5 uit
set_light_color(5, "blue")  # Zet licht 5 op blauw
