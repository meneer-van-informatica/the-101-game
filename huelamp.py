import sys
import requests

# Basis URL van je lampen API
BASE_URL = "http://192.168.2.23/api/wazqsRfcoHTSZwmbVgb2ZXDXtKPgFuSc2zDeUNfQ/lights/"

# Functie om de kleur van een lamp in te stellen
def set_light_color(light_id, color):
    color_map = {
        "green": "#00FF00",
        "red": "#FF0000",
        "blue": "#0000FF",
        "white": "#FFFFFF"
    }

    if color not in color_map:
        print(f"Error: Color {color} is not supported.")
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
        print(f"Light {light_id} set to {color}.")
    else:
        print(f"Error setting light {light_id}: {response.status_code} - {response.text}")


# Functie om een licht aan of uit te zetten
def toggle_light(light_id, state):
    body = {"on": state}
    url = f"{BASE_URL}{light_id}/state"
    response = requests.put(url, json=body)

    if response.status_code == 200:
        print(f"Light {light_id} {'ON' if state else 'OFF'}.")
    else:
        print(f"Error toggling light {light_id}: {response.status_code} - {response.text}")


# Hoofdprogramma om de command-line argumenten te verwerken
def main():
    if len(sys.argv) < 3:
        print("Usage: huelamp <light_id> <command>")
        sys.exit(1)

    light_id = int(sys.argv[1])
    command = sys.argv[2].lower()

    if command == "on":
        toggle_light(light_id, True)
    elif command == "off":
        toggle_light(light_id, False)
    elif command in ["green", "red", "blue", "white"]:
        set_light_color(light_id, command)
    else:
        print(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
