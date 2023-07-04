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
  # You can add more compressed file type here!!!
  declare -A decompress_commands=(
    ["gzip"]="gunzip"
    ["bzip2"]="bunzip2"
    ["Zip"]="unzip"    
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

# Get all files from directory and optionally subdirectories recursively and decompress archives.
function decompress_dir() {
  local dir=$1
  local recursive=$2

  if [[ $recursive -eq 1 ]]; then
    If recursive option is set, find all files in directory and subdirectories
    while IFS= read -r -d '' file; do
        decompress_file "$file"
    done < <(find "$dir" -type f -print0)
    # This is bad practice for this scenario - kept it anyway for future refrence!
    # find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
    #   decompress_file "$file"
    # done    
  else
    # If recursive option is not set, only process files in the given directory
    for file in "$dir"/*; do
      if [[ -f "$file" ]]; then
        decompress_file "$file"
      fi
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
