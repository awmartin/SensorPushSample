import java.util.Date;
import java.text.SimpleDateFormat;
import java.time.*;

class SensorReading {
  float temperature;
  float humidity;
  Date observed;

  public SensorReading(JSONObject sample) {
    this.temperature = sample.getFloat("temperature");
    this.humidity = sample.getFloat("humidity");
    this.observed = this.parseISODate(sample.getString("observed"));
  }
  
  // https://stackoverflow.com/questions/2201925/converting-iso-8601-compliant-string-to-java-util-date
  Date parseISODate(String observed) {
    //DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
    //return df.parse(observed);
    return Date.from(Instant.parse(observed));
  }
}
