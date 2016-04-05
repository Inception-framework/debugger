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

void main(void) {
  int i, s;

  printf("Hello SAB4Z\n");
  s = 0;
  for(i = 0; i <= 100; i++) {
    s += i;
  }
  printf("sum_{i=0}^{i=100}{i}=%d\n", s);
  sleep(2);
  printf("Bye! SAB4Z\n");
}
