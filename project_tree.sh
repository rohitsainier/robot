#!/bin/bash

# project-tree.sh - Advanced directory structure viewer
# Usage: ./project-tree.sh [OPTIONS] [directory]

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DIR="."
MAX_DEPTH=-1
SHOW_HIDDEN=false
SHOW_FILES=true
IGNORE_PATTERNS=(".git" "node_modules" ".vscode" "__pycache__" ".DS_Store" "*.xcodeproj" "*.xcworkspace" "build")
USE_COLORS=true
SHOW_SIZE=false

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY]

Display directory tree structure

OPTIONS:
    -h, --help          Show this help message
    -d, --depth LEVEL   Max display depth (default: unlimited)
    -a, --all           Show hidden files
    -D, --dirs-only     Show only directories
    -c, --no-color      Disable colored output
    -s, --size          Show file sizes
    -i, --ignore PATTERN Add ignore pattern
    
EXAMPLES:
    $(basename "$0")                    # Current directory
    $(basename "$0") /path/to/project   # Specific directory
    $(basename "$0") -d 2 -a            # Depth 2, show hidden
    $(basename "$0") -D -s               # Dirs only with sizes
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        -a|--all)
            SHOW_HIDDEN=true
            shift
            ;;
        -D|--dirs-only)
            SHOW_FILES=false
            shift
            ;;
        -c|--no-color)
            USE_COLORS=false
            shift
            ;;
        -s|--size)
            SHOW_SIZE=true
            shift
            ;;
        -i|--ignore)
            IGNORE_PATTERNS+=("$2")
            shift 2
            ;;
        *)
            DIR="$1"
            shift
            ;;
    esac
done

# Function to check if item should be ignored
should_ignore() {
    local item="$1"
    local basename=$(basename "$item")
    
    # Skip hidden files if not requested
    if [[ $SHOW_HIDDEN == false && $basename == .* ]]; then
        return 0
    fi
    
    # Check ignore patterns
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        if [[ $basename == $pattern ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to get human-readable size
get_size() {
    local file="$1"
    if [[ -d "$file" ]]; then
        if command -v du >/dev/null 2>&1; then
            du -sh "$file" 2>/dev/null | cut -f1
        else
            echo "DIR"
        fi
    else
        if command -v stat >/dev/null 2>&1; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                stat -f%z "$file" | awk '{ 
                    if ($1 < 1024) print $1 "B"
                    else if ($1 < 1048576) printf "%.1fK", $1/1024
                    else if ($1 < 1073741824) printf "%.1fM", $1/1048576
                    else printf "%.1fG", $1/1073741824
                }'
            else
                stat -c%s "$file" | awk '{ 
                    if ($1 < 1024) print $1 "B"
                    else if ($1 < 1048576) printf "%.1fK", $1/1024
                    else if ($1 < 1073741824) printf "%.1fM", $1/1048576
                    else printf "%.1fG", $1/1073741824
                }'
            fi
        else
            echo "N/A"
        fi
    fi
}

# Function to print colored output
print_colored() {
    local item="$1"
    local prefix="$2"
    local basename=$(basename "$item")
    local output="$prefix"
    
    if [[ $USE_COLORS == true ]]; then
        if [[ -d "$item" ]]; then
            output+="${BLUE}${basename}/${NC}"
        elif [[ -x "$item" ]]; then
            output+="${GREEN}${basename}${NC}"
        elif [[ $basename == *.md || $basename == *.txt ]]; then
            output+="${YELLOW}${basename}${NC}"
        elif [[ $basename == *.sh || $basename == *.py || $basename == *.js ]]; then
            output+="${RED}${basename}${NC}"
        else
            output+="$basename"
        fi
    else
        if [[ -d "$item" ]]; then
            output+="${basename}/"
        else
            output+="$basename"
        fi
    fi
    
    if [[ $SHOW_SIZE == true ]]; then
        local size=$(get_size "$item")
        output+=" [${size}]"
    fi
    
    echo -e "$output"
}

# Function to print tree structure
print_tree() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"
    
    # Check if max depth is reached
    if [[ $MAX_DEPTH -ne -1 && $depth -ge $MAX_DEPTH ]]; then
        return
    fi
    
    # Get all items in directory
    local items=()
    while IFS= read -r -d $'\0' item; do
        # Skip if should be ignored
        if should_ignore "$item"; then
            continue
        fi
        
        # Skip files if dirs-only mode
        if [[ $SHOW_FILES == false && -f "$item" ]]; then
            continue
        fi
        
        items+=("$item")
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | sort -z)
    
    local count=${#items[@]}
    local index=0
    
    for item in "${items[@]}"; do
        index=$((index + 1))
        
        # Determine if it's the last item
        if [[ $index -eq $count ]]; then
            print_colored "$item" "${prefix}└── " 
            local new_prefix="${prefix}    "
        else
            print_colored "$item" "${prefix}├── "
            local new_prefix="${prefix}│   "
        fi
        
        # Recurse if it's a directory
        if [[ -d "$item" ]]; then
            print_tree "$item" "$new_prefix" $((depth + 1))
        fi
    done
}

# Statistics
count_items() {
    local dir="$1"
    local dirs=0
    local files=0
    
    while IFS= read -r item; do
        if should_ignore "$item"; then
            continue
        fi
        
        if [[ -d "$item" ]]; then
            dirs=$((dirs + 1))
        else
            files=$((files + 1))
        fi
    done < <(find "$dir" -mindepth 1 2>/dev/null)
    
    echo -e "\n${GREEN}Summary:${NC} $dirs directories, $files files"
}

# Main execution
if [[ ! -d "$DIR" ]]; then
    echo "Error: '$DIR' is not a directory"
    exit 1
fi

# Print header
echo -e "${BLUE}$(basename "$(realpath "$DIR")")/${NC}"
print_tree "$DIR" "" 0

# Show summary if colors are enabled
if [[ $USE_COLORS == true ]]; then
    count_items "$DIR"
fi