#include <SoftwareSerial.h>
SoftwareSerial Bluetooth(10, 9);
char c = ' ';
void setup()
{
    Serial.begin(9600);
    Serial.println("ready");
    Bluetooth.begin(38400);
}
void loop()
{
    if (Bluetooth.available())
    {
        c = Bluetooth.read();
        Serial.write(c);
    }
    if (Serial.available())
    {
        c = Serial.read();
        Bluetooth.write(c);
    }
}