SensorPush sp;

SensorReading[] readings = new SensorReading[30];

String USERNAME = "";
String PASSWORD = "";

void setup() {
  size(800, 500);
  
  sp = new SensorPush(USERNAME, PASSWORD);
  readings = sp.readingsFromSensor(sp.getSensorIdFromName("Main Temperature"));
}

void draw() {
  background(255);
  
  noFill();
  stroke(0);
  beginShape();
  for (int i = 0; i < readings.length; i++) {
    float temp = readings[i].temperature;
    float x = map(i, 29, 0, 0, width);
    float y = map(temp, 70, 80, height, 0);
    vertex(x, y);
  }
  endShape();
}
