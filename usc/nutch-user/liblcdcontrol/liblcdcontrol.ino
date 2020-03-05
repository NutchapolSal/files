//for hd44780 lcds
//https://en.wikipedia.org/wiki/Hitachi_HD44780_LCD_controller

// include the library code:
#include <LiquidCrystal.h>

//here are the pins, connect them correctly or they aren't gonna work lol
const int rs = 12, rw = 10, en = 11, d0 = 9, d1 = 8, d2 = 7, d3 = 6, d4 = 5, d5 = 4, d6 = 3, d7 = 2;
char incomingByte;
bool clearflag;
bool lineflag;
bool updateflag;
int updatenum = 0;
int lastmillis = 0;
int millitimer = 0;
String text = "";
String text2 = "";
String temptxt = "";
LiquidCrystal lcd(rs, rw, en, d0, d1, d2, d3, d4, d5, d6, d7);

void setup() {
  // set up the LCD's number of columns and rows:
  lcd.begin(16, 2);
  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    if (clearflag){
      lcd.clear();
      lineflag = false;
      clearflag = false;
      text = "";
      text2 = "";
    }

    while (Serial.available() > 0){
      incomingByte = Serial.read();
      switch (incomingByte){
        case 10:
          clearflag = true;
          break;
        case 13:
          clearflag = true;
          break;
        case 9:
          lineflag = true;
          break;
        default:
          if(lineflag){
            text2 = text2 + incomingByte;}
          else{
            text = text + incomingByte;}
          break;
      }

    }
  }

  int deltaMilli = millis() - lastmillis;
  lastmillis = millis();
  millitimer = millitimer + deltaMilli;
  if (millitimer > 500){
    updateflag = true;
    millitimer = millitimer - 500;
    updatenum = updatenum + 1;
  }
  lcd.setCursor(0, 0);
  if (text.length() > 16){
    if (updateflag){
      temptxt = text + "   " + text;
      lcd.print(temptxt.substring(updatenum % (text.length() + 3), (updatenum % (text.length() + 3)) + 16));
    }
  }else{
    lcd.print(text);
  }

  lcd.setCursor(0, 1);
  if (text2.length() > 16){
    if (updateflag){
      temptxt = text2 + "   " + text2;
      lcd.print(temptxt.substring(updatenum % (text2.length() + 3), (updatenum % (text2.length() + 3)) + 16));
    }
  }else{
    lcd.print(text2);
  }
  updateflag = false;
}