// Originally from:
// https://github.com/runemadsen/HTTP-Requests-for-Processing/blob/master/src/http/requests/PostRequest.java

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map.Entry;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.auth.BasicScheme;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;

public class PostRequest
{
  String url;
  ArrayList<BasicNameValuePair> nameValuePairs;
  HashMap<String,File> nameFilePairs;
  ArrayList<BasicNameValuePair> headerPairs;

  String content;
  String encoding;
  HttpResponse response;
  UsernamePasswordCredentials creds;

  public PostRequest(String url) {
    this(url, "ISO-8859-1");
  }
  
  public PostRequest(String url, String encoding) {
    this.url = url;
    this.encoding = encoding;
    this.nameValuePairs = new ArrayList<BasicNameValuePair>();
    this.nameFilePairs = new HashMap<String,File>();
    this.headerPairs = new ArrayList<BasicNameValuePair>();
  }

  public void addUser(String user, String pwd) {
    this.creds = new UsernamePasswordCredentials(user, pwd);
  }
    
  public void addHeader(String key,String value) {
    BasicNameValuePair nvp = new BasicNameValuePair(key,value);
    this.headerPairs.add(nvp);
  } 

  public void addData(String key, String value) 
  {
    BasicNameValuePair nvp = new BasicNameValuePair(key,value);
    this.nameValuePairs.add(nvp);
  }

  public void addFile(String name, File f) {
    this.nameFilePairs.put(name,f);
  }

  public void addFile(String name, String path) {
    File f = new File(path);
    this.nameFilePairs.put(name,f);
  }
  
  String body;
  public void addBody(String body) {
    this.body = body;
  }
  
  public void send() {
    try {

      HttpPost httpPost = new HttpPost(this.url);
      this.populateRequest(httpPost);
      
      DefaultHttpClient httpClient = new DefaultHttpClient();
      this.response = httpClient.execute(httpPost);

      HttpEntity entity = this.response.getEntity();
      this.content = EntityUtils.toString(entity);

      if (entity != null) {
        EntityUtils.consume(entity);
      }

      httpClient.getConnectionManager().shutdown();

      this.clear();
      
    } catch (Exception e) { 
      e.printStackTrace();
    }
  }

  private void populateRequest(HttpPost httpPost) {
    try {
      if (this.creds != null) {
        httpPost.addHeader(new BasicScheme().authenticate(this.creds, httpPost, null));        
      }
  
      if (this.body != null) {
        
        StringEntity entity = new StringEntity(this.body);
        httpPost.setEntity(entity);
        
      } else if (nameFilePairs.isEmpty()) {
        
        UrlEncodedFormEntity entity = new UrlEncodedFormEntity(nameValuePairs, encoding); 
        httpPost.setEntity(entity);
        
      } else {
        
        MultipartEntity mentity = this.createMultipartEntity();
        if (mentity != null) {
          httpPost.setEntity(mentity);
        }
        
      }
  
      Iterator<BasicNameValuePair> headerIterator = headerPairs.iterator();
      while (headerIterator.hasNext()) {
        BasicNameValuePair headerPair = headerIterator.next();
        httpPost.addHeader(headerPair.getName(), headerPair.getValue());
      }
      
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private MultipartEntity createMultipartEntity() {
    try {
      
      MultipartEntity mentity = new MultipartEntity();  
      Iterator<Entry<String,File>> it = this.nameFilePairs.entrySet().iterator();
      
      while (it.hasNext()) {
        Entry<String, File> pair = it.next();
        String name = (String) pair.getKey();
        File f = (File) pair.getValue();
        mentity.addPart(name, new FileBody(f));
      }
      
      for (NameValuePair nvp : nameValuePairs) {
        mentity.addPart(nvp.getName(), new StringBody(nvp.getValue()));
      }
    
      return mentity;
      
    } catch (Exception e) {
      e.printStackTrace();
      return null;
    }
  }
  
  void clear() {
    this.nameValuePairs.clear();
    this.nameFilePairs.clear();
    this.headerPairs.clear();
    this.body = "";
  }

  /* Getters
  _____________________________________________________________ */

  public String getContent() {
    return this.content;
  }

  public String getHeader(String name) {
    Header header = this.response.getFirstHeader(name);
    if (header == null) {
      return "";
    } else {
      return header.getValue();
    }
  }
}
