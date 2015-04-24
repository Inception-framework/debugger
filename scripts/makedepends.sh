#!/bin/bash

#
# SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
# Copyright (C) 2015 - Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

usage="usage: $0 rootdir"
if (( $# != 1 )); then
  echo $usage
  exit -1
fi
rootdir=$1
buildrootdir=$rootdir/build
srcrootdir=$rootdir/src
depfilename=dependencies.txt
ignorefilename=ignore

all_tags=""
doc_srcs=""
doc_vsrcs=""
modules=`cd $srcrootdir; ls`

for m in $modules; do
  srcdir=$srcrootdir/$m
  builddir=$buildrootdir/${m}_lib
  printf "${m}-srcs = \$(wildcard \$(srcrootdir)/$m/*.vhd)\n"
  printf "${m}-vsrcs = \$(wildcard \$(srcrootdir)/$m/*.v)\n"
  printf "${m}-tags = \$(patsubst \$(srcrootdir)/$m/%%.vhd,\$(buildrootdir)/${m}_lib/%%.tag,\$(${m}-srcs)) \$(patsubst \$(srcrootdir)/$m/%%.v,\$(buildrootdir)/${m}_lib/%%.tag,\$(${m}-vsrcs))\n"
  printf "\$(${m}-tags): \$(buildrootdir)/${m}_lib/exists\n"
  printf "${m}_lib: \$(${m}-tags)\n"
  for f in $srcdir/*.vhd; do
	  if [ -f "$f" ]; then
		  b=`basename $f .vhd`
		  printf "${m}_lib.$b: \$(buildrootdir)/${m}_lib/$b.tag\n"
		  printf "\$(buildrootdir)/${m}_lib/$b.tag: \$(srcrootdir)/$m/$b.vhd\n"
	  fi
  done
  for f in $srcdir/*.v; do
	  if [ -f "$f" ]; then
		  b=`basename $f .v`
		  printf "${m}_lib.$b: \$(buildrootdir)/${m}_lib/$b.tag\n"
		  printf "\$(buildrootdir)/${m}_lib/$b.tag: \$(srcrootdir)/$m/$b.v\n"
	  fi
  done
  dl="$srcdir/$depfilename"
  if [ -f $dl ]; then
    sed -r -e '
      # delete comments
      s/#.*//
      # remove leading blanks
      s/^[[:blank:]]+//
      # remove trailing blanks
      s/[[:blank:]]+$//
      # delete empty lines
      /^$/d
      # remove blanks between target names and :
      s/[[:blank:]]+:/:/
      # remove rules with .NOSYN target
      /^\.NOSYN:/,/[^\\]$/d
      # change composite names l.e to $buildrootdir/l/e.tag
      s#([^[:blank:]\\:\.]+)\.([^[:blank:]\\:\.]+)#$(buildrootdir)/\1/\2.tag#g
      # change simple names e to $builddir/e.tag ...
      # ... when e is the single name on a line ...
      s#^([^[:blank:]\\:\.]+)$#$(buildrootdir)/'$m'_lib/\1.tag#
      # ... when e is the first name on a line, followed by a blank, a \ or a : ...
      s#^([^[:blank:]\\:\.]+)([[:blank:]\\:])#$(buildrootdir)/'$m'_lib/\1.tag\2#
      # ... when e is the last name on a line, preceded by a blank or a : ...
      s#([[:blank:]:])([^[:blank:]\\:\.]+)$#\1$(buildrootdir)/'$m'_lib/\2.tag#
      # beginning of loop x
      :x
      # ... when e is preceded by a blank or a : and followed by a  blank, a \ or a : ...
      s#([[:blank:]:])([^[:blank:]\\:\.]+)([[:blank:]\\:])#\1$(buildrootdir)/'$m'_lib/\2.tag\3#g
      # loop if matched
      tx
      s#EXTERN/([^[:blank:]\\:\.]+).tag#externs/\1.ext#g
      ' $dl
  fi
  printf "\n"
  if [ -f $srcrootdir/$m/$ignorefilename ]; then
    continue
  fi
  all_tags="$all_tags \$(${m}-tags)"
  doc_srcs="$doc_srcs \$(${m}-srcs)"
  doc_vsrcs="$doc_vsrcs \$(${m}-vsrcs)"
done

printf "all-tags = $all_tags\n"
printf "doc-srcs = $doc_srcs\n"
printf "doc-vsrcs = $doc_vsrcs\n"
printf "\$(vhdocldir)/done: \$(doc-srcs)\n"
