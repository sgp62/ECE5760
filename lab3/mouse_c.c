///////////////////////////////////////
/// 640x480 version!
/// test VGA with hardware video input copy to VGA
// compile with
// gcc fp_test_1.c -o fp1 -lm
///////////////////////////////////////
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/ipc.h> 
#include <sys/shm.h> 
#include <sys/mman.h>
#include <sys/time.h> 
#include <math.h> 
#include <sys/stat.h>
#include <pthread.h>

#include "address_map_arm_brl4.h"

/* function prototypes */
void VGA_text (int, int, char *);
void VGA_text_clear();
void VGA_box (int, int, int, int, short);
void GPU_box (int, int, int, int, short);
void VGA_line(int, int, int, int, short) ;
void VGA_disc (int, int, int, short);
int  VGA_read_pixel(int, int) ;
int  video_in_read_pixel(int, int);
void draw_delay(void) ;

// the light weight buss base
void *h2p_lw_virtual_base;

// RAM FPGA command buffer
volatile unsigned int * sram_ptr = NULL ;
void *sram_virtual_base;

//mouse zoom pio:
volatile int *pio_mouse_zoom_ptr = NULL; // positive
//complex coord increments sent by the FPGA
volatile int *pio_cr_incr_ptr = NULL;  
volatile int *pio_ci_incr_ptr = NULL; 

volatile int *pio_cr_left_ptr = NULL; 
volatile int *pio_cr_right_ptr = NULL;  
volatile int *pio_ci_top_ptr = NULL; 
volatile int *pio_ci_bottom_ptr = NULL; 

volatile int *pio_max_iter = NULL;
volatile int *pio_cycles = NULL;
volatile char *pio_reset = NULL;
 

// pixel buffer
volatile unsigned int * vga_pixel_ptr = NULL ;
void *vga_pixel_virtual_base;

// character buffer
volatile unsigned int * vga_char_ptr = NULL ;
void *vga_char_virtual_base;

// /dev/mem file id
int fd;

//=======================================================
// pixel macro
// !!!PACKED VGA MEMORY!!!
// The lines are contenated with no padding
#define VGA_PIXEL(x,y,color) do{\
	char  *pixel_ptr ;\
	pixel_ptr = (char *)vga_pixel_ptr + ((y)*640) + (x) ;\
	*(char *)pixel_ptr = (color);\
} while(0)
//========================================================	
// swap macro
#define SWAP(X,Y) do{int temp=X; X=Y; Y=temp;}while(0) 
//========================================================		

// measure time
struct timeval t1, t2;
double elapsedTime;
struct timespec delay_time ;

//MUTEXES:
pthread_mutex_t mouse_mtx = PTHREAD_MUTEX_INITIALIZER;


float fix_to_float(int fix);


// convert 32-bit sign extended 4.23 fixed point to float
float fix_to_float(int fix)
{
	// fix: {31:23} int bits {22:0} decimal bits
	return ((float)fix / (float)(1 << 23));
}



signed int mouse_x , mouse_y;
int zoom = 1;
int bytes;
unsigned char data[3];
int fd_mouse; // /dev/input/mice
//int flags = fcntl(fd, F_GETFL, 0);
//fcntl(fd, F_SETFL, flags | O_NONBLOCK);
int left, middle, right;

signed char x_delta, y_delta;
int input_int;
  
void *scanner_thread(){
   while (1)
	{
		// Wait for user command input
    // POLL FOR MAX ITER
		printf("Enter new value for max number of iterations: ");
    scanf("%d", &input_int);
		if (input_int > 0 )
		{
      *pio_max_iter = input_int;
		}
   }
}  
  
void *reset_thread(){
  while(1)
    {
    if(*pio_reset == 1){
        //*pio_max_iter = 1000;
  	    pthread_mutex_lock(&mouse_mtx);
        mouse_x = 0;
        mouse_y = 0;
        *pio_mouse_zoom_ptr &= 0x3;
        zoom = 1;
  	    pthread_mutex_unlock(&mouse_mtx);
     }
        // PRINT CORNERS	
	char cr_bound_text[40];
	char ci_bound_text[40];
        // PRINT CYCLES
	char cycles_text[40];
	sprintf(cr_bound_text, "cr: [%f,%f]", fix_to_float(*pio_cr_left_ptr),fix_to_float(*pio_cr_right_ptr));
	sprintf(ci_bound_text, "ci: [%f,%f]", fix_to_float(*pio_ci_bottom_ptr),fix_to_float(*pio_ci_top_ptr));
	sprintf(cycles_text, "cycles:: %f", (*pio_cycles)/50000.0f);
	VGA_text(5, 52, cr_bound_text);
	VGA_text(5, 53, ci_bound_text);
	VGA_text(5, 54, cycles_text);
   }
}

void *mouse_thread(){
  while(1)
    {
        int flags = fcntl(fd_mouse, F_GETFL, 0);
        fcntl(fd_mouse, F_SETFL, flags | O_NONBLOCK);
        //printf("b4 read\n");
        //READ FROM MOUSE
        bytes = read(fd_mouse, data, sizeof(data));
        //printf("after read\n");
  //	    pthread_mutex_lock(&mouse_mtx);
  //      printf("mouse_x: %d\n", mouse_x);
  //      printf("mouse_y: %d\n", mouse_y);
  //	    pthread_mutex_unlock(&mouse_mtx);
        
        //printf("mouse zoom: %x\n", *pio_mouse_zoom_ptr);
        //printf("mouse zoom amt: %d\n\n\n", zoom);
        if(bytes > 0)
        {
            left = data[0] & 0x1; // Zoom In
            right = data[0] & 0x2; // Zoom Out
            x_delta = data[1];
            y_delta = data[2];
            //printf("x=%d, y=%d, left=%d, right=%d\n", x_delta, y_delta, left, right);
      	    pthread_mutex_lock(&mouse_mtx);
            //printf("mouse_x: %d\n", mouse_x);
            //printf("mouse_y: %d\n", mouse_y);
            //printf("mouse_y: 0x%08x\n", (mouse_y));
            //printf("mouse zoom: 0x%08x\n\n", *pio_mouse_zoom_ptr);
      	    pthread_mutex_unlock(&mouse_mtx);
            if (left) {
              zoom += 1;
              *pio_mouse_zoom_ptr = 0x2;
            } //10
            else if (right == 2){
              *pio_mouse_zoom_ptr = 0x1; //01
              if (zoom < 2) zoom = 1;
              else zoom -= 1;
            }
            else *pio_mouse_zoom_ptr = 0; //00
  	        pthread_mutex_lock(&mouse_mtx);
            mouse_x += x_delta>>3;
            mouse_y += y_delta>>2;
            *pio_mouse_zoom_ptr |= ((mouse_x & 0x7FFF)<<17);
            *pio_mouse_zoom_ptr |= ((mouse_y & 0x7FFF)<<2); //get 15 bits
  	        pthread_mutex_unlock(&mouse_mtx);
            
        }   
        int x_bound = 1<<15-1;
        int y_bound = 1<<15-1;
        if (mouse_x > x_bound){
  	        pthread_mutex_lock(&mouse_mtx);
          mouse_x = x_bound;
  	        pthread_mutex_unlock(&mouse_mtx);
        }
        else if (mouse_x < -x_bound){
  	        pthread_mutex_lock(&mouse_mtx);
          mouse_x = -x_bound;
  	        pthread_mutex_unlock(&mouse_mtx);
        }
        if (mouse_y > y_bound){
  	        pthread_mutex_lock(&mouse_mtx);
          mouse_y = y_bound;
  	        pthread_mutex_unlock(&mouse_mtx);
        }
        else if (mouse_y < -y_bound){
  	        pthread_mutex_lock(&mouse_mtx);
          mouse_y = -y_bound;
  	        pthread_mutex_unlock(&mouse_mtx);
        }
        
      //}
        //else{
            //printf("read nothing\n");
        //    *pio_mouse_zoom_ptr = 0;
        //}
    }
}
  

	
int main(void)
{
	delay_time.tv_nsec = 10 ;
	delay_time.tv_sec = 0 ;

	// Declare volatile pointers to I/O registers (volatile 	// means that IO load and store instructions will be used 	// to access these pointer locations, 
	// instead of regular memory loads and stores) 
  	
	// === need to mmap: =======================
	// FPGA_CHAR_BASE
	// FPGA_ONCHIP_BASE      
	// HW_REGS_BASE        
  
	// === get FPGA addresses ==================
    // Open /dev/mem
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) 	{
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
    
    // get virtual addr that maps to physical
	// for light weight bus
	h2p_lw_virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );	
	if( h2p_lw_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap1() failed...\n" );
		close( fd );
		return(1);
	}
	
	// === get VGA char addr =====================
	// get virtual addr that maps to physical
	vga_char_virtual_base = mmap( NULL, FPGA_CHAR_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_CHAR_BASE );	
	if( vga_char_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap2() failed...\n" );
		close( fd );
		return(1);
	}
    
    // Get the address that maps to the character 
	vga_char_ptr =(unsigned int *)(vga_char_virtual_base);

	// === get VGA pixel addr ====================
	// get virtual addr that maps to physical
	// SDRAM
	vga_pixel_virtual_base = mmap( NULL, SDRAM_FPGA_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, SDRAM_BASE); //SDRAM_BASE	
	
	if( vga_pixel_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap3() failed...\n" );
		close( fd );
		return(1);
	}
    // Get the address that maps to the FPGA pixel buffer
	vga_pixel_ptr =(unsigned int *)(vga_pixel_virtual_base);
 
 
 // Get the address that maps to the PIO ports
	pio_mouse_zoom_ptr = (unsigned int *)(vga_pixel_virtual_base + MOUSE_ZOOM);
	pio_cr_incr_ptr = (unsigned int *)(vga_pixel_virtual_base + CR_INCR);
	pio_ci_incr_ptr = (unsigned int *)(vga_pixel_virtual_base + CI_INCR);
  pio_cr_left_ptr = (unsigned int *)(vga_pixel_virtual_base + CR_LEFT); 
  pio_cr_right_ptr = (unsigned int *)(vga_pixel_virtual_base + CR_RIGHT); 
  pio_ci_top_ptr = (unsigned int *)(vga_pixel_virtual_base + CI_TOP); 
  pio_ci_bottom_ptr = (unsigned int *)(vga_pixel_virtual_base + CI_BOTTOM); 
  pio_max_iter = (unsigned int *)(vga_pixel_virtual_base + MAX_ITER);
  pio_cycles = (unsigned int *)(vga_pixel_virtual_base + CYCLES);
  pio_reset = (unsigned char *)(vga_pixel_virtual_base + RESET);
	
	
	// === get RAM FPGA parameter addr =========
	sram_virtual_base = mmap( NULL, FPGA_ONCHIP_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_ONCHIP_BASE); //fp	
	
	if( sram_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap3() failed...\n" );
		close( fd );
		return(1);
	}
    // Get the address that maps to the RAM buffer
	sram_ptr =(unsigned int *)(sram_virtual_base);
	
	// ===========================================

	/* create a message to be displayed on the VGA 
          and LCD displays */
	char text_top_row[40] = "DE1-SoC ARM/FPGA\0";
	char text_bottom_row[40] = "Cornell ece5760\0";
	char num_string[20], time_string[50];
	
	// a pixel from the video
	int pixel_color;
	// video input index
	int i,j, count;
	
	// clear the screen
	//VGA_box (0, 0, 639, 479, 0x03);
	// clear the text
	VGA_text_clear();
	VGA_text (5, 50, text_top_row);
	VGA_text (5, 51, text_bottom_row);
	
	count = 0;
	// set a seed for rnadom numbers
	srand((unsigned) time(&t1));
 
 
 //====================MOUSE=========================================
 
   mouse_x = 0;
   mouse_y = 0;
  
  const char *pDevice = "/dev/input/mice";
  
  // Open Mouse
  fd_mouse = open(pDevice, O_RDWR);
  if(fd_mouse == -1)
  {
      printf("ERROR Opening %s\n", pDevice);
      return -1;
  }
  
  
  
  //NEED  TO RESET TO ZERO ON FPGA RESET - pio port or smth
  //struct stat st;
  *pio_max_iter = 1000;
  
  // scanning (user input thread) and draw/clock thread
	pthread_t thread_mouse, thread_reset,thread_scanner ;

	pthread_attr_t attr;
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

	// create threads
	pthread_create(&thread_mouse, NULL, mouse_thread, NULL);
	pthread_create(&thread_reset, NULL, reset_thread, NULL);
	pthread_create(&thread_scanner, NULL, scanner_thread, NULL);

	// join threads
	pthread_join(thread_mouse, NULL);
	pthread_join(thread_reset, NULL);
	pthread_join(thread_scanner, NULL);
  
  
  
  return 0; 
 
 
 
 
 
 
} // end main


///////////////////////////////////////////////////////////////////////
// Mouse test from 
// http://stackoverflow.com/questions/11451618/how-do-you-read-the-mouse-button-state-from-dev-input-mice
//
// Native ARM GCC Compile: gcc mouse_test.c -o mouse
//
///////////////////////////////////////////////////////////////////////
/*
int mouse(void)
{
    int fd, bytes;
    unsigned char data[3];

    const char *pDevice = "/dev/input/mice";

    // Open Mouse
    fd = open(pDevice, O_RDWR);
    if(fd == -1)
    {
        printf("ERROR Opening %s\n", pDevice);
        return -1;
    }

    int left, middle, right;
    signed char x, y;
    while(1)
    {
        // Read Mouse     
        bytes = read(fd, data, sizeof(data));

        if(bytes > 0)
        {
            left = data[0] & 0x1; // Zoom In
            right = data[0] & 0x2; // Zoom Out
            x = data[1];
            y = data[2];
            printf("x=%d, y=%d, left=%d, right=%d\n", x, y, left, right);
        }   
    }
    return
     0; 
}
*/
	

/****************************************************************************************
 * Subroutine to read a pixel from the video input 
****************************************************************************************/
// int  video_in_read_pixel(int x, int y){
	// char  *pixel_ptr ;
	// pixel_ptr = (char *)video_in_ptr + ((y)<<9) + (x) ;
	// return *pixel_ptr ;
// }

/****************************************************************************************
 * Subroutine to read a pixel from the VGA monitor 
****************************************************************************************/
int  VGA_read_pixel(int x, int y){
	char  *pixel_ptr ;
	pixel_ptr = (char *)vga_pixel_ptr + ((y)*640) + (x) ;
	return *pixel_ptr ;
}

/****************************************************************************************
 * Subroutine to send a string of text to the VGA monitor 
****************************************************************************************/
void VGA_text(int x, int y, char * text_ptr)
{
  	volatile char * character_buffer = (char *) vga_char_ptr ;	// VGA character buffer
	int offset;
	/* assume that the text string fits on one line */
	offset = (y << 7) + x;
	while ( *(text_ptr) )
	{
		// write to the character buffer
		*(character_buffer + offset) = *(text_ptr);	
		++text_ptr;
		++offset;
	}
}

/****************************************************************************************
 * Subroutine to clear text to the VGA monitor 
****************************************************************************************/
void VGA_text_clear()
{
  	volatile char * character_buffer = (char *) vga_char_ptr ;	// VGA character buffer
	int offset, x, y;
	for (x=0; x<79; x++){
		for (y=0; y<59; y++){
	/* assume that the text string fits on one line */
			offset = (y << 7) + x;
			// write to the character buffer
			*(character_buffer + offset) = ' ';		
		}
	}
}

/****************************************************************************************
 * Draw a filled rectangle using the VGA GPU 
****************************************************************************************/
void GPU_box(int x1, int y1, int x2, int y2, short color)
{
	// sram buffer
	// addr=0 start bit
	// addr=1 x1, addr=2 y1
	// addr=3 x2, addr=4 y2
	// addr=5 color
	// check validity of parameters
	if (x1>639) x1 = 639;
	if (y1>479) y1 = 479;
	if (x2>639) x2 = 639;
	if (y2>479) y2 = 479;
	if (x1<0) x1 = 0;
	if (y1<0) y1 = 0;
	if (x2<0) x2 = 0;
	if (y2<0) y2 = 0;
	if (x1>x2) SWAP(x1,x2);
	if (y1>y2) SWAP(y1,y2);
	// set up scratch pad parameters
	*(sram_ptr+1) = x1;
	*(sram_ptr+2) = y1;
	*(sram_ptr+3) = x2;
	*(sram_ptr+4) = y2;
	*(sram_ptr+5) = color;
	*(sram_ptr) = 1; // the "data-ready" flag

	// wait for FPGA to zero the "data_ready" flag
	while (*(sram_ptr)>0) ;
	
}
/****************************************************************************************
 * Draw a filled rectangle on the VGA monitor 
****************************************************************************************/
#define SWAP(X,Y) do{int temp=X; X=Y; Y=temp;}while(0) 

void VGA_box(int x1, int y1, int x2, int y2, short pixel_color)
{
	char  *pixel_ptr ; 
	int row, col;

	/* check and fix box coordinates to be valid */
	if (x1>639) x1 = 639;
	if (y1>479) y1 = 479;
	if (x2>639) x2 = 639;
	if (y2>479) y2 = 479;
	if (x1<0) x1 = 0;
	if (y1<0) y1 = 0;
	if (x2<0) x2 = 0;
	if (y2<0) y2 = 0;
	if (x1>x2) SWAP(x1,x2);
	if (y1>y2) SWAP(y1,y2);
	for (row = y1; row <= y2; row++)
		for (col = x1; col <= x2; ++col)
		{
			//640x480
			VGA_PIXEL(col, row, pixel_color);
			//pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
			// set pixel color
			//*(char *)pixel_ptr = pixel_color;		
		}
}

/****************************************************************************************
 * Draw a filled circle on the VGA monitor 
****************************************************************************************/

void VGA_disc(int x, int y, int r, short pixel_color)
{
	char  *pixel_ptr ; 
	int row, col, rsqr, xc, yc;
	
	rsqr = r*r;
	
	for (yc = -r; yc <= r; yc++)
		for (xc = -r; xc <= r; xc++)
		{
			col = xc;
			row = yc;
			// add the r to make the edge smoother
			if(col*col+row*row <= rsqr+r){
				col += x; // add the center point
				row += y; // add the center point
				//check for valid 640x480
				if (col>639) col = 639;
				if (row>479) row = 479;
				if (col<0) col = 0;
				if (row<0) row = 0;
				VGA_PIXEL(col, row, pixel_color);
				//pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
				// set pixel color
				//nanosleep(&delay_time, NULL);
				//draw_delay();
				//*(char *)pixel_ptr = pixel_color;
			}
					
		}
}

// =============================================
// === Draw a line
// =============================================
//plot a line 
//at x1,y1 to x2,y2 with color 
//Code is from David Rodgers,
//"Procedural Elements of Computer Graphics",1985
void VGA_line(int x1, int y1, int x2, int y2, short c) {
	int e;
	signed int dx,dy,j, temp;
	signed int s1,s2, xchange;
     signed int x,y;
	char *pixel_ptr ;
	
	/* check and fix line coordinates to be valid */
	if (x1>639) x1 = 639;
	if (y1>479) y1 = 479;
	if (x2>639) x2 = 639;
	if (y2>479) y2 = 479;
	if (x1<0) x1 = 0;
	if (y1<0) y1 = 0;
	if (x2<0) x2 = 0;
	if (y2<0) y2 = 0;
        
	x = x1;
	y = y1;
	
	//take absolute value
	if (x2 < x1) {
		dx = x1 - x2;
		s1 = -1;
	}

	else if (x2 == x1) {
		dx = 0;
		s1 = 0;
	}

	else {
		dx = x2 - x1;
		s1 = 1;
	}

	if (y2 < y1) {
		dy = y1 - y2;
		s2 = -1;
	}

	else if (y2 == y1) {
		dy = 0;
		s2 = 0;
	}

	else {
		dy = y2 - y1;
		s2 = 1;
	}

	xchange = 0;   

	if (dy>dx) {
		temp = dx;
		dx = dy;
		dy = temp;
		xchange = 1;
	} 

	e = ((int)dy<<1) - dx;  
	 
	for (j=0; j<=dx; j++) {
		//video_pt(x,y,c); //640x480
		VGA_PIXEL(x, y, c);
		//pixel_ptr = (char *)vga_pixel_ptr + (y<<10)+ x; 
		// set pixel color
		//*(char *)pixel_ptr = c;	
		 
		if (e>=0) {
			if (xchange==1) x = x + s1;
			else y = y + s2;
			e = e - ((int)dx<<1);
		}

		if (xchange==1) y = y + s2;
		else x = x + s1;

		e = e + ((int)dy<<1);
	}
}


/////////////////////////////////////////////

#define NOP10() asm("nop;nop;nop;nop;nop;nop;nop;nop;nop;nop")

void draw_delay(void){
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10(); //16
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10(); //32
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10(); //48
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10(); //64
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10();
	NOP10(); NOP10(); NOP10(); NOP10(); //68
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10(); //80
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10();
	// NOP10(); NOP10(); NOP10(); NOP10(); //96
}

/// /// ///////////////////////////////////// 
/// end /////////////////////////////////////