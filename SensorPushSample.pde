import java.util.Date;

SensorPush sp;
ArrayList<SensorReading> readings = new ArrayList<SensorReading>();
long startTime;

String USERNAME = "";
String PASSWORD = "";

void setup() {
  size(800, 500);
  
  sp = new SensorPush(USERNAME, PASSWORD);
  SensorReading[] results = sp.readingsFromSensor(sp.getSensorIdFromName("Main Temperature"));
  
  // Stash the results into an ArrayList so we can append new results easily.
  for (int i = 0; i < results.length; i++) {
    readings.add(results[i]);
  }
  
  startTimer();
}

void draw() {
  background(255);
  
  noFill();
  stroke(0);
  beginShape();
  for (int i = 0; i < readings.size(); i++) {
    float temp = readings.get(i).temperature;
    float x = map(i, 0, readings.size() - 1, 0, width);
    float y = map(temp, 70, 110, height, 0);
    vertex(x, y);
  }
  endShape();
  
  updateTimer();
}

void startTimer() {
  Date startDate = new Date();
  startTime = startDate.getTime() / 1000;
}

void updateTimer() {
  Date now = new Date();
  long secs = now.getTime() / 1000;
  boolean oneMinuteElapsed = secs - startTime > 60;

  if (oneMinuteElapsed) {
    String sensorId = sp.getSensorIdFromName("Main Temperature");
    SensorReading[] results = sp.readingsFromSensor(sensorId, 1);
    
    if (results.length > 0) {
      readings.add(results[0]);
      println("New result!", results[0].temperature);
    }
    
    // Reset the timer.
    startTime = secs;
  }
}
