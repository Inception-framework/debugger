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

#define REGS_ADDR 0x40000000
#define REGS_PAGE_SIZE 8UL
#define REGS_ADDR_MASK (REGS_PAGE_SIZE - 1)
#define MEM_ADDR 0x80000000
#define MEM_PAGE_SIZE 0x40000000UL
#define MEM_ADDR_MASK (MEM_PAGE_SIZE - 1)

off_t phys_addr[2] = {REGS_ADDR, MEM_ADDR};
unsigned long page_size[2] = {REGS_PAGE_SIZE, MEM_PAGE_SIZE};
void *virt_addr[2];
int size;

int main(int argc, char **argv) {
  unsigned p, len, min, max, i, j;
  char *str, *mem;
  int fd;
  int st;
  uint32_t *regs;

  st = 0;
  while(1) {
    if(argc != 2) {
      fprintf(stderr, "usage: %s <string>\n", argv[0]);
      st = 1;
      break;
    }
    str = argv[1];
    len = strlen(str);
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if(fd == -1) {
      fprintf(stderr, "cannot open /dev/mem\n");
      st = 1;
      break;
    }
    for(p = 0; p < 2; p++) {
      virt_addr[p] = mmap(0, page_size[p], PROT_READ | PROT_WRITE, MAP_SHARED, fd, phys_addr[p]);
      if(virt_addr[p] == (void *) -1) {
        fprintf(stderr, "cannot map memory\n");
        st = 1;
        break;
      }
    }
    if(p != 2) {
      st = 1;
      break;
    }
    regs = (uint32_t *)(virt_addr[0]);
    mem = (char *)(virt_addr[1]);
    printf("Hello SAB4Z\n");
    printf("  0x%08x: %08x (STATUS)\n", REGS_ADDR, regs[0]);
    printf("  0x%08x: %08x (R)\n", REGS_ADDR + 4, regs[1]);
    regs[1] = 0x12345678;
    for(i = 0x00100000; i < 0x20000000 - len; i++) {
      if(str[0] == mem[i]) {
        if(strncmp(str, mem + i, len) == 0) {
          min = (i - 20) < 0x00100000 ? 0x00100000 : i - 20;
          max = (i + len + 20) >= 0x20000000 ? 0x1fffffff : i + len + 20; 
          printf("  0x%08x: ", min + MEM_ADDR);
          for(j = min; j < max; j++) {
            if(mem[j] >= 32 && mem[j] < 127) {
              printf("%c", mem[j]);
            } else {
              printf(".");
            }
          }
          printf("\n");
          break;
        }
      }
    }
    printf("  0x%08x: %08x (STATUS)\n", REGS_ADDR, regs[0]);
    printf("  0x%08x: %08x (R)\n", REGS_ADDR + 4, regs[1]);
    printf("Bye! SAB4Z\n");
    close(fd);
    for(p = 0; p < 2; p++) {
      if(munmap(virt_addr[p], page_size[p]) == -1) {
        fprintf(stderr, "cannot unmap memory\n");
        st = 1;
      }
    }
    break;
  }
  return st;
}
