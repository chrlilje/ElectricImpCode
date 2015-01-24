// Copyright (c) 2013,2014 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT
//
// Description: DMX512 Controller via impee-Kaylee

// Modified a bit by Christian Liljedahl 2015, to receive dmx data and color data from the agent

function dmxFromAgent(dmxValues){
    local channel = 1;
    foreach (dmxValue in dmxValues)
    {
        local dmxValueInt = dmxValue.tointeger();

        dmx.setChannel(channel, dmxValueInt);
        channel++;
    }
       
}

function OneColor(data){
    // Set many RGB fixtures to the same color
    local red = data.red.tointeger();
    local green = data.green.tointeger();
    local blue = data.blue.tointeger();
    local alpha = 255;
    local fixtures = 10;
    local channel = 1;
    while (channel <= fixtures*4){
        dmx.setChannel(channel, red);
        channel++;
        dmx.setChannel(channel, green);
        channel++;
        dmx.setChannel(channel, blue);
        channel++;
        dmx.setChannel(channel, alpha);
        channel++;
        //server.log(red);
    }
}

const DMXBAUD     = 250000;
const FRAMESIZE   = 513;  // max 512 devices per frame ("universe"), 1 bytes per device, plus 1-byte start code
const FRAMEPERIOD = 0.2; // send frame once per 200 ms

class Dmx512Controller {
    
    uart        = null;
    tx_en       = null;
    tx_pin      = null;
    
    frame = blob(FRAMESIZE);
    
    constructor(_uart, _tx_pin, _tx_en_pin) {
        uart = _uart;
        tx_pin = _tx_pin;
        tx_en = _tx_en_pin;
        clearFrame();
        sendFrame();
    }
    
    function clearFrame() {
        frame.seek(0);
        while(!frame.eos()) {
            frame.writen(0x00,'b');
        }
    }
    
    function sendFrame() {
        // schedule this function to run again in FRAMEPERIOD
        imp.wakeup(FRAMEPERIOD, sendFrame.bindenv(this));
        
        // send the break
        tx_pin.configure(DIGITAL_OUT,0);

        // uart.configure takes more than long enough to be the mark after break. 
        // It would be great if this were faster.
        uart.configure(DMXBAUD, 8, PARITY_NONE, 2, NO_CTSRTS);
        
        // send the frame
        uart.write(frame);
    }
    
    function setChannel(channel, value) {
        // DMX channels are 1-based, with frame slot 0 reserved for the start code
        // currently, only start code 0x00 is used (default value)
        if (channel < 1) { channel = 1; } 
        if (channel > 512) { channel = 512; }
        //frame[channel] = (value & 0xff);
        frame[channel] = value;
        // value will be sent to device next time frame is sent
    }
    
}

// RUNTIME STARTS --------------------------------------------------------------

//imp.enableblinkup(true);
server.log(imp.getmacaddress());
server.log(hardware.getdeviceid());
server.log(imp.getsoftwareversion());

// pin 5 is a GPIO used to select between receive and transmit modes on the RS-485 translator
// externally pulled down (100k)
// set high to transmit

// Using a Transmit Enable is not needed since we are not receiving
tx_en <- hardware.pin5; 
tx_en.configure(DIGITAL_OUT);
tx_en.write(1);


uart <- hardware.uart12;
uart.configure(DMXBAUD, 8, PARITY_NONE, 2, NO_CTSRTS)
tx_pin <- hardware.pin1;

dmx <- Dmx512Controller(uart, tx_pin, tx_en);

// Did we get an array of dmx values?
agent.on("dmxValues", dmxFromAgent);

// Did we get one color to set on all fixtures?
agent.on("OneColor", OneColor);