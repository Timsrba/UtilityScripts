#!/bin/bash
# Script: copy_kotlin_project.sh
# Description: Recursively outputs a Kotlin project's directory structure and file contents
#              in Markdown format, then copies the output to the clipboard using xclip.
#
# Usage:
#   ./copy_kotlin_project.sh <project_directory>
#
# Requirements:
#   - xclip (install via your package manager on Arch Linux)
#
# Notes:
#   - Hidden files and directories (those starting with a dot) are excluded.
#   - Files with the ".kt" extension are rendered with a "kotlin" code fence; all others use "text".
#   - Files with binary extensions (e.g., png, jpeg, etc.) are ignored.

# List of file extensions to ignore (binary files)
IGNORED_EXTENSIONS=("png" "jpeg" "jpg" "gif" "bmp" "ico" "pdf" "zip" "tar" "gz" "rar" "exe" "bin" "webp" "xml")

# Ensure exactly one argument is provided.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <project_directory>"
  exit 1
fi

PROJECT_DIR="$1"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: '$PROJECT_DIR' is not a valid directory."
  exit 1
fi

# Function: process_directory
# Recursively processes the given directory (using a relative path for proper Markdown headings).
process_directory() {
  local base="$1"     # The absolute path of the project root
  local rel_dir="$2"  # The relative directory path from the project root
  local full_dir

  if [ -n "$rel_dir" ]; then
    full_dir="$base/$rel_dir"
  else
    full_dir="$base"
  fi

  # Output a header for the current directory.
  if [ -z "$rel_dir" ]; then
    echo "# Project: $(basename "$base")"
  else
    echo "## Directory: $rel_dir"
  fi

  # Loop through non-hidden entries in the directory.
  for entry in "$full_dir"/*; do
    [ -e "$entry" ] || continue  # Skip if no entries found.
    local name
    name=$(basename "$entry")
    
    if [ -d "$entry" ]; then
      # Construct the relative path for the subdirectory.
      local new_rel
      if [ -z "$rel_dir" ]; then
        new_rel="$name"
      else
        new_rel="$rel_dir/$name"
      fi
      process_directory "$base" "$new_rel"
    elif [ -f "$entry" ]; then
      # Extract the file extension in lowercase.
      local ext="${name##*.}"
      ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
      
      # Check if the file extension is in the ignored list.
      for ignored in "${IGNORED_EXTENSIONS[@]}"; do
        if [ "$ext" == "$ignored" ]; then
          continue 2
        fi
      done
      
      # Construct the relative file path.
      local file_rel
      if [ -z "$rel_dir" ]; then
        file_rel="$name"
      else
        file_rel="$rel_dir/$name"
      fi
      echo "### File: $file_rel"
      
      # Choose the appropriate code block language based on file extension.
      if [ "$ext" == "kt" ]; then
        echo '```kotlin'
      else
        echo '```text'
      fi
      
      # Output the file's content.
      cat "$entry"
      echo '```'
      echo ""
    fi
  done
}

# Process the project directory and pipe the result directly to xclip.
process_directory "$PROJECT_DIR" "" | xclip -selection clipboard

echo "Project structure and content (excluding binary files) copied to clipboard."

