#!/bin/bash

# Initialize variables
verbose=false
recursive=false
decompress_count=0 # Global Var

# Decompress archive according to file type
function decompress_file() {
  local file="$1"
  local fileType

  # Get file compression type 
  fileType=$(file -b "$file" | awk '{print $1}')

  # Define an associative array mapping compression types to decompression commands
  declare -A decompress_commands=(
    ["gzip"]="gunzip"
    ["bzip2"]="bunzip2"
    ["Zip"]="unzip"
    ["compress'd"]="tar -xf"
    ["POSIX"]="tar -xf"    
  )

  # Get decompression command from associative array
  local command=${decompress_commands[$fileType]}

  # If the compression type is recognized, decompress the file
  if [[ -n $command ]]; then
    if $command "$file"; then
      ((decompress_count))
      if $verbose; then
        echo "Unpacking $file"
      fi
    fi    
  else
    if $verbose; then
        echo "Ignoring $file"
    fi
  fi  
}

# Get all files from directory and subdirectories recursively and decompress archives.
function recursive_decomp() {
    local dir=$1
    local option=$2

    if [[ $option -eq 1 ]]; then
        find $dir -type f -print0 | xargs -0 -n 1 decompress_file
    else
        ls $dir | xargs -n 1 decompress_file
    fi
}

# Parse command line flags
while getopts "rv:" opt; do
  case $opt in
    r)
      recursive=true
      ;;
    v)
      verbose=true
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# Decompress each file in the input list
for file in "$@"; do
    if [[ -d "$file" ]]; then
        if $recursive; then
            recursive_decomp $file 1
        else
            recursive_decomp $file 0
        fi
    elif [[ -f "$file" ]]; then
        decompress_file $file
    fi
done

# Print the number of archives decompressed and the number of files not decompressed
echo "Decompressed $decompressed archive(s)"
