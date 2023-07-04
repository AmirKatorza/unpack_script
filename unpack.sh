#!/bin/bash

# Initialize variables
verbose=false
recursive=false
decompress_count=0 # Global Var

# Function to decompress a file
function decompress_file() {
  local file="$1"
  local fileType

  # Get the compression type of the file
  fileType=$(file -b "$file" | awk '{print $1}')

  # Define an associative array mapping compression types to decompression commands
  declare -A decompress_commands=(
    ["gzip"]="gunzip"
    ["bzip2"]="bunzip2"
    ["Zip"]="unzip"
    ["compress'd"]="tar -xf"
    ["POSIX"]="tar -xf"    
  )

  # Get the decompression command for the compression type
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

# Function to traverse a directory recursively and decompress all archives in it
function traverse_directory() {
  local dir="$1"

  while IFS= read -r -d '' file; do
    decompress_file "$file"
  done << (find "$dir" -type f -print0)
}

# Parse command line arguments
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
    if $recursive; then
      traverse_directory "$file"
    fi
  elif [[ -f "$file" ]]; then
    decompress_file "$file"
  fi
done

# Print the number of archives decompressed and the number of files not decompressed
echo "Decompressed $decompressed archive(s)"
