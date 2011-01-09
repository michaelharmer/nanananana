#include <MsTimer2.h>
#include "states.h"

#define NUM_READINGS 100
#define QUIET_PERIODS 20
#define MIN_START_OF_LOUD 3
#define LOUD_BIT_LENGTH 500
#define LOUD_BIT_FACTOR 1.4

int analogPin = 1;   
int sound_pin = 2;
                      
int val = 0;          
int max_val = 0;
int *loud_bit;

enum State g_state = STARTUP;

void set_state(enum State state)
{
  g_state = state;  
}

int get_state()
{
  return g_state; 
}

void play_buzzer(int *volumes, int length, int average)
{
  Serial.println("PLAYING");
  Serial.println(length);
  for (int i = 0; i < length; i++)
  {
    Serial.println(volumes[i]);
    if (volumes[i] > average * LOUD_BIT_FACTOR)
    {
      digitalWrite(sound_pin, HIGH);
      delay(100);
       digitalWrite(sound_pin, LOW);
    }
    else
      delay(100);
  }
}

void process_data()
{
  static int average = 0;
  static int length_of_loud_bit = 0;
  static int length_of_quiet_bit = 0;
  
  Serial.print(get_state());
  Serial.print("  ");
  Serial.print(average);
  Serial.print(" ");
  Serial.println(max_val);
  
  switch (get_state()) {
    case STARTUP:  
      static int total = 0;
      static int num_read = 0;
      
      if (num_read < NUM_READINGS) 
      {
        total += max_val;
        average = total / ++num_read;
      }
      else
      {
        set_state(LISTENING);  
        process_data();
      }
      break;
      
    case LISTENING:
      if (max_val > average * LOUD_BIT_FACTOR)
      {
        set_state(LOUD_BIT_STARTED);
        process_data();  
      }
      break;   
     
    case LOUD_BIT_STARTED:
      length_of_loud_bit = 0;
      set_state(LOUD_BUT_NOT_CONFIRMED);
      process_data();  
      break;  
      
    case LOUD_BUT_NOT_CONFIRMED:
    case LOUD:
      if (length_of_loud_bit > LOUD_BIT_LENGTH)
      {
        set_state(LISTENING);
      }
      else if (max_val > average * LOUD_BIT_FACTOR)
      {
        loud_bit[length_of_loud_bit++] = max_val;
        if (get_state() == LOUD_BUT_NOT_CONFIRMED && length_of_loud_bit > MIN_START_OF_LOUD)
          set_state(LOUD);
      }
      else
      {
        if (get_state() == LOUD_BUT_NOT_CONFIRMED)
        {
          set_state(LISTENING);
        }
        else
        {
          set_state(QUIET_BIT_STARTED);
          process_data();    
        }
      }
      break;
      
    case QUIET_BIT_STARTED:
      length_of_quiet_bit = 0;
      set_state(LOUD_BUT_NOW_QUIET);
      process_data();
      break;  
    
    case LOUD_BUT_NOW_QUIET:
      if (length_of_loud_bit > LOUD_BIT_LENGTH)
      {
        set_state(LISTENING);
      }
      else 
      {
        length_of_quiet_bit++;
        loud_bit[length_of_loud_bit++] = max_val;
        if (length_of_quiet_bit > QUIET_PERIODS) 
        {
          set_state(PLAYBACK);
          process_data();
        }
      }
      break;      
    
    case PLAYBACK:
      //MsTimer2::stop();
      play_buzzer(loud_bit, length_of_loud_bit, average);
      //MsTimer2::start();
      set_state(LISTENING);
      break;
    
  }
  max_val = 0;
  
}


void setup()
{
  pinMode(sound_pin, OUTPUT);
  set_state(STARTUP);
  loud_bit = (int *) malloc(sizeof(int) * LOUD_BIT_LENGTH);
  Serial.begin(57600);          //  setup serial
  Serial.println("starting");
}

unsigned long previousMillis = 0;
void loop()
{
  unsigned long currentMillis = millis();
 
  val = abs(analogRead(analogPin) - 512);    // read the input pin
  if (val > max_val)
    max_val = val; 
    
  if (currentMillis - previousMillis > 100) {
    previousMillis = currentMillis; 
    process_data();
  }
    
}


