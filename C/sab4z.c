/*
 * Copyright (C) Telecom ParisTech
 * 
 * This file must be used under the terms of the CeCILL. This source
 * file is licensed as described in the file COPYING, which you should
 * have received as part of this distribution. The terms are also
 * available at:
 * http://www.cecill.info/licences/Licence_CeCILL_V1.1-US.txt
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <inttypes.h>

// Base address of registers
#define REGS_ADDR 0x40000000
#define REGS_PAGE_SIZE 8UL
#define REGS_ADDR_MASK (REGS_PAGE_SIZE - 1)
// Base address of DDR (when accessed across the PL)
#define MEM_ADDR 0x80000000
#define MEM_PAGE_SIZE 0x40000000UL
#define MEM_ADDR_MASK (MEM_PAGE_SIZE - 1)

off_t phys_addr[2] = {REGS_ADDR, MEM_ADDR}; // Physical addresses
unsigned long page_size[2] = {REGS_PAGE_SIZE, MEM_PAGE_SIZE}; // Pages sizes
void *virt_addr[2]; // Virtual addresses
int size;

int main(int argc, char **argv) {
  unsigned p, len, min, max, i, j;
  char *str, *mem;
  int fd;
  int st;
  uint32_t *regs;

  st = 0; // Exit status
  while(1) { // Just a trick used for error management
    if(argc != 2) { // If not the right number of arguments...
      fprintf(stderr, "usage: %s <string>\n", argv[0]);
      st = 1;
      break;
    }
    str = argv[1]; // String to search for
    len = strlen(str); // Length of string to search for
    fd = open("/dev/mem", O_RDWR | O_SYNC); // Open dev-mem character device
    if(fd == -1) { // If cannot open...
      fprintf(stderr, "cannot open /dev/mem\n");
      st = 1;
      break;
    }
    for(p = 0; p < 2; p++) { // For all regions to map (2 only: registers and DDR)...
      virt_addr[p] = mmap(0, page_size[p], PROT_READ | PROT_WRITE, MAP_SHARED, fd, phys_addr[p]); // Map region
      if(virt_addr[p] == (void *) -1) { // If cannot map...
        fprintf(stderr, "cannot map memory\n");
        st = 1;
        break;
      }
    }
    if(p != 2) { // If could not map all regions...
      st = 1;
      break;
    }
    regs = (uint32_t *)(virt_addr[0]); // Registers region
    mem = (char *)(virt_addr[1]); // DDR region
    printf("Hello SAB4Z\n"); // Print welcome message
    printf("  0x%08x: %08x (STATUS)\n", REGS_ADDR, regs[0]); // Print content of status register
    printf("  0x%08x: %08x (R)\n", REGS_ADDR + 4, regs[1]); // Print content of r register
    regs[1] = 0x12345678; // Write r register
    for(i = 0x00100000; i < 0x01100000 - len; i++) { // For all bytes in [2G+1M..2G.17M[...
      if(str[0] == mem[i]) { // If byte matches first character of string to search for...
        if(strncmp(str, mem + i, len) == 0) { // If strings match...
          min = (i - 20) < 0x00100000 ? 0x00100000 : i - 20; // Offset of first character to print
          max = (i + len + 20) >= 0x20000000 ? 0x1fffffff : i + len + 20; // Offset of last character to print
          printf("  0x%08x: ", min + MEM_ADDR); // Print address of first character of matching string
          for(j = min; j < max; j++) { // For characters to print...
            if(mem[j] >= 32 && mem[j] < 127) { // If printable character...
              printf("%c", mem[j]); // Print it
            } else { // If not printable character...
              printf("."); // Print a dot
            }
          }
          printf("\n");
          break; // String found, stop searching
        }
      }
    }
    if(i == 0x01100000 - len) { // If string not found
      printf("  String not found\n"); // Print not-found message
    }
    printf("  0x%08x: %08x (STATUS)\n", REGS_ADDR, regs[0]); // Print content of status register
    printf("  0x%08x: %08x (R)\n", REGS_ADDR + 4, regs[1]); // Print content of r register
    printf("Bye! SAB4Z\n"); // Print good bye message
    close(fd); // Close dev-mem character device
    for(p = 0; p < 2; p++) { // For all memory regions...
      if(munmap(virt_addr[p], page_size[p]) == -1) { // If cannot unmap region...
        fprintf(stderr, "cannot unmap memory\n");
        st = 1;
      }
    }
    break; // This is the end 
  }
  return st; // Return exit status (0: no error)
}
