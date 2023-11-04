#include <Servo.h>
#include <SoftwareSerial.h>
#include <math.h>
#define RX 9
#define TX 10
#define motor_f 6
#define motor_b 5
#define SERVO 11
#define DefaultAngle 90

Servo servo;
SoftwareSerial bluetooth(TX, RX);
char buf[80];

int speedForward = 0;
int speedBackward = 0;
int angle = DefaultAngle;

#define ALLOWMOTOR 0

int readline(int readch, char *buffer, int len)
{
    static int pos = 0;
    int rpos;

    if (readch > 0)
    {
        switch (readch)
        {
        case '\r': // Ignore CR
            break;
        case '\n': // Return on new-line
            rpos = pos;
            pos = 0; // Reset position index ready for next time
            return rpos;
        default:
            if (pos < len - 1)
            {
                buffer[pos++] = readch;
                buffer[pos] = 0;
            }
        }
    }
    return 0;
}
void setup()
{
    if (ALLOWMOTOR)
    {
        pinMode(motor_f, OUTPUT);
        pinMode(motor_b, OUTPUT);
        servo.attach(SERVO);
    }
    bluetooth.begin(9600);
    Serial.begin(115200);
    delay(1000);
}
void loop()
{
    if (readline(bluetooth.read(), buf, 80) > 0)
    {
        String str = String(buf);
        int splitIndex = str.indexOf("|");
        String speed = str.substring(0, splitIndex);
        String angle = str.substring(splitIndex + 1);
        double speedValue = speed.toDouble();
        double angleValue = angle.toDouble();
        speedValue = speedValue * 255;
        angleValue = angleValue * 50;
        if (speedValue > 0)
        {
            speedForward = speedValue;
            speedBackward = 0;
        }
        else
        {
            speedForward = 0;
            speedBackward = -speedValue;
        }
        angle = DefaultAngle + angleValue;

        Serial.print("speed front: ");
        Serial.print(speedForward);
        Serial.print(" speed back: ");
        Serial.print(speedBackward);
        Serial.print(" angle: ");
        Serial.println(angle);
    }
    if (ALLOWMOTOR)
    {
        servo.write(angle);
        analogWrite(motor_f, speedForward);
        analogWrite(motor_b, speedBackward);
    }
}
