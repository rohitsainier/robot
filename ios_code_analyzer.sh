#!/bin/bash

# ================================================================
# iOS/macOS Code Quality Analyzer - FIXED VERSION
# Detects duplicate code, unused code, and resources in Apple projects
# ================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
PROJECT_PATH="${1:-.}"
OUTPUT_DIR="code_analysis_report"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="${OUTPUT_DIR}/${TIMESTAMP}"
MIN_DUPLICATE_LINES=5
MIN_DUPLICATE_TOKENS=50
EXCLUDE_DIRS=("Pods" "Carthage" ".build" "DerivedData" "build" "*.xcodeproj" "*.xcworkspace" "vendor" "node_modules")

# Tool check flags
HAS_SWIFTLINT=false
HAS_PERIPHERY=false
HAS_OCLINT=false
HAS_PMD=false
HAS_XCODEPROJ=false

# ================================================================
# Helper Functions
# ================================================================

print_header() {
    echo -e "\n${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${BOLD}${MAGENTA}▶ $1${NC}"
    echo -e "${MAGENTA}$(printf '─%.0s' {1..60})${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install missing tools
install_tools() {
    print_section "Checking and Installing Required Tools"
    
    # Check for Homebrew
    if ! command_exists brew; then
        print_error "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Check/Install SwiftLint
    if command_exists swiftlint; then
        HAS_SWIFTLINT=true
        print_success "SwiftLint found"
    else
        print_warning "SwiftLint not found. Installing..."
        brew install swiftlint
        HAS_SWIFTLINT=true
    fi
    
    # Check/Install Periphery (for unused code detection)
    if command_exists periphery; then
        HAS_PERIPHERY=true
        print_success "Periphery found"
    else
        print_warning "Periphery not found. Installing..."
        brew install peripheryapp/periphery/periphery
        HAS_PERIPHERY=true
    fi
    
    # Check for PMD (for CPD - Copy Paste Detector)
    if command_exists pmd; then
        HAS_PMD=true
        print_success "PMD found"
    else
        print_warning "PMD not found. Installing..."
        brew install pmd
        HAS_PMD=true
    fi
    
    # Install jq for JSON processing
    if ! command_exists jq; then
        print_warning "jq not found. Installing..."
        brew install jq
    fi
    
    # Install ag (silver searcher) for fast searching
    if ! command_exists ag; then
        print_warning "ag not found. Installing..."
        brew install the_silver_searcher
    fi
}

# Create report directory structure
setup_report_directory() {
    mkdir -p "${REPORT_DIR}"/{duplicate,unused,resources,metrics}
    print_success "Report directory created: ${REPORT_DIR}"
}

# ================================================================
# Duplicate Code Detection
# ================================================================

detect_duplicate_swift() {
    print_section "Detecting Duplicate Swift Code"
    
    local swift_files=$(find "$PROJECT_PATH" -name "*.swift" -type f 2>/dev/null | grep -v -E "Pods|Carthage|.build|DerivedData" || true)
    
    if [ -z "$swift_files" ]; then
        print_warning "No Swift files found"
        return
    fi
    
    # Using PMD's CPD for duplicate detection
    if [ "$HAS_PMD" = true ]; then
        print_info "Running PMD CPD for Swift..."
        
        pmd cpd --minimum-tokens $MIN_DUPLICATE_TOKENS \
            --language swift \
            --files "$PROJECT_PATH" \
            --exclude "**/Pods/**,**/Carthage/**,**/.build/**" \
            --format xml > "${REPORT_DIR}/duplicate/swift_duplicates.xml" 2>/dev/null || true
    fi
    
    # Alternative: Use simple hash-based detection
    print_info "Running hash-based duplicate detection..."
    
    cat > /tmp/detect_swift_duplicates.py <<'PYTHON_EOF'
#!/usr/bin/env python3
import sys
import os
import hashlib
import json
from collections import defaultdict

def extract_functions(filepath):
    functions = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            if any(line.startswith(x) for x in ['func ', 'private func', 'public func', 'internal func']):
                start = i
                brace_count = 0
                found_opening = False
                
                for j in range(i, len(lines)):
                    if '{' in lines[j]:
                        brace_count += lines[j].count('{')
                        found_opening = True
                    if '}' in lines[j]:
                        brace_count -= lines[j].count('}')
                    
                    if found_opening and brace_count == 0:
                        func_content = ''.join(lines[start:j+1])
                        # Normalize the content for hashing
                        normalized = ' '.join(func_content.split())
                        func_hash = hashlib.md5(normalized.encode()).hexdigest()
                        functions.append({
                            'file': filepath,
                            'start_line': start + 1,
                            'end_line': j + 1,
                            'content': func_content[:200] if len(func_content) > 200 else func_content,
                            'hash': func_hash
                        })
                        i = j
                        break
            i += 1
    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
    
    return functions

# Main
duplicates = defaultdict(list)
project_path = sys.argv[1] if len(sys.argv) > 1 else '.'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'duplicates.json'

for root, dirs, files in os.walk(project_path):
    dirs[:] = [d for d in dirs if not any(exc in d for exc in ['Pods', 'Carthage', '.build', 'DerivedData'])]
    for file in files:
        if file.endswith('.swift'):
            filepath = os.path.join(root, file)
            for func in extract_functions(filepath):
                duplicates[func['hash']].append(func)

result = {
    'duplicates': [
        {'hash': h, 'occurrences': funcs}
        for h, funcs in duplicates.items()
        if len(funcs) > 1
    ]
}

with open(output_file, 'w') as f:
    json.dump(result, f, indent=2)

print(f"Found {len(result['duplicates'])} groups of duplicate functions")
PYTHON_EOF
    
    python3 /tmp/detect_swift_duplicates.py "$PROJECT_PATH" "${REPORT_DIR}/duplicate/swift_function_duplicates.json"
}

# ================================================================
# Unused Code Detection - FIXED
# ================================================================

detect_unused_swift_code() {
    print_section "Detecting Unused Swift Code"
    
    if [ "$HAS_PERIPHERY" = true ]; then
        print_info "Running Periphery for unused code detection..."
        
        # Find xcodeproj or xcworkspace
        local project_file=$(find "$PROJECT_PATH" -name "*.xcworkspace" -o -name "*.xcodeproj" 2>/dev/null | head -1)
        
        if [ -n "$project_file" ]; then
            # Try to get scheme name
            local scheme_name=""
            if command_exists xcodebuild; then
                scheme_name=$(xcodebuild -list -json 2>/dev/null | jq -r '.project.schemes[0]' 2>/dev/null || echo "")
            fi
            
            if [ -n "$scheme_name" ]; then
                periphery scan \
                    --project "$project_file" \
                    --schemes "$scheme_name" \
                    --targets all \
                    --format json \
                    > "${REPORT_DIR}/unused/periphery_report.json" 2>/dev/null || true
            else
                periphery scan \
                    --project "$project_file" \
                    --format json \
                    > "${REPORT_DIR}/unused/periphery_report.json" 2>/dev/null || true
            fi
            
            if [ -f "${REPORT_DIR}/unused/periphery_report.json" ] && [ -s "${REPORT_DIR}/unused/periphery_report.json" ]; then
                local unused_count=$(cat "${REPORT_DIR}/unused/periphery_report.json" | jq '. | length' 2>/dev/null || echo "0")
                print_info "Found $unused_count unused Swift declarations"
            fi
        else
            print_warning "No Xcode project found for Periphery analysis"
        fi
    fi
    
    # Alternative: Simple unused detection - FIXED
    print_info "Running pattern-based unused detection..."
    
    cat > /tmp/detect_unused_swift.py <<'PYTHON_EOF'
#!/usr/bin/env python3
import os
import re
import sys

project_path = sys.argv[1] if len(sys.argv) > 1 else '.'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'unused.txt'

# Find all Swift files
swift_files = []
for root, dirs, files in os.walk(project_path):
    dirs[:] = [d for d in dirs if not any(exc in d for exc in ['Pods', 'Carthage', '.build', 'DerivedData'])]
    for file in files:
        if file.endswith('.swift'):
            swift_files.append(os.path.join(root, file))

# Extract declarations
declarations = set()
all_content = []

for filepath in swift_files:
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            all_content.append(content)
            
            # Find function declarations
            func_pattern = r'(?:public |private |internal |fileprivate |open )?func\s+([a-zA-Z_][a-zA-Z0-9_]*)'
            for match in re.finditer(func_pattern, content):
                declarations.add(('func', match.group(1)))
            
            # Find class declarations
            class_pattern = r'(?:public |private |internal |fileprivate |open )?class\s+([a-zA-Z_][a-zA-Z0-9_]*)'
            for match in re.finditer(class_pattern, content):
                declarations.add(('class', match.group(1)))
            
            # Find struct declarations
            struct_pattern = r'(?:public |private |internal |fileprivate |open )?struct\s+([a-zA-Z_][a-zA-Z0-9_]*)'
            for match in re.finditer(struct_pattern, content):
                declarations.add(('struct', match.group(1)))
    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)

# Check usage
all_text = '\n'.join(all_content)
unused = []

for decl_type, name in declarations:
    # Skip common names
    if name in ['init', 'deinit', 'viewDidLoad', 'viewWillAppear', 'viewDidAppear', 
                'awakeFromNib', 'setUp', 'tearDown', 'main']:
        continue
    
    # Count occurrences (declaration + usages)
    count = len(re.findall(r'\b' + re.escape(name) + r'\b', all_text))
    
    if count <= 1:  # Only found once (the declaration itself)
        unused.append(f"{decl_type} {name}: potentially unused")

# Write results
with open(output_file, 'w') as f:
    for item in sorted(unused):
        f.write(item + '\n')

print(f"Found {len(unused)} potentially unused declarations")
PYTHON_EOF
    
    python3 /tmp/detect_unused_swift.py "$PROJECT_PATH" "${REPORT_DIR}/unused/unused_swift_simple.txt"
}

detect_unused_objc_code() {
    print_section "Detecting Unused Objective-C Code"
    
    cat > /tmp/detect_unused_objc.py <<'PYTHON_EOF'
#!/usr/bin/env python3
import os
import re
import sys
import json

def find_objc_declarations(project_path):
    declarations = {
        'classes': set(),
        'methods': set(),
        'properties': set()
    }
    
    for root, dirs, files in os.walk(project_path):
        dirs[:] = [d for d in dirs if not any(exc in d for exc in ['Pods', 'Carthage', 'DerivedData'])]
        
        for file in files:
            if file.endswith('.h'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Find interface declarations
                        classes = re.findall(r'@interface\s+(\w+)', content)
                        declarations['classes'].update(classes)
                        
                        # Find method declarations
                        methods = re.findall(r'[-+]\s*KATEX_INLINE_OPEN[^)]+KATEX_INLINE_CLOSE\s*(\w+)', content)
                        declarations['methods'].update(methods)
                        
                        # Find property declarations
                        properties = re.findall(r'@property[^;]*\s+(\w+)\s*;', content)
                        declarations['properties'].update(properties)
                except Exception as e:
                    print(f"Error reading {filepath}: {e}", file=sys.stderr)
    
    return declarations

def find_usages(project_path, declarations):
    unused = {
        'classes': list(declarations['classes']),
        'methods': list(declarations['methods']),
        'properties': list(declarations['properties'])
    }
    
    for root, dirs, files in os.walk(project_path):
        dirs[:] = [d for d in dirs if not any(exc in d for exc in ['Pods', 'Carthage', 'DerivedData'])]
        
        for file in files:
            if file.endswith(('.m', '.mm', '.swift')):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Remove from unused if found
                        for cls in list(unused['classes']):
                            if cls in content:
                                if cls in unused['classes']:
                                    unused['classes'].remove(cls)
                        
                        for method in list(unused['methods']):
                            if method in content:
                                if method in unused['methods']:
                                    unused['methods'].remove(method)
                        
                        for prop in list(unused['properties']):
                            if prop in content:
                                if prop in unused['properties']:
                                    unused['properties'].remove(prop)
                except Exception as e:
                    print(f"Error reading {filepath}: {e}", file=sys.stderr)
    
    return unused

# Main
project_path = sys.argv[1] if len(sys.argv) > 1 else '.'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'unused_objc.json'

declarations = find_objc_declarations(project_path)
unused = find_usages(project_path, declarations)

with open(output_file, 'w') as f:
    json.dump(unused, f, indent=2)

print(f"Found {len(unused['classes'])} unused classes, {len(unused['methods'])} unused methods")
PYTHON_EOF
    
    python3 /tmp/detect_unused_objc.py "$PROJECT_PATH" "${REPORT_DIR}/unused/unused_objc.json"
}

# ================================================================
# Unused Resources Detection - FIXED
# ================================================================

detect_unused_resources() {
    print_section "Detecting Unused Resources"
    
    # Find unused images - FIXED
    print_info "Checking for unused images..."
    
    cat > /tmp/detect_unused_images.py <<'PYTHON_EOF'
#!/usr/bin/env python3
import os
import re
import sys
import json

def find_image_references(project_path):
    image_files = set()
    used_images = set()
    
    for root, dirs, files in os.walk(project_path):
        dirs[:] = [d for d in dirs if not any(exc in d for exc in ['Pods', 'Carthage', '.build', 'DerivedData'])]
        
        for file in files:
            # Collect image files
            if file.endswith(('.png', '.jpg', '.jpeg', '.pdf', '.svg')):
                # Remove size suffixes and extension
                image_name = os.path.splitext(file)[0]
                image_name = image_name.replace('@2x', '').replace('@3x', '').replace('@1x', '')
                image_files.add(image_name)
            
            # Check for image usage in code
            if file.endswith(('.swift', '.m', '.mm')):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                        # Swift patterns for image usage
                        patterns = [
                            r'UIImage\s*KATEX_INLINE_OPEN\s*named:\s*"([^"]+)"',
                            r'Image\s*KATEX_INLINE_OPEN\s*"([^"]+)"',
                            r'UIImage\s*KATEX_INLINE_OPEN\s*systemName:\s*"([^"]+)"',
                            r'imageNamed:\s*@?"([^"]+)"'
                        ]
                        
                        for pattern in patterns:
                            matches = re.findall(pattern, content)
                            for match in matches:
                                image_name = match.replace('@2x', '').replace('@3x', '').replace('@1x', '')
                                used_images.add(image_name)
                except Exception as e:
                    print(f"Error reading {filepath}: {e}", file=sys.stderr)
            
            # Check storyboards and xibs
            if file.endswith(('.storyboard', '.xib')):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        matches = re.findall(r'image="([^"]+)"', content)
                        for match in matches:
                            image_name = match.replace('@2x', '').replace('@3x', '').replace('@1x', '')
                            used_images.add(image_name)
                except Exception as e:
                    print(f"Error reading {filepath}: {e}", file=sys.stderr)
    
    unused_images = list(image_files - used_images)
    return {
        'total_images': len(image_files),
        'used_images': len(used_images),
        'unused_images': sorted(unused_images)
    }

# Main
project_path = sys.argv[1] if len(sys.argv) > 1 else '.'
output_file = sys.argv[2] if len(sys.argv) > 2 else 'unused_images.json'

result = find_image_references(project_path)

with open(output_file, 'w') as f:
    json.dump(result, f, indent=2)

print(f"Found {len(result['unused_images'])} unused images out of {result['total_images']} total")
PYTHON_EOF
    
    python3 /tmp/detect_unused_images.py "$PROJECT_PATH" "${REPORT_DIR}/resources/unused_images.json"
    
    # Find unused storyboards and XIBs
    print_info "Checking for unused storyboards and XIBs..."
    
    > "${REPORT_DIR}/resources/unused_interfaces.txt"
    find "$PROJECT_PATH" KATEX_INLINE_OPEN -name "*.storyboard" -o -name "*.xib" KATEX_INLINE_CLOSE -type f 2>/dev/null | while read -r file; do
        basename_file=$(basename "$file" | sed 's/\.[^.]*$//')
        # Skip Launch screens and Main storyboards
        if [[ "$basename_file" == "LaunchScreen" ]] || [[ "$basename_file" == "Main" ]]; then
            continue
        fi
        usage_count=$(grep -r "$basename_file" "$PROJECT_PATH" --include="*.swift" --include="*.m" --include="*.plist" 2>/dev/null | wc -l)
        if [ "$usage_count" -le 1 ]; then
            echo "$file: potentially unused (found $usage_count references)" >> "${REPORT_DIR}/resources/unused_interfaces.txt"
        fi
    done
}

# ================================================================
# Generate Summary Report
# ================================================================

generate_summary() {
    print_section "Generating Summary Report"
    
    cat > "${REPORT_DIR}/SUMMARY.md" <<EOF
# Code Quality Analysis Report

## Project: $(basename "$PROJECT_PATH")
## Date: $(date)

---

## 📊 Summary Statistics

### Files Analyzed
EOF
    
    # Count files
    swift_count=$(find "$PROJECT_PATH" -name "*.swift" 2>/dev/null | grep -v -E "Pods|Carthage|.build|DerivedData" | wc -l || echo "0")
    objc_count=$(find "$PROJECT_PATH" KATEX_INLINE_OPEN -name "*.m" -o -name "*.h" KATEX_INLINE_CLOSE 2>/dev/null | grep -v -E "Pods|Carthage|.build|DerivedData" | wc -l || echo "0")
    
    echo "- Swift files: $swift_count" >> "${REPORT_DIR}/SUMMARY.md"
    echo "- Objective-C files: $objc_count" >> "${REPORT_DIR}/SUMMARY.md"
    
    cat >> "${REPORT_DIR}/SUMMARY.md" <<EOF

### Issues Found
EOF
    
    # Add duplicate code summary
    if [ -f "${REPORT_DIR}/duplicate/swift_function_duplicates.json" ]; then
        dup_count=$(jq '.duplicates | length' "${REPORT_DIR}/duplicate/swift_function_duplicates.json" 2>/dev/null || echo "0")
        echo "- Duplicate Swift code blocks: $dup_count" >> "${REPORT_DIR}/SUMMARY.md"
    fi
    
    # Add unused code summary
    if [ -f "${REPORT_DIR}/unused/unused_swift_simple.txt" ]; then
        unused_count=$(wc -l < "${REPORT_DIR}/unused/unused_swift_simple.txt" 2>/dev/null || echo "0")
        echo "- Potentially unused Swift items: $unused_count" >> "${REPORT_DIR}/SUMMARY.md"
    fi
    
    # Add unused resources summary
    if [ -f "${REPORT_DIR}/resources/unused_images.json" ]; then
        unused_images=$(jq '.unused_images | length' "${REPORT_DIR}/resources/unused_images.json" 2>/dev/null || echo "0")
        echo "- Unused images: $unused_images" >> "${REPORT_DIR}/SUMMARY.md"
    fi
    
    cat >> "${REPORT_DIR}/SUMMARY.md" <<EOF

---

## 📝 Recommendations

1. **Duplicate Code**: Review and refactor duplicate code blocks into reusable components
2. **Unused Code**: Remove or document unused functions and classes
3. **Resources**: Clean up unused images and assets to reduce app size

---

## 📁 Report Files

- \`duplicate/\`: Contains duplicate code analysis
- \`unused/\`: Contains unused code analysis
- \`resources/\`: Contains unused resources analysis

EOF
    
    print_success "Summary report generated: ${REPORT_DIR}/SUMMARY.md"
}

# ================================================================
# Main Execution
# ================================================================

main() {
    print_header "iOS/macOS Code Quality Analyzer"
    
    # Validate project path
    if [ ! -d "$PROJECT_PATH" ]; then
        print_error "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi
    
    print_info "Analyzing project: $PROJECT_PATH"
    
    # Install tools if needed
    install_tools
    
    # Setup report directory
    setup_report_directory
    
    # Run analyses
    detect_duplicate_swift
    detect_unused_swift_code
    detect_unused_objc_code
    detect_unused_resources
    
    # Generate reports
    generate_summary
    
    # Final summary
    print_header "Analysis Complete!"
    print_success "Reports saved to: ${REPORT_DIR}"
    print_info "View the summary: cat ${REPORT_DIR}/SUMMARY.md"
}

# Run main function
main "$@"