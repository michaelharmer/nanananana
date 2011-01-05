#include <MsTimer2.h>

#define NUM_READINGS 100
#define QUIET_PERIODS 10
#define LOUD_BIT_LENGTH 500
#define LOUD_BIT_FACTOR 1.6

int analogPin = 1;     
                      
int val = 0;          
int average = 0;
int num_read = 0;
int max_val = 0;
int total = 0;
int *loud_bit;
int loud_bit_counter = 0; 
int loud_bit_started = false;
int quiet_counter = 0;
int always_false = false;

void play_buzzer()
{
  Serial.println("PLAYING");
  for (int i = 0; i < loud_bit_counter; i++)
    Serial.println(loud_bit[i]);
}

void output_max()
{
  if (num_read < NUM_READINGS) 
  {
    total += max_val;
    average = total / ++num_read;
    Serial.print("** ");
    Serial.print(average);
    Serial.print(" ");
    Serial.println(max_val);
  }
  else 
  {
    Serial.print(average);
    Serial.print(" ");
    Serial.print(max_val);
    if (max_val > average * LOUD_BIT_FACTOR) 
    {
      Serial.print(" ****");
      loud_bit_started = true;
      quiet_counter = 0;
    }
    else
    {
      quiet_counter++;
      if (loud_bit_started == true && quiet_counter > QUIET_PERIODS)
      {
        loud_bit_started = false;
        if (loud_bit_counter > 20)
        {
          MsTimer2::stop();
          play_buzzer();
          MsTimer2::start();
        }
        loud_bit_counter = 0;
      }    
    }
    Serial.println();

    if (loud_bit_started == true && loud_bit_counter < LOUD_BIT_LENGTH)
    {
      loud_bit[loud_bit_counter++] = max_val;
    }
  }
  max_val = 0;

}

void setup()
{
  loud_bit = (int *) malloc(sizeof(int) * LOUD_BIT_LENGTH);
  Serial.begin(57600);          //  setup serial
  Serial.println("starting");
  MsTimer2::set(100, output_max); // 500ms period
  MsTimer2::start();
}

void loop()
{
  val = abs(analogRead(analogPin) - 512);    // read the input pin
  if (val > max_val)
    max_val = val;  
}


