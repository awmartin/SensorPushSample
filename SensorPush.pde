import java.util.*;
import java.text.*;
import java.io.*;

int MAX_READINGS = 30;

class SensorPush {
  String email;
  String password;
  
  String authorization;
  String accessToken;
  
  // You can provide a credentials JSON file that has two fields, email and password.
  // {
  //   "email": "myemail@example.com",
  //   "password": "pa$$w0rd"
  // }
  public SensorPush(String credentialsFile) {
    JSONObject creds = loadJSONObject(credentialsFile);
    this.email = creds.getString("email");
    this.password = creds.getString("password");
  }

  public SensorPush(String email, String password) {
    this.email = email;
    this.password = password;
  }
  
  JSONObject listGateways() {
    this.auth();

    PostRequest post = new PostRequest("https://api.sensorpush.com/api/v1/devices/gateways");
    post.addHeader("Accept", "application/json");
    post.addHeader("Authorization", this.accessToken);
    post.send();
    
    JSONObject result = parseJSONObject(post.getContent());
    if (result == null) {
      println("Listing gateways failed.");
      println(post.getContent());
      return new JSONObject();
    } else {
      return result;
    }
  }
  
  JSONObject listSensors() {
    this.auth();
    
    PostRequest post = new PostRequest("https://api.sensorpush.com/api/v1/devices/sensors");
    post.addHeader("Accept", "application/json");
    post.addHeader("Authorization", this.accessToken);
    post.send();
    
    JSONObject result = parseJSONObject(post.getContent());
    if (result == null) {
      println("Listing sensors failed.");
      println(post.getContent());
      return new JSONObject();
    } else {
      String statusCode = result.getString("statusCode");
      if (statusCode != null) {
        println("An error probably occurred...");
        println(result);
        return new JSONObject();
      } else {
        return result;
      }
    }
  }
  
  JSONObject querySamples() {
    this.auth();
    
    PostRequest post = new PostRequest("https://api.sensorpush.com/api/v1/samples");
    post.addHeader("Accept", "application/json");
    post.addHeader("Authorization", this.accessToken);
    post.addBody("{\"limit\": " + MAX_READINGS + "}");

    post.send();
    
    JSONObject result = parseJSONObject(post.getContent());
    if (result == null) {
      println("Querying samples failed.");
      println(post.getContent());
      return new JSONObject();
    } else {
      return result;
    }
  }
  
  String[] getAllSensorIds() {
    JSONObject sensors = this.listSensors();
    Set sensorIds = sensors.keys();
    String[] names = new String[sensorIds.size()];
    
    int i = 0;
    for (Iterator<String> it = sensorIds.iterator(); it.hasNext(); ) {
      String sensorId = it.next();
      JSONObject sensor = sensors.getJSONObject(sensorId);
      String name = sensor.getString("name");
      names[i] = name;
      i += 1;
    }

    return names;
  }
  
  String getSensorIdFromName(String sensorName) {
    JSONObject sensors = this.listSensors();
    Set sensorIds = sensors.keys();
    
    for (Iterator<String> it = sensorIds.iterator(); it.hasNext(); ) {
      String sensorId = it.next();
      JSONObject sensor = sensors.getJSONObject(sensorId);
      String name = sensor.getString("name");
      if (name.equals(sensorName)) {
        return sensorId;
      }
    }
    
    println("Couldn't find a sensor with name:", sensorName);
    return null;
  }
  
  SensorReading[] readingsFromSensor(String sensorId) {
    if (sensorId == null) {
      println("Called readingsFromSensor with a null sensor ID.");
      return null;
    }
    
    JSONObject samples = this.querySamples();
    JSONObject sensors = samples.getJSONObject("sensors");
    
    JSONArray sensorSamples = sensors.getJSONArray(sensorId);
    if (sensorSamples == null) {
      return new SensorReading[0];
    }
    
    int numSensorReadings = sensorSamples.size();
    SensorReading[] readings = new SensorReading[numSensorReadings];
    for (int i = 0; i < sensorSamples.size(); i ++) {
      readings[i] = new SensorReading(sensorSamples.getJSONObject(i));
    }
    
    return readings;
  }
  
  void auth() {
    println("Authorizing the request.");

    if (this.authorization == null || this.accessToken == null) {
      this.loadAuthFile();
    }
    
    // TODO Check to see if the authorization and access tokens are still good.
    
    if (this.authorization == null || this.accessToken == null) {
      println("Either no auth file found or its tokens expired. Reauthorizing...");
      this.authorize();
      this.access();
      this.writeAuthFile();
    }
  }
  
  void authorize() {
    println("Authorizing...");

    PostRequest post = new PostRequest("https://api.sensorpush.com/api/v1/oauth/authorize");
    post.addHeader("Accept", "application/json");
    post.addHeader("Content-Type", "application/json");
    post.addBody("{\"email\":\"" + this.email + "\", \"password\": \"" + this.password + "\"}");
    
    post.send();
    
    JSONObject result = parseJSONObject(post.getContent());
    
    if (result == null) {
      println("Authorization failed. No result.");
      println(post.getContent());
    } else {
      this.authorization = result.getString("authorization");
      if (this.authorization == null) {
        println("Got an error while authorizing:");
        println(result);
      } else {
        println("Authorization code retrieved:", this.authorization);
        println(result);
      }
    }
  }
  
  void access() {
    println("Getting access token...");
    
    PostRequest post = new PostRequest("https://api.sensorpush.com/api/v1/oauth/accesstoken");
    post.addHeader("Accept", "application/json");
    post.addHeader("Content-Type", "application/json");
    post.addBody("{\"authorization\": \"" + this.authorization + "\"}");
    post.send();
    
    JSONObject result = parseJSONObject(post.getContent());
    if (result == null) {
      println("Retrieving access token failed");
      println(post.getContent());
    } else {
      this.accessToken = result.getString("accesstoken");
      if (this.accessToken == null) {
        println("An error occurred while retrieving an access token:");
        println(result);
      } else {
        println("Access token retrieved:", this.accessToken);
        println(result);
      }
    }
  }
  
  void loadAuthFile() {
    File authFile = new File(sketchPath(), "auth.json");
    if (!authFile.exists()) {
      println("auth.json doesn't exist.");
      this.authorization = null;
      this.accessToken = null;
      return;
    }
 
    String[] lines = loadStrings("auth.json");
    String content = join(lines, "\n");
    
    JSONObject json = parseJSONObject(content);
    if (json != null) {
      int timestamp = int(json.getString("timestamp"));
      
      if (this.isMoreThanThirtyMinutesOld(timestamp)) {
        this.removeAuthFile();
        this.authorization = null;
        this.accessToken = null;
      } else {
        println("Found a fresh auth file and tokens.");
        this.authorization = json.getString("authorization");
        this.accessToken = json.getString("accessToken");
      }
      
      // Some error checking for known error cases.
      if (this.authorization.equals("null") || this.accessToken.equals("null")) {
        this.authorization = null;
        this.accessToken = null;
      }
    }
  }
  
  boolean isMoreThanThirtyMinutesOld(int timestamp) {
    Date date = new Date();
    long now = date.getTime() / 1000;
    return (now - timestamp) > 30 * 60;
  }
  
  void removeAuthFile() {
    File file = new File(sketchPath(), "auth.json");
    if (file.delete()) {
      println("Old auth file deleted.");
    } else {
      println("Auth file couldn't be deleted.");
    }
  }
  
  void writeAuthFile() {
    println("Writing a new auth file.");
    String[] contents = { "{",
      "  \"authorization\": \"" + this.authorization + "\",",
      "  \"accessToken\": \"" + this.accessToken + "\",",
      "  \"timestamp\": \"" + this.getTimestamp() + "\"",
      "}" };
    saveStrings("auth.json", contents);
  }
  
  String getTimestamp() {
    Date date = new Date();
    long secs = date.getTime() / 1000;
    return String.valueOf(secs);
  }
}
