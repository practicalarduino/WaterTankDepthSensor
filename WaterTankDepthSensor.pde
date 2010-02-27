/**
 * WaterTankDepthSensor
 *
 * Uses an analog input to read the level of water in a tank using a
 * differential pressure transducer, with the result displayed in a web
 * page served using a WiShield that provides WiFi connectivity to the
 * Arduino.
 *
 * Copyright 2009 Jonathan Oxer <jon@oxer.com.au>
 * Copyright 2009 Hugh Blemings <hugh@blemings.org>
 * http://www.practicalarduino.com/projects/water-tank-depth-sensor
 */


#include <WiServer.h>

#define WIRELESS_MODE_INFRA	1
#define WIRELESS_MODE_ADHOC	2

// Wireless configuration parameters ----------------------------------------
unsigned char local_ip[] = {10,0,1,200};         // IP address of WiShield
unsigned char gateway_ip[] = {10,0,1,1};         // router or gateway IP address
unsigned char subnet_mask[] = {255,255,255,0};   // subnet mask for the local network
const prog_char ssid[] PROGMEM = {"YourSSID"};   // max 32 bytes

unsigned char security_type = 3;                 // 0 - open; 1 - WEP; 2 - WPA; 3 - WPA2

// WPA/WPA2 passphrase
const prog_char security_passphrase[] PROGMEM = {"YourWifiPassphrase"};    // max 64 characters

// WEP 128-bit keys
// sample HEX keys
prog_uchar wep_keys[] PROGMEM = {
  0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,  // Key 0
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 1
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Key 2
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   // Key 3
};

// Set up the wireless mode
// "infrastructure" means connect to an access point. This is typical.
// "adhoc" means connect to another WiFi device. Unusual.
unsigned char wireless_mode = WIRELESS_MODE_INFRA;

unsigned char ssid_len;
unsigned char security_passphrase_len;
// End of wireless configuration parameters ----------------------------------------

int sensorValue      = 0;
int constrainedValue = 0;
int tankLevel        = 0;
#define TANK_SENSOR 0

#define TANK_EMPTY 0
#define TANK_FULL  1023

/**
 * Setup
 */
void setup() {
  // Initialize WiServer and specify the function to use for serving pages. Three
  // example functions are provided: uncomment only one of these at a time.
  WiServer.init( sendWebPage );
  //WiServer.init( sendWebPagePretty );
  //WiServer.init( sendWebPageFlash );
  
  // Enable Serial output and ask WiServer to generate log messages (optional)
  Serial.begin( 38400 );
  WiServer.enableVerboseMode( true );
}

/**
 * Main program loop. We don't need to do anything in the loop except repeatedly
 * invoke the WiServer object, because everything else is handled by callbacks
 * in the object itself. Nothing much happens unless the object detects an incoming
 * connection request, in which case it invokes the web serving function specified
 * above in the "init" call inside setup();
 */
void loop(){
  // Run WiServer
  WiServer.server_task();
  delay( 10 );
}

/**
 * sendWebPage( char* URL )
 *
 * A basic version of the page serving function that just outputs some trivial
 * HTML to show the sensor value and the scaled tank level.
 */
boolean sendWebPage( char* URL ) {
  sensorValue = analogRead( TANK_SENSOR );
  constrainedValue = constrain( sensorValue, TANK_EMPTY, TANK_FULL );
  tankLevel = map( constrainedValue, TANK_EMPTY, TANK_FULL, 0, 100 );
    // Check if the requested URL matches "/"
    if( strcmp( URL, "/" ) == 0 ) {
        // Use WiServer's print and println functions to write out the page content
        WiServer.print( "<html>" );
        WiServer.print( "Hello World!<br>" );
        WiServer.print( sensorValue );
        WiServer.print( " - " );
        WiServer.print( tankLevel );
        WiServer.print( "&#37;</html>" );
        
        // URL was recognized
        return true;
    }
    // URL not found
    return false;
}

/**
 * sendWebPagePretty( char* URL )
 * 
 * This version of the serving function uses a table to provide a visual representation
 * of the water level in the tank.
 */
boolean sendWebPagePretty( char* URL ) {
  sensorValue = analogRead( TANK_SENSOR );
  constrainedValue = constrain( sensorValue, TANK_EMPTY, TANK_FULL );
  tankLevel = map( constrainedValue, TANK_EMPTY, TANK_FULL, 0, 100 );
    // Check if the requested URL matches "/"
    if( strcmp(URL, "/" ) == 0) {
        // Use WiServer's print and println functions to write out the page content
        WiServer.print( "<html><center>" );
        WiServer.print( "<h1>Tank Level</h1>" );
        WiServer.print( "<h2>" );
        WiServer.print( tankLevel );
        WiServer.print( "&#37;" );
        WiServer.print( "</h2>" );
        WiServer.print( "<table width=200 cellspacing=0 cellpadding=0 border=1>" );
        WiServer.print( "<tr><td bgcolor=#cccccc height=" );
        WiServer.print( 2 * (100 - tankLevel) );
        WiServer.print( "></td></tr>" );
        WiServer.print( "<tr><td bgcolor=#3333aa height=" );
        WiServer.print( 2 * tankLevel );
        WiServer.print( "></td></tr>" );
        WiServer.print( "</table><br><br>" );
        WiServer.print( sensorValue );
        WiServer.print( " (" );
        WiServer.print( TANK_EMPTY );
        WiServer.print( "-" );
        WiServer.print( TANK_FULL );
        WiServer.print( ")</center></html>" );
        
        // URL was recognized
        return true;
    }
    // URL not found
    return false;
}

/**
 * sendWebPageFlash( char* URL )
 *
 * This version of the serving function uses an iFrame to reference an external
 * server containing a PHP file and a Flash object. The PHP file reads the parameter
 * value that has been sent to it in the URL, and loads the Flash object to
 * provide a visual display of the result.
 */
boolean sendWebPageFlash( char* URL ) {
  sensorValue = analogRead( TANK_SENSOR );
  constrainedValue = constrain( sensorValue, TANK_EMPTY, TANK_FULL );
  tankLevel = map( constrainedValue, TANK_EMPTY, TANK_FULL, 0, 100 );
    // Check if the requested URL matches "/"
    if( strcmp( URL, "/" ) == 0 ) {
        // Use WiServer's print and println functions to write out the page content
        WiServer.println( "<html><center>" );
        WiServer.print( "<iframe width=\"550\" height=\"400\" scrolling=\"no\" " );
        WiServer.print( "src=\"http://www.example.com/tank.php?level=" );
        WiServer.print( tankLevel );
        WiServer.println( "\"></iframe>" );
        WiServer.println( "</center></html>" );
        
        // URL was recognized
        return true;
    }
    // URL not found
    return false;
}
