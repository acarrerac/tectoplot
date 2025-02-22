# This file must be sourced by

# Arguments:
# 1. KML file
# 2. Font name
# 3. Font color
# 4. Font max size
# 5. Font min size
# 6. Outline command (or nil)
#

if [[ ${#@} -ne 6 ]]; then
  echo "labels_helper.sh: Requires 6 arguments"
  exit 1
fi

#TEXT_KMLFILE=/Users/kylebradley/Dropbox/scripts/tectoplot/labels/TextLabels.kml
TEXT_KMLFILE=/Users/kylebradley/Dropbox/SoutheastAsiaLabels.kml
TEXT_OUTLINE_PEN="=0.2p,white"
#TEXT_OUTLINE_PEN=""
FONT="Helvetica-Bold"
FONT_COLOR="black"
TEXT_FONT=${FONT},${FONT_COLOR}${TEXT_OUTLINE_PEN}
PLOTLINE="+i"  # +i option suppresses line plotting
#PLOTLINE=""
MAX_FONTSIZE=12

echo "in args are ${@}; total of ${#@}"

# Convert KML paths to GMT OGR format
ogr2ogr -f "OGR_GMT" TextLabels.gmt $TEXT_KMLFILE

# Parse the KML file to extract the paths and labels
gawk < TextLabels.gmt '
  ($1==">") {
    # skip lines starting with a >
  }
  # Extract the @D values which are the quoted labels followed by a |
  (substr($0,0,4) == "# @D") {
      out=substr($0,5,length($0)-5)
      print "> -L" out
  }
  # Print the longitude and latitude values with an increment used for splining
  ($1+0==$1) {
    # print $1, $2, incr++
    print
  }' > data_pre.txt

# Clip the input lines to the AOI
gmt spatial data_pre.txt -Fl -T -R | gawk '
{
  if ($1+0==$1) {
    print $1, $2, incr++
  } else {
    print
  }
}'> data_clipped.txt

# Should I separate the paths with only two points to ensure they are not smoothed?

# Resample the paths using the 'time' increment to smooth them out
gmt sample1d data_clipped.txt -Fc -T2 -I0.1 > data_resampled.txt

# Calculate the lengths of the paths in map coordinates (centimeters)
gmt mapproject data_clipped.txt -i0,1 -G+uC+a -R -J  > data_proj_dist.txt

# Calculate the lengths of the labels for fontsize 1
/Users/kylebradley/Dropbox/scripts/tectoplot/bashscripts/stringlength.sh ${FONT} 1 data_proj_dist.txt > data_proj_dist_labelcalc.txt

#gmt mapproject data_pre.txt -i0,1 -G+ud+a > data_dist.txt

# We can adjust the font size, which makes letters taller and wider, and we
# can add spaces between letters, which makes the label wider only.

# Input files are the data_proj_dist.txt containing GMT and calculated widths
# and the resampled data file containing the same labels in the same order

gawk -v maxfontsize=${MAX_FONTSIZE} '
  function max(a,b) { return (a>b)?a:b }
  function min(a,b) { return (a<b)?a:b }
  function rd(n, multipleOf)
  {
    if (n % multipleOf == 0) {
      num = n
    } else {
       if (n > 0) {
          num = n - n % multipleOf;
       } else {
          num = n + (-multipleOf - n % multipleOf);
       }
    }
    return num
  }
  BEGIN {
    changesize=1
    maxspacing=4
    minfontsize=1
  }
  (NR==FNR) {
   if ($1+0==$1) {
      current_dist=$3
   }

   # When we hit a header, we immediately read the calculated cm distance
   # and then assign the GMT path length for the previous label header
   if (substr($0,0,1)==">") {
      # Assign and increment curnum (dist[0] will be 0)
      dist[curnum++]=current_dist
      # The calculated cm distance is the last field of the header
      calcdist[curnum]=$(NF)
   }
  }
  (NR != FNR) {
    if (doneend==0) {
      dist[curnum]=current_dist
      doneend=1
      curout=1
    }
    # Process a label
    if (substr($0,0,1) == ">") {
      thisdistance=dist[curout]
      thiscalcdist=calcdist[curout++]
      thislabel=substr($0,5,length($0)-1)
      textlength=length($0)-6

      print "For label:", thislabel, "GMT dist is", thisdistance, "and width at fontsize=1 is", thiscalcdist, "and at max font size", maxfontsize, "is", maxfontsize*thiscalcdist > "/dev/stderr"

      # fontsize_t is the font size that should fill the line almost completely
      fontsize_t = thisdistance/thiscalcdist*0.9

      # lenbiggest is the length of the label at the maximum font size
      lenatbiggest=thiscalcdist*maxfontsize
      # print "lenatbiggest is", lenatbiggest > "/dev/stderr"

      if (substr(thislabel, 1, 1) != "\"") {
        thislabel=sprintf("\"%s\"", thislabel)
      }
      reducefont=0
      spacing=0
      if (changesize==1 && fontsize_t > maxfontsize) {
        print "a" > "/dev/stderr"
        fontsize_t = maxfontsize
        origlength=length(thislabel)

        while (spacing < maxspacing) {
            j=1
            textlength=0
            newlabel=""
            spacing++
            for (i=1;i<=length(thislabel);i++) {
              # Do not add spaces before or after a quotation mark or a space
              if (substr(thislabel, i, 1) == "\"" || substr(thislabel, i+1, 1) == "\"") {
                newlabel=sprintf("%s%s", newlabel, substr(thislabel, i, 1))
                textlength++
              } else {
                # Add n spaces after each character where n=spacing
                newlabel=sprintf("%s%s", newlabel, substr(thislabel, i, 1))
                textlength+=1
                for (k=1;k<=spacing;k++) {
                  newlabel=sprintf("%s ", newlabel)
                  textlength+=1
                }
              }
            }
            #           (number_spaces*0.01+thiscalcdist)*fontsize
            newcalcdist=((textlength-origlength)*0.01+thiscalcdist)*fontsize_t

            if (newcalcdist < thisdistance) {
              print "Estimated length with spacing=" spacing, "is", newcalcdist > "/dev/stderr"
              thislabel=newlabel
            } else {
              print "No adjust as", newcalcdist, ">=", thisdistance > "/dev/stderr"
              break
            }
        }
        if (fontsize_t < minfontsize) {
          print "Label", thislabel, "has font size too small:", fontsize_t > "/dev/stderr"
        }
      } # changesize==1
      if (fontsize_t > 1 && fontsize_t < minfontsize) {
        filename=sprintf("text_%0.1f_file.gmt", 1)
      } else {
        filename=sprintf("text_%0.1f_file.gmt", rd(fontsize_t, 0.5))
      }
      print "> -L" thislabel >> filename
    } else {
      if ($1 > 180) { $1=$1-360 }
      print $1, $2 >> filename
    }
  }
  ' data_proj_dist_labelcalc.txt data_resampled.txt > data.txt

# Plot the text along the smoothed curves
#gmt psxy data.txt -Sqn1:+v+Lh+i $RJOK >> map.ps

for textfile in text*.gmt; do
  fontsize=$(basename $textfile | gawk -F_ '{print $2}')
  if [[ $(echo "$fontsize > 0.5" | bc) -eq 1 ]]; then
    #echo gmt psxy $textfile -Sqn1:+Lh+f${fontsize}p,$TEXT_FONT${PLOTLINE}+v $RJOK
    gmt psxy $textfile -N -Sqn1:+Lh+f${fontsize}p,$TEXT_FONT${PLOTLINE}+v $RJOK >> map.ps
  fi
done
