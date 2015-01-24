
function requestHandler(request, response) {
  try {
      local responseText = "ok";
   
    // Code to handle a dmx value array as a query string
    if ("dmx" in request.query) {
     
      // We expect to get a request like this ?dmx=0,255,0,250
      // This means: Channel 1: 0, ch 2: 255, ch 3: 0, ch 4: 250
      local dmxArray = request.query.dmx;
      local dmxValues = split(dmxArray,",");
      device.send("dmxValues",dmxValues);
      responseText += "We got a dmx-address-string"
    }
    
    // Code to handle the Pitchfork Color Picker.
    // JSON in this form: 
    // { "red" : "(red value)" , "green" : "(green value)" , "blue" : "(blue value)" }
    // Example: Red at 100% brightness
    // { "red" : "255" , "green" : "0" , "blue" : "0" }
    try {
        // Maybe we got a JSON - Lets decode it!
        local data = http.jsondecode(request.body);
        if("red" in data){
            device.send("OneColor",data);
             responseText = "JSON received";
        }
    } catch (ex){
        responseText = " - No JSON or bad JSON received";
    }
    response.send(200,responseText);

  } catch (ex) {
    response.send(500, "Internal Server Error: " + ex);
  }
}
 
// register the HTTP handler
http.onrequest(requestHandler);