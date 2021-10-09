
# Commands for plotting GIS datasets like points, lines, and grids
# To add: polygons

# Register the module with tectoplot
TECTOPLOT_MODULES+=("gis")

function tectoplot_defaults_gis() {

  #############################################################################
  ### GIS point options
  POINTSYMBOL="c"
  POINTCOLOR="black"
  POINTSIZE="0.02i"
  POINTLINECOLOR="black"
  POINTLINEWIDTH="0.5p"
  POINTCPT=$CPTDIR"defaultpt.cpt"

  #############################################################################
  ### GIS line options
  USERLINECOLOR=black           # GIS line data file, line color
  USERLINEWIDTH="0.5p"          # GIS line data file, line width

  #############################################################################
  ### Contoured grid options
  CONTOURNUMDEF=20             # Number of contours to plot
  GRIDCONTOURWIDTH=0.1p
  GRIDCONTOURCOLOUR="black"
  GRIDCONTOURSMOOTH=100
  GRIDCONTOURLABELS="on"

  current_userlinefilenumber=1
  current_userpointfilenumber=1
  current_usergridnumber=1
  current_smallcirclenumber=1

  usergridfilenumber=0
  userlinefilenumber=0
  userpointfilenumber=0
  userpolyfilenumber=0
  smallcnumber=0
  greatcnumber=0

  #############################################################################
  ### Small circle options

  SMALLCWIDTH_DEF="1p"
  SMALLCCOLOR_DEF="black"

}

#############################################################################
### Argument processing function defines the flag (-example) and parses arguments

function tectoplot_args_gis()  {
  # The following lines are required for all modules
  tectoplot_module_caught=0
  tectoplot_module_shift=0

  # The following case statement mimics the argument processing for tectoplot
  case "${1}" in

  -cn|--contour)
if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
-cn:           plot contours of a grid
-cn [gridfile] [[ { GMT GRID COMMANDS } ]]

  Contour a grid using GMT format options

Example:
   None yet
--------------------------------------------------------------------------------
EOF
fi
    shift
    if arg_is_flag $1; then
      info_msg "[-cn]: Grid file not specified"
    else
      CONTOURGRID=$(abs_path $1)
      shift
      ((tectoplot_module_shift++))
      if arg_is_flag $1; then
        info_msg "[-cn]: Contour interval not specified. Calculating automatically from Z range using $CONTOURNUMDEF contours"
        gridcontourcalcflag=1
      else
        CONTOURINTGRID="${1}"
        shift
        ((tectoplot_module_shift++))
      fi
    fi
    if [[ ${1:0:1} == [{] ]]; then
      info_msg "[-cn]: GMT argument string detected"
      shift
      ((tectoplot_module_shift++))
      while : ; do
          [[ ${1:0:1} != [}] ]] || break
          gridvars+=("${1}")
          shift
          ((tectoplot_module_shift++))
      done
      shift
      ((tectoplot_module_shift++))
      CONTOURGRIDVARS="${gridvars[@]}"
    fi
    info_msg "[-cn]: Custom GMT grid contour commands: ${CONTOURGRIDVARS[@]}"
    plots+=("gis_grid_contour")

    tectoplot_module_caught=1
    ;;

  -gr) #      [gridfile] [[cpt]] [[trans%]]
if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
-gr:           plot grid file
-gr [grid1] [[cpt1]] [[trans1]]

  Multiple instances of -gr can be specified and the plotting order versus other
  map layers will be respected.
  NaN cells are plotted as fully transparent (grdimage -Q)

Example:
  tectoplot -t -r BR -gr grid1.grd cpt1.cpt -a -gr grid2.grd cpt2.cpt 50
--------------------------------------------------------------------------------
EOF
fi
    shift
    usergridfilenumber=$(echo "$usergridfilenumber+1" | bc)
    if arg_is_flag $1; then
      info_msg "[-gr]: Grid file must be specified"
    else
      GRIDADDFILE[$usergridfilenumber]=$(abs_path $1)
      if [[ ! -e "${GRIDADDFILE[$usergridfilenumber]}" ]]; then
        info_msg "GRID file ${GRIDADDFILE[$usergridfilenumber]} does not exist"
      fi
      shift
      ((tectoplot_module_shift++))
    fi
    if arg_is_flag $1; then
      info_msg "[-gr]: GRID CPT file not specified. Using turbo."
      GRIDADDCPT[$usergridfilenumber]="turbo"
    else
      ISGMTCPT="$(is_gmt_cpt $1)"
      if [[ ${ISGMTCPT} -eq 1 ]]; then
        info_msg "[-gr]: Using GMT CPT file ${1}."
        GRIDADDCPT[$usergridfilenumber]="${1}"
      elif [[ -e ${1} ]]; then
        info_msg "[-gr]: Copying user defined CPT ${1}"
        TMPNAME=$(abs_path $1)

        cp $TMPNAME ${TMP}${F_CPTS}
        GRIDADDCPT[$usergridfilenumber]="${F_CPTS}"$(basename "$1")
      else
        info_msg "CPT file ${1} cannot be found directly. Looking in CPT dir: ${CPTDIR}${2}."
        if [[ -e ${CPTDIR}${1} ]]; then
          cp "${CPTDIR}${1}" ${TMP}${F_CPTS}
          info_msg "Copying CPT file ${CPTDIR}${1} to temporary holding space"
          GRIDADDCPT[$usergridfilenumber]="./${F_CPTS}${1}"
        else
          info_msg "Using default CPT (turbo)"
          GRIDADDCPT[$usergridfilenumber]="turbo"
        fi
      fi
      shift
      ((tectoplot_module_shift++))
    fi
    if arg_is_flag $1; then
      info_msg "[-gr]: GRID transparency not specified. Using 0 percent"
      GRIDADDTRANS[$usergridfilenumber]=0
    else
      GRIDADDTRANS[$usergridfilenumber]="${1}"
      shift
      ((tectoplot_module_shift++))
    fi
    GRIDIDCODE[$usergridfilenumber]="c"   # custom ID
    addcustomusergridsflag=1

    plots+=("gis_grid")
    # cpts+=("gis_grid")

    tectoplot_module_caught=1

    ;;

  -im) # args: file { arguments }
if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
-im:           plot a referenced RGB grid file (e.g. GeoTiff)
-im [filename] { GMT OPTIONS }

  gmt options (to psimage) might include { -t50 }

Example: None
--------------------------------------------------------------------------------
EOF
fi
    shift

    IMAGENAME=$(abs_path $1)
    shift
    ((tectoplot_module_shift++))

    # Args come in the form $ { -t50 -cX.cpt }
    if [[ ${1:0:1} == [{] ]]; then
      info_msg "[-im]: image argument string detected"
      shift
      ((tectoplot_module_shift++))

      while : ; do
          [[ ${1:0:1} != [}] ]] || break
          imageargs+=("${1}")
          shift
          ((tectoplot_module_shift++))

      done
      shift
      ((tectoplot_module_shift++))

      info_msg "[-im]: Found image args ${imageargs[@]}"
      IMAGEARGS="${imageargs[@]}"
    fi
    plotimageflag=1

    plots+=("gis_image")

    tectoplot_module_caught=1
    ;;

  -li) # args: file color width
if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
-li:           plot one or more polyline files
-li [filename] [[linecolor]] [[linewidth]]

  Can be called multiple times to plot multiple datasets.
  Currently does not handle complex symbologies (ornamented, CPT, etc.)

Example: Plot a few lines across Romania
  printf ">\n21 44\n26 48\n>\n22 46\n27 45\n" > ./xy.dat
  tectoplot -r RO -t -li xy.dat red 1p
  rm -f ./xy.dat
--------------------------------------------------------------------------------
EOF
fi
    shift
    # Required arguments
    userlinefilenumber=$(echo "$userlinefilenumber + 1" | bc -l)
    USERLINEDATAFILE[$userlinefilenumber]=$(abs_path $1)
    shift
    ((tectoplot_module_shift++))

    if [[ ! -e ${USERLINEDATAFILE[$userlinefilenumber]} ]]; then
      info_msg "[-li]: User line data file ${USERLINEDATAFILE[$userlinefilenumber]} does not exist."
      exit 1
    fi
    # Optional arguments
    # Look for symbol code
    if arg_is_flag $1; then
      info_msg "[-li]: No color specified. Using $USERLINECOLOR."
      USERLINECOLOR_arr[$userlinefilenumber]=$USERLINECOLOR
    else
      USERLINECOLOR_arr[$userlinefilenumber]="${1}"
      shift
      ((tectoplot_module_shift++))
      info_msg "[-li]: User line color specified. Using ${USERLINECOLOR_arr[$userlinefilenumber]}."
    fi

    # Then look for width
    if arg_is_flag $1; then
      info_msg "[-li]: No width specified. Using $USERLINEWIDTH."
      USERLINEWIDTH_arr[$userlinefilenumber]=$USERLINEWIDTH
    else
      USERLINEWIDTH_arr[$userlinefilenumber]="${1}"
      shift
      ((tectoplot_module_shift++))

      info_msg "[-li]: Line width specified. Using ${USERLINEWIDTH_arr[$userlinefilenumber]}."
    fi

    if [[ "${1}" == "fill" ]]; then
      info_msg "[-li]: Fillling polygon"
      USERLINEFILL_arr[$userlinefilenumber]="-Gred"
      shift
      ((tectoplot_module_shift++))

    else
      USERLINEFILL_arr[$userlinefilenumber]=""
    fi

    info_msg "[-li]: LINE${userlinefilenumber}: ${USERLINEDATAFILE[$userlinefilenumber]}"

    plots+=("gis_line")
    tectoplot_module_caught=1

  ;;

    -pt)
  if [[ $USAGEFLAG -eq 1 ]]; then
  cat <<-EOF
modules/module_gis.sh
-pt:           plot point dataset with specified size, fill, cpt
-pt [filename] [[symbol=${POINT_SYMBOL}]] [[size=${POINTSIZE}]] [[@ color]]
-pt [filename] [[symbol=${POINT_SYMBOL}]] [[size=${POINTSIZE}]] [[cpt_filename]]

  symbol is a GMT psxy -S code:
    +(plus), st(a)r, (b|B)ar, (c)ircle, (d)iamond, (e)llipse,
 	  (f)ront, octa(g)on, (h)exagon, (i)nvtriangle, (j)rotated rectangle,
 	  pe(n)tagon, (p)oint, (r)ectangle, (R)ounded rectangle, (s)quare,
    (t)riangle, (x)cross, (y)dash,

  Multiple calls to -pt can be made; they will plot in map layer order.

Example: None
--------------------------------------------------------------------------------
EOF

  fi
      shift

      # COUNTER userpointfilenumber
      # Required arguments
      userpointfilenumber=$(echo "$userpointfilenumber + 1" | bc -l)
      POINTDATAFILE[$userpointfilenumber]=$(abs_path $1)
      shift
      ((tectoplot_module_shift++))
      if [[ ! -e ${POINTDATAFILE[$userpointfilenumber]} ]]; then
        info_msg "[-pt]: Point data file ${POINTDATAFILE[$userpointfilenumber]} does not exist."
        exit 1
      fi
      # Optional arguments
      # Look for symbol code
      if arg_is_flag $1; then
        info_msg "[-pt]: No symbol specified. Using $POINTSYMBOL."
        POINTSYMBOL_arr[$userpointfilenumber]=$POINTSYMBOL
      else
        POINTSYMBOL_arr[$userpointfilenumber]="${1:0:1}"
        shift
        ((tectoplot_module_shift++))
        info_msg "[-pt]: Point symbol specified. Using ${POINTSYMBOL_arr[$userpointfilenumber]}."
      fi

      # Then look for size
      if arg_is_flag $1; then
        info_msg "[-pt]: No size specified. Using $POINTSIZE."
        POINTSIZE_arr[$userpointfilenumber]=$POINTSIZE
      else
        POINTSIZE_arr[$userpointfilenumber]="${1}"
        shift
        ((tectoplot_module_shift++))
        info_msg "[-pt]: Point size specified. Using ${POINTSIZE_arr[$userpointfilenumber]}."
      fi

      # Finally, look for CPT file
      if arg_is_flag $1; then
        info_msg "[-pt]: No cpt specified. Using ${POINTCOLOR} fill for -G"
        pointdatafillflag[$userpointfilenumber]=1
        pointdatacptflag[$userpointfilenumber]=0
      elif [[ ${1:0:1} == "@" ]]; then
        shift
        ((tectoplot_module_shift++))
        POINTCOLOR=${1}
        info_msg "[-pt]: No cpt specified using @. Using POINTCOLOR for -G"
        shift
        ((tectoplot_module_shift++))
        pointdatafillflag[$userpointfilenumber]=1
        pointdatacptflag[$userpointfilenumber]=0
      else
        POINTDATACPT[$userpointfilenumber]=$(abs_path $1)
        shift
        ((tectoplot_module_shift++))
        if [[ ! -e ${POINTDATACPT[$userpointfilenumber]} ]]; then
          info_msg "[-pt]: CPT file $POINTDATACPT does not exist. Using default $POINTCPT"
          POINTDATACPT[$userpointfilenumber]=$(abs_path $POINTCPT)
        else
          info_msg "[-pt]: Using CPT file $POINTDATACPT"
        fi
        pointdatacptflag[$userpointfilenumber]=1
        pointdatafillflag[$userpointfilenumber]=0
      fi

      info_msg "[-pt]: PT${userpointfilenumber}: ${POINTDATAFILE[$userpointfilenumber]}"
      plots+=("gis_point")

      tectoplot_module_caught=1
    ;;

    # Plot small circle with given angular radius, color, linewidth
    -smallc)
  if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
modules/module_gis.sh
-smallc:       plot small circle centered on a geographic point
-smallc [lon] [lat] [radius] [[argid arg]] ...

  argid:
  color     Color of small circle line
  pole      Activate plotting of pole location as point
  stroke    Pen width (e.g. 1p)
  dash      Activate dashed line styl

  Multiple calls to -smallc can be made; they will plot in map layer order.

Example: None
--------------------------------------------------------------------------------
EOF
  fi
      shift


      smallcnumber=$(echo "$smallcnumber + 1" | bc -l)

      if arg_is_float $1; then
        SMALLCLON[$smallcnumber]=$1
        shift
        ((tectoplot_module_shift++))
      fi

      if arg_is_float $1; then
        SMALLCLAT[$smallcnumber]=$1
        shift
        ((tectoplot_module_shift++))
      fi

      if arg_is_float $1; then
        SMALLCDEG[$smallcnumber]=$1
        shift
        ((tectoplot_module_shift++))
      elif ! arg_is_flag $1; then
        # If argument is not a pure number, assume it is a kilometer value
        SMALLCDEG[$smallcnumber]=$(echo "$1 ${SMALLCLAT[$smallcnumber]}" | gawk '{print cos($2*3.14159/180)*($1+0) / 111.325}')
        shift
        ((tectoplot_module_shift++))
      fi

      # if ! arg_is_flag $1; then
      #   SMALLCWIDTH[$smallcnumber]="${1}"
      #   shift
      #   ((tectoplot_module_shift++))
      # else
      #   SMALLCWIDTH[$smallcnumber]=${SMALLCWIDTH_DEF}
      # fi
      #
      #

      SMALLCPOLE[$smallcnumber]=0
      SMALLCDASH[$smallcnumber]=""

      while ! arg_is_flag $1; do
        case $1 in
          dash)
            SMALLCDASH[$smallcnumber]=",-"
            ;;
          pole)
            SMALLCPOLE[$smallcnumber]="1"
            ;;
          color)
            shift
            ((tectoplot_module_shift++))
            if ! arg_is_flag $1; then
              SMALLCCOLOR[$smallcnumber]="${1}"
            else
              SMALLCCOLOR[$smallcnumber]=${SMALLCCOLOR_DEF}
            fi
            ;;
          stroke)
            shift
            ((tectoplot_module_shift++))
            if ! arg_is_flag $1; then
              SMALLCWIDTH[$smallcnumber]="${1}"
            else
              SMALLCWIDTH[$smallcnumber]=${SMALLCWIDTH_DEF}
            fi
            ;;
        esac
        shift
        ((tectoplot_module_shift++))
      done

      info_msg "[-smallc]: Small circle defined: ${SMALLCLON[$smallcnumber]} ${SMALLCLAT[$smallcnumber]} ${SMALLCWIDTH[$smallcnumber]} ${SMALLCCOLOR[$smallcnumber]} ${SMALLCDASH[$smallcnumber]}"

      plots+=("gis_small_circle")
      tectoplot_module_caught=1
    ;;

    # Plot small circle with given angular radius, color, linewidth
    -greatc)
  if [[ $USAGEFLAG -eq 1 ]]; then
cat <<-EOF
modules/module_gis.sh
-greatc:       plot great circles passing through points with given azimuths
-greatc [[file]] [lon1] [lat1] [azimuth1] [[lon2]] [[lat2]] [[azimuth2]] ..

  If file is specified, read it in first. Format: lon lat azimuth

Example: None
--------------------------------------------------------------------------------
EOF
  fi
      shift

      # Check if there is an input file
      if [[ -s "${1}" ]]; then
        greatcfile="${1}"
        echo "input file"
        shift
        ((tectoplot_module_shift++))
        #
        while read p; do
          greatcnumber=$(echo "${greatcnumber} + 1" | bc -l)
          d=($(echo $p))
          GREATCLON[$greatcnumber]=${d[0]}
          GREATCLAT[$greatcnumber]=${d[1]}
          GREATCAZ[$greatcnumber]=${d[2]}
        done < $greatcfile
      else

        while ! arg_is_flag $1; do
          greatcnumber=$(echo "${greatcnumber} + 1" | bc -l)

          if arg_is_float $1; then
            GREATCLON[$greatcnumber]=$1
            shift
            ((tectoplot_module_shift++))
          fi

          if arg_is_float $1; then
            GREATCLAT[$greatcnumber]=$1
            shift
            ((tectoplot_module_shift++))
          fi

          if arg_is_float $1; then
            GREATCAZ[$greatcnumber]=$1
            shift
            ((tectoplot_module_shift++))
          fi

        done
      fi

      if [[ ${greatcnumber} -gt 0 ]]; then
        info_msg "[-greatc]: ${greatcnumber} great circles defined"
        plots+=("gis_great_circle")
      else
        echo "[-greatc]: No circles defined"
      fi

      tectoplot_module_caught=1
    ;;



  esac
}

# function tectoplot_calculate_gis()  {
# }

# function tectoplot_cpt_gis() {
# }

function tectoplot_plot_gis() {

  case $1 in

  gis_grid)
    # Each time gis_grid is called, plot the grid and increment to the next
    info_msg "Plotting user grid $current_usergridnumber: ${GRIDADDFILE[$current_usergridnumber]} with CPT ${GRIDADDCPT[$current_usergridnumber]}"
    gmt grdimage ${GRIDADDFILE[$current_usergridnumber]} -Q -I+d -C${GRIDADDCPT[$current_usergridnumber]} $GRID_PRINT_RES -t${GRIDADDTRANS[$current_usergridnumber]} $RJOK ${VERBOSE} >> map.ps
    current_usergridnumber=$(echo "$current_usergridnumber + 1" | bc -l)

    tectoplot_plot_caught=1
    ;;

  gis_grid_contour)
    # Exclude options that are contained in the ${CONTOURGRIDVARS[@]} array
    AFLAG=-A$CONTOURINTGRID
    CFLAG=-C$CONTOURINTGRID
    SFLAG=-S$GRIDCONTOURSMOOTH

    for i in ${CONTOURGRIDVARS[@]}; do
      if [[ ${i:0:2} =~ "-A" ]]; then
        AFLAG=""
      fi
      if [[ ${i:0:2} =~ "-C" ]]; then
        CFLAG=""
      fi
      if [[ ${i:0:2} =~ "-S" ]]; then
        SFLAG=""
      fi
    done

    gmt grdcontour $CONTOURGRID $AFLAG $CFLAG $SFLAG -W$GRIDCONTOURWIDTH,$GRIDCONTOURCOLOUR ${CONTOURGRIDVARS[@]} $RJOK ${VERBOSE} >> map.ps

    tectoplot_plot_caught=1
  ;;

  gis_point)
    info_msg "Plotting point dataset $current_userpointfilenumber: ${POINTDATAFILE[$current_userpointfilenumber]}"
    if [[ ${pointdatacptflag[$current_userpointfilenumber]} -eq 1 ]]; then
      gmt psxy ${POINTDATAFILE[$current_userpointfilenumber]} -W$POINTLINEWIDTH,$POINTLINECOLOR -C${POINTDATACPT[$current_userpointfilenumber]} -G+z -S${POINTSYMBOL_arr[$current_userpointfilenumber]}${POINTSIZE_arr[$current_userpointfilenumber]} $RJOK $VERBOSE >> map.ps
    else
      gmt psxy ${POINTDATAFILE[$current_userpointfilenumber]} -G$POINTCOLOR -W$POINTLINEWIDTH,$POINTLINECOLOR -S${POINTSYMBOL_arr[$current_userpointfilenumber]}${POINTSIZE_arr[$current_userpointfilenumber]} $RJOK $VERBOSE >> map.ps
    fi
    current_userpointfilenumber=$(echo "$current_userpointfilenumber + 1" | bc -l)
    tectoplot_plot_caught=1
  ;;

  gis_line)
    info_msg "Plotting line dataset $current_userlinefilenumber"
    echo       gmt psxy ${USERLINEDATAFILE[$current_userlinefilenumber]} ${USERLINEFILL_arr[$current_userlinefilenumber]} -W${USERLINEWIDTH_arr[$current_userlinefilenumber]},${USERLINECOLOR_arr[$current_userlinefilenumber]} $RJOK $VERBOSE \>\> map.ps

    gmt psxy ${USERLINEDATAFILE[$current_userlinefilenumber]} ${USERLINEFILL_arr[$current_userlinefilenumber]} -W${USERLINEWIDTH_arr[$current_userlinefilenumber]},${USERLINECOLOR_arr[$current_userlinefilenumber]} $RJOK $VERBOSE >> map.ps
    current_userlinefilenumber=$(echo "$current_userlinefilenumber + 1" | bc -l)
    tectoplot_plot_caught=1
  ;;

  gis_image)
    gmt grdimage ${IMAGENAME} -Q $RJOK $VERBOSE >> map.ps
    tectoplot_plot_caught=1
  ;;

  gis_great_circle)

    for this_gc in $(seq 1 $greatcnumber); do
      gmt project -C${GREATCLON[$this_gc]}/${GREATCLAT[$this_gc]} -A${GREATCAZ[$this_gc]} -G0.5 -L-360/0 > great_circle_${this_gc}.txt
      gmt psxy great_circle_${this_gc}.txt -W1p,black $RJOK $VERBOSE >> map.ps
    done
  ;;

  gis_small_circle)
    info_msg "Creating small circle ${current_smallcirclenumber}"

    # Somehow, lon=38 lat=32 FAILS but lon=38 lat=32.0001 doesn't (GMT 6.1.1) ?????
    polelat=${SMALLCLAT[$current_smallcirclenumber]}
    polelon=${SMALLCLON[$current_smallcirclenumber]}

    poleantilat=$(echo "0 - (${polelat}+0.0000001)" | bc -l)
    poleantilon=$(echo "${polelon}" | gawk  '{if ($1 < 0) { print $1+180 } else { print $1-180 } }')

    gmt_init_tmpdir

    echo gmt project -T${polelon}/${polelat} -C${poleantilon}/${poleantilat} -G0.5/${SMALLCDEG[$current_smallcirclenumber]} -L-360/0 $VERBOSE \| gawk '{print $1, $2}' \> ${F_MAPELEMENTS}smallcircle_${current_smallcirclenumber}.txt

gmt project -T${polelon}/${polelat} -C${poleantilon}/${poleantilat} -G0.5/${SMALLCDEG[$current_smallcirclenumber]} -L-360/0 $VERBOSE | gawk '{print $1, $2}' > ${F_MAPELEMENTS}smallcircle_${current_smallcirclenumber}.txt
    gmt_remove_tmpdir

    gmt psxy ${F_MAPELEMENTS}smallcircle_${current_smallcirclenumber}.txt -W${SMALLCWIDTH[$current_smallcirclenumber]},${SMALLCCOLOR[$current_smallcirclenumber]}${SMALLCDASH[$current_smallcirclenumber]} $RJOK $VERBOSE >> map.ps

    if [[ ${SMALLCPOLE[$current_smallcirclenumber]} -eq 1 ]]; then
      echo "$polelon $polelat" | gmt psxy -Sc0.1i -G${SMALLCCOLOR[$current_smallcirclenumber]} $RJOK $VERBOSE >> map.ps
    fi

    current_smallcirclenumber=$(echo "$current_smallcirclenumber + 1" | bc -l)
    tectoplot_plot_caught=1
  ;;
  esac

}

# function tectoplot_legend_gis() {
# }

function tectoplot_legendbar_gis() {
  case $1 in
    gis_grid)
      echo "G 0.2i" >> legendbars.txt
      echo "B ${GRIDADDCPT[$current_usergridnumber]} 0.2i 0.1i+malu -Bxaf+l\"$(basename ${GRIDADDFILE[$current_usergridnumber]})\"" >> legendbars.txt
      barplotcount=$barplotcount+1
      current_usergridnumber=$(echo "$current_usergridnumber + 1" | bc -l)
      tectoplot_caught_legendbar=1
      ;;
  esac
}

# function tectoplot_post_gis() {
# }
