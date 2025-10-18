#!/bin/bash

# Script: collect_code.sh
# Purpose: Collect all code files from a project into a single text file
# Usage: ./collect_code.sh [source_directory] [output_file]

# Default values
SOURCE_DIR="${1:-.}"  # Default to current directory if not specified
OUTPUT_FILE="${2:-collected_code.txt}"  # Default output filename

# File extensions to include (modify as needed)
EXTENSIONS=(
    "py"
    "js"
    "jsx"
    "ts"
    "tsx"
    "java"
    "c"
    "cpp"
    "h"
    "hpp"
    "cs"
    "php"
    "rb"
    "go"
    "rs"
    "swift"
    "kt"
    "scala"
    "r"
    "R"
    "m"
    "sql"
    "html"
    "css"
    "scss"
    "sass"
    "xml"
    "json"
    "yaml"
    "yml"
    "toml"
    "ini"
    "conf"
    "config"
    "sh"
    "bash"
    "zsh"
    "fish"
    "ps1"
    "bat"
    "cmd"
    "md"
    "txt"
    "dockerfile"
    "makefile"
    "gradle"
    "maven"
    "sbt"
    "vue"
    "svelte"
)

# Additional specific filenames to include
SPECIFIC_FILES=(
    "Dockerfile"
    "Makefile"
    "package.json"
    ".env.example"
    "requirements.txt"
    "Gemfile"
    "Gemfile.lock"
    "Cargo.toml"
    "Cargo.lock"
    "go.mod"
    "go.sum"
)

# Clear or create output file
> "$OUTPUT_FILE"

# Header
echo "=================================================================================" >> "$OUTPUT_FILE"
echo "Project Code Collection" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "Source Directory: $SOURCE_DIR" >> "$OUTPUT_FILE"
echo "=================================================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Collecting code files from $SOURCE_DIR..."
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

# Counter for files
FILE_COUNT=0

# Function to should exclude directory
should_exclude() {
    local path="$1"
    # Normalize path: remove leading ./ if present
    path="${path#./}"
    local exclude_dirs=("node_modules" "components" ".git"  "README.md" ".svn" ".hg" "__pycache__" ".pytest_cache" "venv" "env" ".env" "virtualenv" "dist" "build" "target" 
                       ".idea" ".vscode" ".vs" "bin" "obj" ".gradle" ".maven" 
                       "vendor" "packages" ".nuget" "coverage" ".coverage" 
                       ".nyc_output" ".sass-cache" "bower_components" ".next" 
                       ".nuxt" ".cache" , package-lock.json)
    
    for exclude in "${exclude_dirs[@]}"; do
        case "$path" in
            */"$exclude"/*) return 0 ;;
            */"$exclude")   return 0 ;;
            "$exclude"/*)   return 0 ;;
            "$exclude")     return 0 ;;
        esac
    done
    return 1
}

# Function to check if file should be included
should_include_file() {
    local file="$1"
    local basename=$(basename "$file")
    
    # Check specific files
    for specific in "${SPECIFIC_FILES[@]}"; do
        if [[ "$basename" == "$specific" ]]; then
            return 0
        fi
    done
    
    # Check extensions
    for ext in "${EXTENSIONS[@]}"; do
        if [[ "$file" == *".$ext" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Process files
while IFS= read -r -d '' file; do
    # Check if we should exclude this path
    if should_exclude "$file"; then
        continue
    fi
    
    # Check if we should include this file
    if ! should_include_file "$file"; then
        continue
    fi
    
    # Skip if file is empty
    if [ ! -s "$file" ]; then
        continue
    fi
    
    # Get relative path
    REL_PATH=$(realpath --relative-to="$SOURCE_DIR" "$file" 2>/dev/null || echo "$file")
    
    # Add file separator and path
    echo "" >> "$OUTPUT_FILE"
    echo "=================================================================================" >> "$OUTPUT_FILE"
    echo "FILE: $REL_PATH" >> "$OUTPUT_FILE"
    echo "=================================================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Add file contents
    cat "$file" >> "$OUTPUT_FILE" 2>/dev/null || echo "[Error reading file]" >> "$OUTPUT_FILE"
    
    # Add ending separator
    echo "" >> "$OUTPUT_FILE"
    echo "=== END OF FILE: $REL_PATH ===" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Increment counter and show progress
    ((FILE_COUNT++))
    echo "Processed: $REL_PATH"
    
done < <(find "$SOURCE_DIR" -type f -print0 2>/dev/null)

# Footer
echo "" >> "$OUTPUT_FILE"
echo "=================================================================================" >> "$OUTPUT_FILE"
echo "End of Collection" >> "$OUTPUT_FILE"
echo "Total files collected: $FILE_COUNT" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "=================================================================================" >> "$OUTPUT_FILE"

# Summary
echo ""
echo "================================================================================="
echo "Collection complete!"
echo "Total files collected: $FILE_COUNT"
echo "Output saved to: $OUTPUT_FILE"
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "================================================================================="