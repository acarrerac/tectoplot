# Source this script

# tectoplot
# bashscripts/args_cleanup.sh
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

## Argument processing, data management, and cleanup routines

################################################################################
# Messaging and debugging routines


# Returns true if argument is empty or starts with a hyphen but is not a float;
# else returns false. Not sure this is the best way to code this test... bash...
# if arg_is_flag "${1}"; then ... ; fi
function arg_is_flag() {
  if ! arg_is_float "${1}"; then
    [[ ${1:0:1} == [-] || -z ${1} ]] && return
  else
    [[ 1 -eq 0 ]] && return
  fi
}

# Returns the opposite of arg_is_flag
function arg_is_string() {
   if arg_is_flag $1; then
    [[ 1 -eq 0 ]] && return
  else
    [[ 1 -eq 1 ]] && return
  fi
}

# Returns true if argument is a (optionally signed, optionally decimal) number
function arg_is_float() {
  [[ "${1}" =~ ^[+-]?([0-9]+\.?|[0-9]*\.[0-9]+)$ ]]
}

# Returns true if argument is a (optionally signed, optionally decimal) positive number
function arg_is_positive_float() {
  [[ "${1}" =~ ^[+]?([0-9]+\.?|[0-9]*\.[0-9]+)$ ]]
}

# Returns true if argument is a (optionally decimal) negative number
function arg_is_negative_float() {
  [[ "${1}" =~ ^[-]([0-9]+\.?|[0-9]*\.[0-9]+)$ ]]
}

# Returns true if argument is a (optionally signed) integer
function arg_is_integer() {
  [[ "${1}" =~ ^[+-]?([0-9]+)$ ]]
}

# Returns true if argument is a (optionally signed, optionally decimal) positive number
function arg_is_positive_integer() {
  [[ "${1}" =~ ^[+]?([0-9]+)$ ]]
}

# Returns true if argument is a negative integer
function arg_is_negative_integer() {
  [[ "${1}" =~ ^[-]([0-9]+)$ ]]
}


# Returns true if argument is a file that contains data
function arg_is_file() {
  if [[ -s $1 ]]; then
    return 1
  fi
  return 0
}

# Report the number of arguments remaining before the next flag argument
# Assumes the first argument in ${@} is current flag (eg -xyz) and ignores it
# num_left=$(number_nonflag_args "${@}")
function number_nonflag_args() {
  THESE_ARGS=("${@}")
  for index_a in $(seq 2 ${#THESE_ARGS[@]}); do
    if arg_is_flag "${THESE_ARGS[$index_a]}"; then
      break
    fi
  done
  echo $(( index_a - 1 ))
}

function error_msg() {
  printf "%s[%s]: %s\n" "${BASH_SOURCE[1]##*/}" ${BASH_LINENO[0]} "${@}" > /dev/stderr
  exit 1
}

function info_msg() {
  if [[ $narrateflag -eq 1 ]]; then
    printf "TECTOPLOT %05s: " ${BASH_LINENO[0]}
    printf "%s\n" "${@}"
  fi
  printf "TECTOPLOT %05s: " ${BASH_LINENO[0]} >> "${INFO_MSG}"
  printf "%s\n" "${@}" >> "${INFO_MSG}"
}


# Exit cleanup code from Mitch Frazier
# https://www.linuxjournal.com/content/use-bash-trap-statement-cleanup-temporary-files

function cleanup_on_exit()
{
      for i in "${on_exit_items[@]}"; do
        if [[ $CLEANUP_FILES -eq 1 ]]; then
          info_msg "rm -f $i"
          rm -f "${i}"
        else
          info_msg "Not cleaning up file $i"
        fi
      done
}

function move_on_exit()
{
      for i in "${on_exit_move_items[@]}"; do
        if [[ -d ${OUTPUTDIRECTORY} ]]; then
          info_msg "mv $i ${OUTPUTDIRECTORY}"
          mv $i ${OUTPUTDIRECTORY}
        else
          info_msg "Not moving file $i"
        fi
      done
}
# Be sure to only cleanup files that are in the temporary directory
function cleanup()
{
    local n=${#on_exit_items[*]}
    on_exit_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        info_msg "Setting EXIT trap function cleanup_on_exit()"
        trap cleanup_on_exit EXIT
    fi
}

# Be sure to only cleanup files that are in the temporary directory
function move_exit()
{
    local n=${#on_exit_move_items[*]}
    on_exit_move_items[$n]="$*"
    if [[ $n -eq 0 ]]; then
        info_msg "Setting EXIT trap function move_on_exit()"
        trap move_on_exit EXIT
    fi
}

function is_gmt_cpt () {
  gawk < "${GMTCPTS}" -v id="${1}" 'BEGIN{res=0} ($1==id) {res=1; exit} END {print res}'
}

# Return the full path to a file or directory
function abs_path() {

    # If it's an existing directory, return the full path with / at the end
    if [ -d "${1}" ]; then
        (cd "${1}"; echo "$(pwd)/")
    # If it's an existing file, return the full path with / at the end
    elif [ -f "${1}" ]; then
        if [[ $1 = /* ]]; then
            echo "${1}"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    # Special case to parse to the temporary data directory
    elif [[ $1 =~ TEMP/* ]]; then
      echo "${TMP}"/"${1##*/}"
    else
      echo $1
    fi
}


# Return the full path to the directory containing a file, or the directory itself
function abs_dir() {
    if [ -d "${1}" ]; then
        (cd "${1}"; echo "$(pwd)/")
    elif [ -f "${1}" ]; then
        if [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/"
        else
            echo "$(pwd)/"
        fi
    # Assume it's a directory that does not yet exist
    else
      if [[ $1 == */ ]]; then
        echo "${1}"
      else
        echo "${1}"/
      fi
    fi
}

# tectoplot_get_opts uses a simple control file to set variables from the
# command line arguments, including required and optional variables.

# The variables are stored in associative arrays keyed by the number of times
# the given option is called: OPT_VAR[1] vs OPT_VAR[2] etc. This allows the
# plotting section to handle multiple calls to the same command.

# Optional variables are initialized using default values

# Arguments: [function_name]
# Expects a file with the same name as [function_name] in the local directory

function tectoplot_get_opts() {

  if [[ ${#@} -lt 1 ]]; then
    echo "tectoplot_get_opts: no function name provided"
    exit 1
  else
    call=$1
    shift
  fi

  # Read in the control file and look for required arguments, then options

  unset tectoplot_options_count
  unset tectoplot_opts_argument
  unset tectoplot_opts_variable
  unset tectoplot_opts_type
  unset tectoplot_opts_default


  # Get the name of the correct variable; reference using ${!}
  tectoplot_opts_exp=${call}_opt_count
  eval "((${call}_opt_count++))"

  variable_list="${variable_list} ${call}_opt_count"

  # Read in required parameters while loading optional parameter list
  while IFS= read -r p <&3 || [ -n "$p" ] ; do
    d=($(echo $p))
    case ${d[0]} in
      req)
        case ${d[2]} in
          file)
            if ! arg_is_flag $1; then
              eval "${d[1]}[${!tectoplot_opts_exp}]=$(abs_path ${1})"
              variable_list=$(echo "${variable_list} ${d[1]}[${!tectoplot_opts_exp}]")
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: file option requires argument"
              exit 1
            fi
          ;;
          float)
            if arg_is_float ${1}; then
              eval "${d[1]}[${!tectoplot_opts_exp}]=${1}"
              variable_list=$(echo "${variable_list} ${d[1]}[${!tectoplot_opts_exp}]")
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required float argument not found; found $1 instead."
              exit 1
            fi
          ;;
          positive_float)
            if arg_is_positive_float ${1}; then
              eval "${d[1]}[${!tectoplot_opts_exp}]=${1}"
              variable_list=$(echo "${variable_list} ${d[1]}[${!tectoplot_opts_exp}]")
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required positive float argument not found; found $1 instead."
              exit 1
            fi
          ;;
          string)
            if arg_is_string ${1}; then
              eval "${d[1]}[${!tectoplot_opts_exp}]=${1}"
              variable_list=$(echo "${variable_list} ${d[1]}[${!tectoplot_opts_exp}]")
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required string argument not found; found $1 instead."
              exit 1
            fi
          ;;
        esac
      ;;
      opt)
        ((tectoplot_options_count++))
        tectoplot_opts_argument[${tectoplot_options_count}]=${d[1]}
        tectoplot_opts_variable[${tectoplot_options_count}]=${d[2]}
        tectoplot_opts_type[${tectoplot_options_count}]=${d[3]}
        tectoplot_opts_default[${tectoplot_options_count}]=${d[4]}
        # Set the default value for the option variable
        eval "${d[2]}[${!tectoplot_opts_exp}]=${d[4]}"
        # Add to the list of created variables
        variable_list=$(echo "${variable_list} ${d[2]}[${!tectoplot_opts_exp}]")
      ;;
      nam|des)
        # Ignore these for this part of processing
      ;;
      *)
        info_msg "[-$call]: Ignoring unrecognized control line: $p"
      ;;
    esac
  done 3< $call

  # Read in optional parameters
  while ! arg_is_flag $1; do
    opts_found=0
    for opt_i in $(seq 1 $tectoplot_options_count); do
      if [[ ${tectoplot_opts_argument[$opt_i]} == $1 ]]; then
        shift
        ((tectoplot_module_shift++))
        case ${tectoplot_opts_type[$opt_i]} in
          # list is a list of any kinds of words contained within { } brackets
          list)
            unset argument_list
            if [[ $1 != "{" ]]; then
              echo "[tectoplot_get_opts]: list variable expected list starting with {"
              exit 1
            fi
            shift
            ((tectoplot_module_shift++))
            while [[ $1 != "}" && ! -z $1 ]]; do
              if [[ -z ${argument_list} ]]; then
                argument_list=${1}
              else
                argument_list="${argument_list} $1"
              fi
              shift
              ((tectoplot_module_shift++))
            done
            if [[ $1 != "}" ]]; then
              echo "[tectoplot_get_opts]: list variable expected list ending with }"
              exit 1
            else
              shift
              ((tectoplot_module_shift++))
            fi
            eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=\"${argument_list}\""
          ;;
          # cpt is a filename or name of a builtin (tectoplot or GMT) CPT
          cpt)
            get_cpt_path $1
            eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${CPT_PATH}"
            shift
            ((tectoplot_module_shift++))
          ;;
          # file is an existing, non-empty file
          file)
            if [[ -s ${1} ]]; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=$(abs_path ${1})"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: file $1 does not exist or is empty"
              exit 1
            fi
          ;;
          # flag is 0 (off) or 1 (on); invoking argument switches flag on/off
          flag)
            if [[ $1 == "off" ]]; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=0"
              shift
              ((tectoplot_module_shift++))
            elif [[ $1 == "on" ]]; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=1"
              shift
              ((tectoplot_module_shift++))
            else
              # Get the name of the variable
              str="${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]"
              # Check its value using ${!}
              case ${!str} in
                0) eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=1";;
                1) eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=0";;
              esac
            fi
          ;;
          # float is any floating point number in decimal form
          float)
            if arg_is_float ${1}; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${1}"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required float argument not found; found $1 instead."
              exit 1
            fi
          ;;
          # floatlist is a list of floats
          floatlist)
            unset temp_floatlist
            while arg_is_float ${1}; do
              if [[ $temp_floatlist == "" ]]; then
                temp_floatlist=$1
              else
                temp_floatlist="$temp_floatlist $1"
              fi
              shift
              ((tectoplot_module_shift++))
            done
            eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=\"${temp_floatlist}\""
          ;;
          # int is any integer
          int)
            if arg_is_integer ${1}; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${1}"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required integer argument not found; found $1 instead."
              exit 1
            fi
          ;;
          # posint is any positive integer
          posint)
            if arg_is_positive_integer ${1}; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${1}"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required positive integer argument not found; found $1 instead."
              exit 1
            fi
          ;;
          # posfloat is any positife float
          posfloat)
            if arg_is_positive_float ${1}; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${1}"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required positive float argument not found; found $1 instead."
              exit 1
            fi
          ;;
          # string is anything that is not an arg_is_flag flag (-c, -t, etc)
          string)
            if arg_is_string ${1}; then
              eval "${tectoplot_opts_variable[$opt_i]}[${!tectoplot_opts_exp}]=${1}"
              shift
              ((tectoplot_module_shift++))
            else
              echo "[-$call]: required string argument not found; found $1 instead."
              exit 1
            fi
          ;;
        esac
        opts_found=1
      fi
    done
    if [[ $opts_found -eq 0 ]]; then
      echo "[-$call]: Optional argument $1 not recognized"
      exit 1
    fi
    # shift
    # ((tectoplot_module_shift++))
  done

  info_msg "[tectoplot_get_opts -$call]: set variables: ${variable_list}"
}

function resolve() {
  local mystr=$1
  echo ${!mystr}
}

# Print out a usage message based on the contents of an opts file

function tectoplot_usage_opts() {
  if [[ ${#@} -lt 1 ]]; then
    echo "tectoplot_usage_opts: no file or function name provided"
    exit 1
  else
    call=$1
    shift
  fi

  # First, print the name of the command and its description
  gawk < $call '
    ($1=="des") {
      nam=$2
      printf("%-15s", nam)
      printf("%s\n", substr($0, length($1)+length($2)+3))
      printf("%s ", nam)
    }
    ($1=="req") {
      printf("[%s] ", $3)
    }
    ($1=="opt") {
      optflag=1
    }
    END {
      if (optflag==1) {
        print "[[options ...]]"
      }
    }'

  # Print the required arguments
  gawk < $call -v uflag=${USAGEVARSFLAG} '
    BEGIN {
      doneopts=0
    }
    ($1=="req") {
      if (doneopts==0) {
        printf("\n\n")
        print "Required arguments:"
      }
      a=sprintf("%s", $3)
      printf "%-25s", a
      c=$2
      getline
      printf("%s", $0)
      if (uflag==1) {
        printf("\t%s", c)
      }
      doneopts=1
    }
    END {
      if(doneopts==1) {
        printf("\n")
      }
    }'

  # Print the optional arguments
  gawk < $call -v uflag=${USAGEVARSFLAG} '
    BEGIN {
      doneopts=0
    }
    ($1=="opt") {
      if (doneopts==0) {
        print ""
        print "Optional arguments:"
      }
      if ($4!="flag") {
        if (substr($4,length($4)-3,4)=="list") {
          pvar=" [val ...]"
        } else {
          pvar=" [val]"
        }
      } else {
        pvar=" [[val]]"
        flagmessage=1
      }
      a=sprintf("%s%s", $2, pvar)
      if ($4=="flag" && $5=="0") {
        b=sprintf("[%s=%s] ", $4, "off")
      } else {
        b=sprintf("[%s=%s] ", $4, $5)
      }
      c=$3
      printf "%-25s", a
      getline
      printf("%s %s", $0, b)
      if (uflag==1) {
        printf("\t%s", c)
      }
      printf("\n")

      doneopts=1
    }
    END {
      if (flagmessage==1) {
        print "\nFor flag options, [[val]] can be off or on; no argument means flip default value "
      }
    }'

    # Print any messages
    gawk < $call '
    BEGIN {
      printedmes=0
    }
    ($1=="mes") {
      str=substr($0,4,length($0)-3)
      if (printedmes==0) { printf("\n"); printedmes=1 }
      print str
    }'

    # Print examples
    gawk < $call '
    BEGIN {
      printedexa=0
    }
    ($1=="exa") {
      $1=""
      if (printedexa==0) { printf("\nExample: "); printedexa=1 }
      printf("%s\n", $0)
    }
    END {
      printf("--------------------------------------------------------------------------------\n")
    }' | gawk '{$1=$1;print}'
}
