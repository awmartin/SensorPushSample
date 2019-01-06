# SensorPush API with Processing

This is sample code for accessing the beta API for [SensorPush](http://www.sensorpush.com/) devices
with [Processing](https://processing.org).

It provides some niceties that enable you to request data from sensors attached to a SensorPush
Gateway easily. It manages the OAuth flow, caches the auth tokens for subsequent requests, provides
objects that make working with the JSON responses easy, etc.

## Dependencies

This sketch uses a modified version of the HTTP Requests library. Installing it is the best way to
install the dependencies required to make the API requests in this sketch, namely org.apache.http.
So just install the HTTP Requests library from the Processing Contribution Manager to get it.

