// arduino/BitWorldBlink/BitWorldBlink.ino
// 115200 baud, newline '\n'
// H   -> "OK"
// L1  -> LED ON (pin 13)
// L0  -> LED OFF
// S1/S0 -> continuous blink aan/uit
// P   -> 200ms pulse
const int LED = LED_BUILTIN;
bool running = false;
unsigned long periodMs = 500;
unsigned long lastToggle = 0;
bool ledState = false;

void setup() {
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);
  Serial.begin(115200);
  while (!Serial) { ; }
}

void loop() {
  if (Serial.available()) {
    String line = Serial.readStringUntil('\n');
    line.trim();
    if (line == "H") { Serial.println("OK"); }
    else if (line == "L1") { running=false; ledState=true; digitalWrite(LED,HIGH); }
    else if (line == "L0") { running=false; ledState=false; digitalWrite(LED,LOW); }
    else if (line == "S1") { running=true; lastToggle=millis(); }
    else if (line == "S0") { running=false; ledState=false; digitalWrite(LED,LOW); }
    else if (line == "P")  { digitalWrite(LED,HIGH); delay(200); digitalWrite(LED,LOW); }
    else if (line.startsWith("T")) {
      long v=line.substring(1).toInt();
      if (v>=50 && v<=5000) periodMs=(unsigned long)v;
    }
  }
  if (running) {
    unsigned long now=millis();
    if (now-lastToggle >= periodMs/2) {
      lastToggle=now; ledState=!ledState; digitalWrite(LED, ledState?HIGH:LOW);
    }
  }
}
