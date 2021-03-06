///////////////////////////////////////
/// 640x480 version! 16-bit color
/// This code will segfault the original
/// DE1 computer
/// compile with
/// gcc graphics_video_16bit.c -o gr -O2 -lm
///
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
#include <pthread.h>
//#include "address_map_arm_brl4.h"

// video display
#define SDRAM_BASE 0xC0000000
#define SDRAM_END 0xC3FFFFFF
#define SDRAM_SPAN 0x04000000
#define SDRAM_FPGA_SPAN 0x06000000

#define NUM_ROWS 0x5000000
#define RHO 0x5000010
#define INITIAL_AMP 0x5000020
#define G_TENSION 0x5000030
#define ETA_TERM 0x5000040
#define UPDATE_CYCLES 0x5000050

// all powers of 2
volatile int *pio_num_rows_ptr = NULL; // positive
volatile int *pio_rho_ptr = NULL;
volatile int *pio_initial_amp_ptr = NULL; // positive
volatile int *pio_g_tension_ptr = NULL;
volatile int *pio_eta_term_ptr = NULL;
volatile int *pio_update_cycles_ptr = NULL;

float fix_to_float(int);
int float_to_fix(double f);

// characters
#define FPGA_CHAR_BASE 0xC9000000
#define FPGA_CHAR_END 0xC9001FFF
#define FPGA_CHAR_SPAN 0x00002000
/* Cyclone V FPGA devices */
#define HW_REGS_BASE 0xff200000
//#define HW_REGS_SPAN        0x00200000
#define HW_REGS_SPAN 0x00005000

// graphics primitives
void VGA_text(int, int, char *);
void VGA_text_clear();
void VGA_box(int, int, int, int, short);
void VGA_rect(int, int, int, int, short);
void VGA_line(int, int, int, int, short);
void VGA_Vline(int, int, int, short);
void VGA_Hline(int, int, int, short);
void VGA_disc(int, int, int, short);
void VGA_circle(int, int, int, int);
// 16-bit primary colors
#define red (0 + (0 << 5) + (31 << 11))
#define dark_red (0 + (0 << 5) + (15 << 11))
#define green (0 + (63 << 5) + (0 << 11))
#define dark_green (0 + (31 << 5) + (0 << 11))
#define blue (31 + (0 << 5) + (0 << 11))
#define dark_blue (15 + (0 << 5) + (0 << 11))
#define yellow (0 + (63 << 5) + (31 << 11))
#define cyan (31 + (63 << 5) + (0 << 11))
#define magenta (31 + (0 << 5) + (31 << 11))
#define black (0x0000)
#define gray (15 + (31 << 5) + (51 << 11))
#define white (0xffff)
int colors[] = {red, dark_red, green, dark_green, blue, dark_blue,
								yellow, cyan, magenta, gray, black, white};

// pixel macro
#define VGA_PIXEL(x, y, color)                                           \
	do                                                                     \
	{                                                                      \
		int *pixel_ptr;                                                      \
		pixel_ptr = (int *)((char *)vga_pixel_ptr + (((y)*640 + (x)) << 1)); \
		*(short *)pixel_ptr = (color);                                       \
	} while (0)

// the light weight buss base
void *h2p_lw_virtual_base;

// pixel buffer
volatile unsigned int *vga_pixel_ptr = NULL;
void *vga_pixel_virtual_base;

// character buffer
volatile unsigned int *vga_char_ptr = NULL;
void *vga_char_virtual_base;

// /dev/mem file id
int fd;

// measure time
struct timeval t1, t2;
double elapsedTime;

// clock period in microseconds
unsigned long clock_period = 10000;

// token for string parsing
char *token;

unsigned int updated_params = 0;

unsigned int paused = 0;

#define SCALE (4.6)

// Mutexes

// pthread_mutex_t clk_mtx = PTHREAD_MUTEX_INITIALIZER;
char input_buffer[64];
int input_int;

// convert float to 32-bit sign extended 7.20 fixed point
int float_to_fix(double f)
{
	// fix: {31:20} int bits {19:0} decimal bits
	return (int)((float)f * (float)(1 << 20));
}

int main(void)
{

	// === need to mmap: =======================
	// FPGA_CHAR_BASE
	// FPGA_ONCHIP_BASE
	// HW_REGS_BASE

	// === get FPGA addresses ==================
	// Open /dev/mem
	if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1)
	{
		printf("ERROR: could not open \"/dev/mem\"...\n");
		return (1);
	}

	// get virtual addr that maps to physical
	h2p_lw_virtual_base = mmap(NULL, HW_REGS_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, HW_REGS_BASE);
	if (h2p_lw_virtual_base == MAP_FAILED)
	{
		printf("ERROR: mmap1() failed...\n");
		close(fd);
		return (1);
	}

	// === get VGA char addr =====================
	// get virtual addr that maps to physical
	vga_char_virtual_base = mmap(NULL, FPGA_CHAR_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, FPGA_CHAR_BASE);
	if (vga_char_virtual_base == MAP_FAILED)
	{
		printf("ERROR: mmap2() failed...\n");
		close(fd);
		return (1);
	}

	// Get the address that maps to the FPGA LED control
	vga_char_ptr = (unsigned int *)(vga_char_virtual_base);

	// === get VGA pixel addr ====================
	// get virtual addr that maps to physical
	vga_pixel_virtual_base = mmap(NULL, SDRAM_FPGA_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, SDRAM_BASE);
	if (vga_pixel_virtual_base == MAP_FAILED)
	{
		printf("ERROR: mmap3() failed...\n");
		close(fd);
		return (1);
	}

	// Get the address that maps to the FPGA pixel buffer
	vga_pixel_ptr = (unsigned int *)(vga_pixel_virtual_base);

//	volatile int *pio_num_rows_ptr = NULL;
//	volatile int *pio_rho_ptr = NULL;
//	volatile int *pio_initial_amp_ptr = NULL;
//	volatile int *pio_g_tension_ptr = NULL;
//	volatile int *pio_eta_term_ptr = NULL;
//	volatile int *pio_fpga_update_cycles_ptr = NULL;

	// === get VGA pixel addr ====================
	// Get the address that maps to the PIO ports
	pio_num_rows_ptr = (unsigned int *)(vga_pixel_virtual_base + NUM_ROWS);
	pio_rho_ptr = (unsigned int *)(vga_pixel_virtual_base + RHO);
	pio_initial_amp_ptr = (unsigned int *)(vga_pixel_virtual_base + INITIAL_AMP);
	pio_g_tension_ptr = (unsigned int *)(vga_pixel_virtual_base + G_TENSION);
	pio_eta_term_ptr = (unsigned int *)(vga_pixel_virtual_base + ETA_TERM);
	pio_update_cycles_ptr = (unsigned int *)(vga_pixel_virtual_base + UPDATE_CYCLES);

  *pio_num_rows_ptr = 0x5;
  *pio_rho_ptr = 0x3;
  *pio_initial_amp_ptr = 0x11; // 17
  *pio_g_tension_ptr = 0x6;
  *pio_eta_term_ptr = 0xb; // 11
  

    while (1)
	{
		// Wait for user command input
		printf("Change settings (or press C to display number of cycles per update)? Y/N\n");
		scanf("%s", input_buffer);
		if (strcmp(input_buffer, "Y") == 0 )
		{
			printf("Insert a new number for each (use 0 to keep the previous value)\n");
			printf("Number of rows (number will be taken to the power of 2):\n");

			scanf("%d", &input_int);

      if(input_int) *pio_num_rows_ptr = input_int;

      
			printf("Amplitude multiplier (number will be taken to the power of 2):\n");
			scanf("%d", &input_int);
			if(input_int) *pio_initial_amp_ptr = (((input_int)));
			printf("Rho (number will be taken to the negative power of 2):\n");
			scanf("%d", &input_int);
			if(input_int) *pio_rho_ptr = (((input_int)));
			printf("G_tension (number will be taken to the negative power of 2):\n");
			scanf("%d", &input_int);
			if(input_int) *pio_g_tension_ptr = (((input_int)));
			printf("Eta term (number will be taken to the negative power of 2):\n");
			scanf("%d", &input_int);
			if(input_int) *pio_eta_term_ptr = (((input_int)));
			printf("All Done!\n\n");
		}
		else if (strcmp(input_buffer, "C") == 0 )
		{
			printf("Microseconds for update: %f\n", (float)*pio_update_cycles_ptr/50);
		}
		else if (!strcmp(input_buffer, "N") == 0 )
		{
			printf("Invalid input... please try again\n");
		}
	}

//	pthread_t thread_scan;
//
//	pthread_attr_t attr;
//	pthread_attr_init(&attr);
//	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
//
//	// create threads
//	pthread_create(&thread_scan, NULL, parameter_scanner, NULL);
//
//	// join threads
//	pthread_join(thread_scan, NULL);

	return 0;

} // end main

/****************************************************************************************
 * Subroutine to send a string of text to the VGA monitor
 ****************************************************************************************/
void VGA_text(int x, int y, char *text_ptr)
{
	volatile char *character_buffer = (char *)vga_char_ptr; // VGA character buffer
	int offset;
	/* assume that the text string fits on one line */
	offset = (y << 7) + x;
	while (*(text_ptr))
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
	volatile char *character_buffer = (char *)vga_char_ptr; // VGA character buffer
	int offset, x, y;
	for (x = 0; x < 79; x++)
	{
		for (y = 0; y < 59; y++)
		{
			/* assume that the text string fits on one line */
			offset = (y << 7) + x;
			// write to the character buffer
			*(character_buffer + offset) = ' ';
		}
	}
}

/****************************************************************************************
 * Draw a filled rectangle on the VGA monitor
 ****************************************************************************************/
#define SWAP(X, Y) \
	do               \
	{                \
		int temp = X;  \
		X = Y;         \
		Y = temp;      \
	} while (0)

void VGA_box(int x1, int y1, int x2, int y2, short pixel_color)
{
	char *pixel_ptr;
	int row, col;

	/* check and fix box coordinates to be valid */
	if (x1 > 639)
		x1 = 639;
	if (y1 > 479)
		y1 = 479;
	if (x2 > 639)
		x2 = 639;
	if (y2 > 479)
		y2 = 479;
	if (x1 < 0)
		x1 = 0;
	if (y1 < 0)
		y1 = 0;
	if (x2 < 0)
		x2 = 0;
	if (y2 < 0)
		y2 = 0;
	if (x1 > x2)
		SWAP(x1, x2);
	if (y1 > y2)
		SWAP(y1, y2);
	for (row = y1; row <= y2; row++)
		for (col = x1; col <= x2; ++col)
		{
			// 640x480
			// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
			//  set pixel color
			//*(char *)pixel_ptr = pixel_color;
			VGA_PIXEL(col, row, pixel_color);
		}
}

/****************************************************************************************
 * Draw a outline rectangle on the VGA monitor
 ****************************************************************************************/
#define SWAP(X, Y) \
	do               \
	{                \
		int temp = X;  \
		X = Y;         \
		Y = temp;      \
	} while (0)

void VGA_rect(int x1, int y1, int x2, int y2, short pixel_color)
{
	char *pixel_ptr;
	int row, col;

	/* check and fix box coordinates to be valid */
	if (x1 > 639)
		x1 = 639;
	if (y1 > 479)
		y1 = 479;
	if (x2 > 639)
		x2 = 639;
	if (y2 > 479)
		y2 = 479;
	if (x1 < 0)
		x1 = 0;
	if (y1 < 0)
		y1 = 0;
	if (x2 < 0)
		x2 = 0;
	if (y2 < 0)
		y2 = 0;
	if (x1 > x2)
		SWAP(x1, x2);
	if (y1 > y2)
		SWAP(y1, y2);
	// left edge
	col = x1;
	for (row = y1; row <= y2; row++)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}

	// right edge
	col = x2;
	for (row = y1; row <= y2; row++)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}

	// top edge
	row = y1;
	for (col = x1; col <= x2; ++col)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}

	// bottom edge
	row = y2;
	for (col = x1; col <= x2; ++col)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}
}

/****************************************************************************************
 * Draw a horixontal line on the VGA monitor
 ****************************************************************************************/
#define SWAP(X, Y) \
	do               \
	{                \
		int temp = X;  \
		X = Y;         \
		Y = temp;      \
	} while (0)

void VGA_Hline(int x1, int y1, int x2, short pixel_color)
{
	char *pixel_ptr;
	int row, col;

	/* check and fix box coordinates to be valid */
	if (x1 > 639)
		x1 = 639;
	if (y1 > 479)
		y1 = 479;
	if (x2 > 639)
		x2 = 639;
	if (x1 < 0)
		x1 = 0;
	if (y1 < 0)
		y1 = 0;
	if (x2 < 0)
		x2 = 0;
	if (x1 > x2)
		SWAP(x1, x2);
	// line
	row = y1;
	for (col = x1; col <= x2; ++col)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}
}

/****************************************************************************************
 * Draw a vertical line on the VGA monitor
 ****************************************************************************************/
#define SWAP(X, Y) \
	do               \
	{                \
		int temp = X;  \
		X = Y;         \
		Y = temp;      \
	} while (0)

void VGA_Vline(int x1, int y1, int y2, short pixel_color)
{
	char *pixel_ptr;
	int row, col;

	/* check and fix box coordinates to be valid */
	if (x1 > 639)
		x1 = 639;
	if (y1 > 479)
		y1 = 479;
	if (y2 > 479)
		y2 = 479;
	if (x1 < 0)
		x1 = 0;
	if (y1 < 0)
		y1 = 0;
	if (y2 < 0)
		y2 = 0;
	if (y1 > y2)
		SWAP(y1, y2);
	// line
	col = x1;
	for (row = y1; row <= y2; row++)
	{
		// 640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10)    + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}
}

/****************************************************************************************
 * Draw a filled circle on the VGA monitor
 ****************************************************************************************/

void VGA_disc(int x, int y, int r, short pixel_color)
{
	char *pixel_ptr;
	int row, col, rsqr, xc, yc;

	rsqr = r * r;

	for (yc = -r; yc <= r; yc++)
		for (xc = -r; xc <= r; xc++)
		{
			col = xc;
			row = yc;
			// add the r to make the edge smoother
			if (col * col + row * row <= rsqr + r)
			{
				col += x; // add the center point
				row += y; // add the center point
				// check for valid 640x480
				if (col > 639)
					col = 639;
				if (row > 479)
					row = 479;
				if (col < 0)
					col = 0;
				if (row < 0)
					row = 0;
				// pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
				//  set pixel color
				//*(char *)pixel_ptr = pixel_color;
				VGA_PIXEL(col, row, pixel_color);
			}
		}
}

/****************************************************************************************
 * Draw a  circle on the VGA monitor
 ****************************************************************************************/

void VGA_circle(int x, int y, int r, int pixel_color)
{
	char *pixel_ptr;
	int row, col, rsqr, xc, yc;
	int col1, row1;
	rsqr = r * r;

	for (yc = -r; yc <= r; yc++)
	{
		// row = yc;
		col1 = (int)sqrt((float)(rsqr + r - yc * yc));
		// right edge
		col = col1 + x; // add the center point
		row = yc + y;		// add the center point
		// check for valid 640x480
		if (col > 639)
			col = 639;
		if (row > 479)
			row = 479;
		if (col < 0)
			col = 0;
		if (row < 0)
			row = 0;
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
		// left edge
		col = -col1 + x; // add the center point
		// check for valid 640x480
		if (col > 639)
			col = 639;
		if (row > 479)
			row = 479;
		if (col < 0)
			col = 0;
		if (row < 0)
			row = 0;
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}
	for (xc = -r; xc <= r; xc++)
	{
		// row = yc;
		row1 = (int)sqrt((float)(rsqr + r - xc * xc));
		// right edge
		col = xc + x;		// add the center point
		row = row1 + y; // add the center point
		// check for valid 640x480
		if (col > 639)
			col = 639;
		if (row > 479)
			row = 479;
		if (col < 0)
			col = 0;
		if (row < 0)
			row = 0;
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
		// left edge
		row = -row1 + y; // add the center point
		// check for valid 640x480
		if (col > 639)
			col = 639;
		if (row > 479)
			row = 479;
		if (col < 0)
			col = 0;
		if (row < 0)
			row = 0;
		// pixel_ptr = (char *)vga_pixel_ptr + (row<<10) + col ;
		//  set pixel color
		//*(char *)pixel_ptr = pixel_color;
		VGA_PIXEL(col, row, pixel_color);
	}
}

// =============================================
// === Draw a line
// =============================================
// plot a line
// at x1,y1 to x2,y2 with color
// Code is from David Rodgers,
//"Procedural Elements of Computer Graphics",1985
void VGA_line(int x1, int y1, int x2, int y2, short c)
{
	int e;
	signed int dx, dy, j, temp;
	signed int s1, s2, xchange;
	signed int x, y;
	char *pixel_ptr;

	/* check and fix line coordinates to be valid */
	if (x1 > 639)
		x1 = 639;
	if (y1 > 479)
		y1 = 479;
	if (x2 > 639)
		x2 = 639;
	if (y2 > 479)
		y2 = 479;
	if (x1 < 0)
		x1 = 0;
	if (y1 < 0)
		y1 = 0;
	if (x2 < 0)
		x2 = 0;
	if (y2 < 0)
		y2 = 0;

	x = x1;
	y = y1;

	// take absolute value
	if (x2 < x1)
	{
		dx = x1 - x2;
		s1 = -1;
	}

	else if (x2 == x1)
	{
		dx = 0;
		s1 = 0;
	}

	else
	{
		dx = x2 - x1;
		s1 = 1;
	}

	if (y2 < y1)
	{
		dy = y1 - y2;
		s2 = -1;
	}

	else if (y2 == y1)
	{
		dy = 0;
		s2 = 0;
	}

	else
	{
		dy = y2 - y1;
		s2 = 1;
	}

	xchange = 0;

	if (dy > dx)
	{
		temp = dx;
		dx = dy;
		dy = temp;
		xchange = 1;
	}

	e = ((int)dy << 1) - dx;

	for (j = 0; j <= dx; j++)
	{
		// video_pt(x,y,c); //640x480
		// pixel_ptr = (char *)vga_pixel_ptr + (y<<10)+ x;
		//  set pixel color
		//*(char *)pixel_ptr = c;
		VGA_PIXEL(x, y, c);

		if (e >= 0)
		{
			if (xchange == 1)
				x = x + s1;
			else
				y = y + s2;
			e = e - ((int)dx << 1);
		}

		if (xchange == 1)
			y = y + s2;
		else
			x = x + s1;

		e = e + ((int)dy << 1);
	}
}
