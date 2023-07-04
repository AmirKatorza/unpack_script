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
    ["compress'd"]="uncompress"
    ["POSIX"]="tar -xvf"    
  )

  # Get decompression command from associative array
  local command=${decompress_commands[$fileType]}

  # If the compression type is recognized, decompress the file
  if [[ -n $command ]]; then
    if $command -f "$file"; then  # Added the -f option to force overwrite
      ((decompress_count++))      
      if "$verbose"; then
        echo "Unpacking $file"
      fi
    fi
  else
    if "$verbose"; then
      echo "Ignoring $file"
    fi
  fi
}

# Get all files from directory and subdirectories recursively and decompress archives.
function decompress_dir() {
  local dir=$1
  local option=$2

  if [[ $option -eq 1 ]]; then
    while IFS= read -r -d '' file; do
        decompress_file "$file"
    done < <(find "$dir" -type f -print0)
    # find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
    #   decompress_file "$file"
    # done     
  else
    for file in "$dir"/*; do
        if [[ -f "$file" ]]; then
            decompress_file "$file"
        fi
    done
    # ls "$dir" | while IFS='' read -r file; do
    #   decompress_file "$dir/$file"
    done
  fi
}

# Parse command line flags
while getopts "rv" opt; do
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
    if "$recursive"; then
      decompress_dir "$file" 1
    else
      decompress_dir "$file" 0
    fi
  elif [[ -f "$file" ]]; then
    decompress_file "$file"
  fi
done

# Print the number of archives decompressed
echo "Decompressed $decompress_count archive(s)"
