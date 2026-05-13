/******************************************************************************/
/*                                                                            */
/* PmodKYPD.c -- Demo for the use of the Pmod Keypad IP core                  */
/*                                                                            */
/******************************************************************************/
/* Author:   Mikel Skreen                                                     */
/* Copyright 2016, Digilent Inc.                                              */
/******************************************************************************/
/* File Description:                                                          */
/*                                                                            */
/* This demo continuously captures keypad data and prints a message to an     */
/* attached serial terminal whenever a positive edge is detected on any of    */
/* the sixteen keys. In order to receive messages, a serial terminal          */
/* application on your PC should be connected to the appropriate COM port for */
/* the micro-USB cable connection to your board's USBUART port. The terminal  */
/* should be configured with 8-bit data, no parity bit, 1 stop bit, and the   */
/* the appropriate Baud rate for your application. If you are using a Zynq    */
/* board, use a baud rate of 115200, if you are using a MicroBlaze system,    */
/* use the Baud rate specified in the AXI UARTLITE IP, typically 115200 or    */
/* 9600 Baud.                                                                 */
/*                                                                            */
/******************************************************************************/
/* Revision History:                                                          */
/*                                                                            */
/*    06/08/2016(MikelS):   Created                                           */
/*    08/17/2017(artvvb):   Validated for Vivado 2015.4                       */
/*    08/30/2017(artvvb):   Validated for Vivado 2016.4                       */
/*                          Added Multiple keypress error detection           */
/*    01/27/2018(atangzwj): Validated for Vivado 2017.4                       */
/*                                                                            */
/******************************************************************************/

//https://github.com/Digilent/vivado-library/tree/master/ip/Pmods/PmodKYPD_v1_0

#include "PmodKYPD.h"
#include "sleep.h"
#include "xil_cache.h"
#include "xparameters.h"

#define ROCK 1
#define SCISSORS 3
#define PAPER 2
#define KYPDTURN 0
#define FPGATURN 1
#define CHECKWINNER 2

void GameInitialize();
u8 getKey(u8 *key, u8 *last_key);
void runGame();
void GameCleanup();
void DisableCaches();
void EnableCaches();
void DemoSleep(u32 millis);
void read_byte(char *buf, int max_len);
int parse_1_to_3(const char *s, u8 *a);
char* map_number_to_string(u8 number);

PmodKYPD myDevice;
char buffer[2];

int main(void) {
   GameInitialize();
   runGame();
   GameCleanup();
   return 0;
}

// keytable is determined as follows (indices shown in Keypad position below)
// 12 13 14 15
// 8  9  10 11
// 4  5  6  7
// 0  1  2  3
#define DEFAULT_KEYTABLE "0FED789C456B123A"

void GameInitialize() {
   EnableCaches();
   KYPD_begin(&myDevice, XPAR_PMODKYPD_0_AXI_LITE_GPIO_BASEADDR);
   KYPD_loadKeyTable(&myDevice, (u8*) DEFAULT_KEYTABLE);
}

void runGame(){
   int turn=KYPDTURN;
   u8 KYPD_key, KYPD_last_key = 'x';
   u8 FPGA_key;
   while (1){
      if (turn==KYPDTURN){
         if (getKey(&KYPD_key, &KYPD_last_key) == 0){
            xil_printf("Invalid KYPD key!\r\n" );
            usleep(1000000);
            continue;
         }
         KYPD_key=KYPD_key-'0';
         char* str = map_number_to_string(KYPD_key);
         xil_printf("KYPD Key Pressed: %s\r\n", str);
         turn++;
      }
      if (turn==FPGATURN){
         read_byte(buffer,2);
         if (parse_1_to_3(buffer, &FPGA_key)==-1){
            xil_printf("Invalid PC terminal key!\r\n");
            usleep(1000000);
            continue;
         }
         char* str = map_number_to_string(FPGA_key);
         xil_printf("PC terminal Key Pressed: %s\r\n", str);
         turn++;
      }
      if (turn==CHECKWINNER){
         if (FPGA_key==KYPD_key){
            xil_printf("Draw!\r\n");
            turn=KYPDTURN;
            continue;
         }
         switch (FPGA_key)
         {
         case ROCK:
            if (KYPD_key==SCISSORS)
               xil_printf("PC terminal Wins!\r\n");
            else
               xil_printf("KYPD Wins!\r\n");
         break;
         case SCISSORS:
            if (KYPD_key==PAPER)
               xil_printf("PC terminal Wins!\r\n");
            else
               xil_printf("KYPD Wins!\r\n");
         break;
         case PAPER:
            if (KYPD_key==ROCK)
               xil_printf("PC terminal Wins!\r\n");
            else
               xil_printf("KYPD Wins!\r\n");
         break;
         default:
         xil_printf("Something is Wrong\r\n");
            break;
         }
         turn=KYPDTURN;
      }
   }

}

u8 getKey(u8 *key, u8 *last_key) {
   u16 keystate;
   XStatus status, last_status = KYPD_NO_KEY;
   // Initial value of last_key cannot be contained in loaded KEYTABLE string

   Xil_Out32(myDevice.GPIO_addr, 0xF);

   // xil_printf("Pmod KYPD demo started. Press any key on the Keypad.\r\n");
   while (1) {
      // Capture state of each key
      keystate = KYPD_getKeyStates(&myDevice);

      // Determine which single key is pressed, if any
      status = KYPD_getKeyPressed(&myDevice, keystate, key);

      // Print key detect if a new key is pressed or if status has changed
      if (status == KYPD_SINGLE_KEY
            && (status != last_status || *key != *last_key)) {
         // xil_printf("Key Pressed: %c\r\n", (char) key);
         *last_key = *key;
         if (*key>='1' && *key<='3')
               return 1;
         else
               return 0;
      } else if (status == KYPD_MULTI_KEY && status != last_status)
         xil_printf("Error: Multiple keys pressed\r\n");

      last_status = status;

      usleep(1000);
   }
}

void read_byte(char *buf, int max_len) {
    int i = 0;
    char c;

    while (i < max_len - 1) {
        c = inbyte();  // read from UART
        if (c == '\r' || c == '\n') break;
        buf[i++] = c;
    }
    buf[i] = '\0';
}

int parse_1_to_3(const char *s, u8 *a) {
    int i = 0;

    *a = 0;
    if (s[i]>='1' && s[i]<='3'){
      *a = s[i]-'0';
      return 0;
   }
   else 
      return -1;
}

char* map_number_to_string(u8 number){
   switch(number)
   {
      case ROCK:
         return "ROCK";
      case SCISSORS:
         return "SCISSORS";
      case PAPER:
         return "PAPER";
   }
   return NULL;
}
void GameCleanup() {
   DisableCaches();
}

void EnableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
   Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
   Xil_DCacheEnable();
#endif
#endif
}

void DisableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
   Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
   Xil_ICacheDisable();
#endif
#endif
}
