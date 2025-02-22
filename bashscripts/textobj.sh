#!/bin/bash

# tectoplot
# bashscripts/textobj.sh
# Copyright (c) 2021 Kyle Bradley, all rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



# arguments: font_obj_directory "string of characters" output_file
FONT_OBJ_DIR="${1}"
shift

OUTPUT_FILE="${1}"
shift

TEXTSTRING="${@}"
cur_vertex=0
cur_x=0
kern=0.1

# Letters are output from Blender but I forgot what I did!

# echo "textobj.sh ${FONT_OBJ_DIR} ${OUTPUT_FILE} ${TEXTSTRING}"

for (( i=0; i<${#TEXTSTRING}; i++ )); do
  thisletter="${TEXTSTRING:$i:1}"
  case $thisletter in
    [a-z])
      objfile="lower${thisletter}.obj"
    ;;
    [A-Z])
      objfile="capital${thisletter}.obj"
      ;;
    [/])
      objfile="forwardslash.obj"
      ;;
    [:])
      objfile="colon.obj"
      ;;
    [.])
      objfile="period.obj"
      ;;
    [-])
      objfile="dash.obj"
      ;;
    [0-9])
      objfile="${thisletter}.obj"
    ;;
    [\ ])
      objfile="space.obj"
      ;;
    [\(])
      objfile="leftparen.obj"
      ;;
    [\)])
      objfile="rightparen.obj"
      ;;
  esac
  case $thisletter in
    0) width=0.470000 ;;
    1) width=0.250000 ;;
    2) width=0.466000 ;;
    3) width=0.424000 ;;
    4) width=0.471000 ;;
    5) width=0.438000 ;;
    6) width=0.465000 ;;
    7) width=0.490000 ;;
    8) width=0.468000 ;;
    9) width=0.461000 ;;
    A) width=0.667000 ;;
    B) width=0.443000 ;;
    C) width=0.663000 ;;
    D) width=0.704000 ;;
    E) width=0.471000 ;;
    F) width=0.440000 ;;
    G) width=0.673000 ;;
    H) width=0.653000 ;;
    I) width=0.174000 ;;
    J) width=0.174000 ;;
    K) width=0.655000 ;;
    L) width=0.480000 ;;
    M) width=0.709000 ;;
    N) width=0.706000 ;;
    O) width=0.778000 ;;
    P) width=0.500000 ;;
    Q) width=0.780000 ;;
    R) width=0.604000 ;;
    S) width=0.426000 ;;
    T) width=0.587000 ;;
    U) width=0.648000 ;;
    V) width=0.604000 ;;
    W) width=1.041000 ;;
    X) width=0.706000 ;;
    Y) width=0.604000 ;;
    Z) width=0.631000 ;;
    :) width=0.059 ;;
    /) width=0.274 ;;
    -) width=0.283 ;;
    [\ ]) width=0.3 ;;
    [\)]) width=0.298826 ;;
    [\(]) width=0.311000 ;;
    [\.]) width=0.169000 ;;
    a) width=0.411000 ;;
    b) width=0.466000 ;;
    c) width=0.403000 ;;
    d) width=0.451000 ;;
    e) width=0.446000 ;;
    f) width=0.296000 ;;
    g) width=0.421000 ;;
    h) width=0.439000 ;;
    i) width=0.163000 ;;
    j) width=0.159000 ;;
    k) width=0.500000 ;;
    l) width=0.154000 ;;
    m) width=0.712000 ;;
    n) width=0.439000 ;;
    o) width=0.516000 ;;
    p) width=0.464000 ;;
    q) width=0.443000 ;;
    r) width=0.397000 ;;
    s) width=0.345000 ;;
    t) width=0.332000 ;;
    u) width=0.437000 ;;
    v) width=0.434000 ;;
    w) width=0.719000 ;;
    x) width=0.500000 ;;
    y) width=0.438000 ;;
    z) width=0.405000 ;;
  esac
  # echo "file $objfile with width $width"

  if [[ $objfile =~ "space.obj" ]]; then
    cur_x=$(echo "$cur_x + ${width} + ${kern}" | bc -l)
  else
    if [[ ! -s ${FONT_OBJ_DIR}${objfile} ]]; then
      echo "Letter file ${FONT_OBJ_DIR}${objfile} does not exist!"
    else
      rm -f ./cur_vertex.txt
      # echo  "gawk \< ${FONT_OBJ_DIR}${objfile} -v cur_x=${cur_x} -v cur_vertex=${cur_vertex}"

      gawk < ${FONT_OBJ_DIR}${objfile} -v cur_x=${cur_x} -v cur_vertex=${cur_vertex} -v thetarot=-90 '
      @include "tectoplot_functions.awk"
      BEGIN {
        OFMT="%.12f"
        this_index=0
        thetarad=deg2rad(thetarot)
      }
      {
        if ($1=="v") {

          # letters have yval=0

          this_index++
          xval=$2
          yval=$4*sin(thetarad)
          zval=$4*cos(thetarad)

          # xoff=depth*sin(theta)*cos(phi)
          # yoff=depth*sin(theta)*sin(phi)
          # zoff=depth*cos(theta)

          # Offset the letter in space
          # $2=xval+cur_x


          # print $0
          # print "v", $2+cur_x, $4, $3

          print "v", xval+cur_x, yval, zval
        } else if ($1=="f") {
          split($2,f1,"/")
          split($3,f2,"/")
          split($4,f3,"/")

          if ($5!="") {
            split($5,f4,"/")
            printf("f %d/%d/%d %d/%d/%d %d/%d/%d %d/%d/%d\n", f1[1]+cur_vertex, f1[2]+cur_vertex, f1[3]+cur_vertex, f2[1]+cur_vertex, f2[2]+cur_vertex, f2[3]+cur_vertex, f3[1]+cur_vertex, f3[2]+cur_vertex, f3[3]+cur_vertex, f4[1]+cur_vertex, f4[2]+cur_vertex, f4[3]+cur_vertex)
          } else {
            printf("f %d/%d/%d %d/%d/%d %d/%d/%d\n", f1[1]+cur_vertex, f1[2]+cur_vertex, f1[3]+cur_vertex, f2[1]+cur_vertex, f2[2]+cur_vertex, f2[3]+cur_vertex, f3[1]+cur_vertex, f3[2]+cur_vertex, f3[3]+cur_vertex)
          }
        } else if ($1=="mtllib" || $1=="s" ) {
          # nothing
        } else if ($1=="o") {
          print "o", cur_x
        } else {
          print
        }
      }
      END {
        print cur_vertex+this_index > "./cur_vertex.txt"
      }' >> "${OUTPUT_FILE}"
    fi
    cur_vertex=$(head -n 1 ./cur_vertex.txt)
    cur_x=$(echo "$cur_x + ${width}+ ${kern}" | bc -l)

    # echo "After letter ${thisletter}, cur_vertex=${cur_vertex}"
  fi
done
