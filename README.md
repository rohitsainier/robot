# 🛠️ Developer Productivity Scripts Suite

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)
![Shell](https://img.shields.io/badge/shell-bash-orange.svg)

**A comprehensive collection of powerful bash scripts for code analysis, project management, and iOS/macOS development**

[Features](#-features) • [Installation](#-installation) • [Scripts](#-scripts) • [Usage](#-usage) • [Contributing](#-contributing)

</div>

---

## ✨ Features

- 🔍 **Code Quality Analysis** - Detect duplicate and unused code in your projects
- 📦 **Code Collection** - Aggregate all project files into a single document
- 🎯 **iOS/macOS Development** - Build and package macOS applications
- 🌳 **Project Visualization** - Display beautiful directory tree structures
- 🎨 **Colored Output** - Enhanced terminal output with color coding
- 📊 **Detailed Reports** - Generate comprehensive HTML and Markdown reports

## 📋 Prerequisites

- **macOS** (for iOS/macOS specific scripts)
- **Bash 4.0+**
- **Python 3.6+**
- **Homebrew** (for automatic tool installation)

## 🚀 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/yourusername/dev-scripts-suite.git
cd dev-scripts-suite

# Make all scripts executable
chmod +x *.sh

# Optional: Add to PATH
echo 'export PATH="$PATH:~/dev-scripts-suite"' >> ~/.bashrc
source ~/.bashrc
```

### Required Tools (Auto-installed by scripts)

The scripts will automatically install required dependencies via Homebrew:

- `swiftlint` - Swift style and conventions
- `periphery` - Unused Swift code detection  
- `pmd` - Copy-paste detection
- `jq` - JSON processing
- `ag` - Fast file searching

## 📚 Scripts

### 1. 📝 Code Collector (`collect_code.sh`)

Aggregates all code files from a project into a single text file for easy review or sharing.

<details>
<summary><b>Features</b></summary>

- ✅ Supports 40+ programming languages
- ✅ Excludes build artifacts and dependencies
- ✅ Preserves file structure and paths
- ✅ Customizable file extensions
- ✅ Progress tracking

</details>

<details>
<summary><b>Usage</b></summary>

```bash
# Collect from current directory
./collect_code.sh

# Specify source and output
./collect_code.sh /path/to/project output.txt

# Example output structure
# ==========================================
# FILE: src/main.swift
# ==========================================
# [file contents]
# === END OF FILE: src/main.swift ===
```

</details>

<details>
<summary><b>Supported Languages</b></summary>

| Language | Extensions |
|----------|------------|
| Python | `.py` |
| JavaScript | `.js`, `.jsx`, `.ts`, `.tsx` |
| Swift | `.swift` |
| Java | `.java` |
| C/C++ | `.c`, `.cpp`, `.h`, `.hpp` |
| Ruby | `.rb` |
| Go | `.go` |
| Rust | `.rs` |
| And 30+ more... | |

</details>

---

### 2. 🔍 iOS/macOS Code Quality Analyzer (`ios_code_analyzer.sh`)

Comprehensive code quality analysis tool for Apple platform projects.

<details>
<summary><b>Features</b></summary>

- 🔄 **Duplicate Code Detection**
  - Hash-based function matching
  - PMD CPD integration
  - Cross-file analysis
  
- 🗑️ **Unused Code Detection**
  - Functions, classes, and methods
  - Resource files (images, XIBs)
  - Localization strings
  
- 📊 **Code Metrics**
  - Lines of code statistics
  - SwiftLint violations
  - Large file detection

</details>

<details>
<summary><b>Usage</b></summary>

```bash
# Analyze current directory
./ios_code_analyzer.sh

# Analyze specific project
./ios_code_analyzer.sh /path/to/ios/project

# Skip tool installation
./ios_code_analyzer.sh . --no-install

# Custom settings
./ios_code_analyzer.sh . --exclude Tests --min-lines 10
```

</details>

<details>
<summary><b>Report Structure</b></summary>

```
code_analysis_report/
└── 20240101_120000/
    ├── SUMMARY.md           # Executive summary
    ├── duplicate/
    │   ├── swift_duplicates.xml
    │   └── swift_function_duplicates.json
    ├── unused/
    │   ├── periphery_report.json
    │   └── unused_swift_simple.txt
    └── resources/
        └── unused_images.json
```

</details>

<details>
<summary><b>Sample Output</b></summary>

```markdown
================================================================================
CODE QUALITY ANALYSIS REPORT
================================================================================

SUMMARY
----------------------------------------
Total files analyzed: 125
Duplicate code blocks found: 8
Unused functions: 23
Unused classes: 5
Unused images: 47

DUPLICATE CODE
----------------------------------------
EXACT Duplicate (found in 3 places):
  - ViewControllers/HomeVC.swift:45-89
  - ViewControllers/ProfileVC.swift:23-67
  - ViewControllers/SettingsVC.swift:100-144
```

</details>

---

### 3. 📦 macOS App Builder & Packager

Builds and packages macOS applications into distributable DMG files.

<details>
<summary><b>Features</b></summary>

- 🏗️ Clean build with Release configuration
- 🔐 Ad-hoc code signing
- 💿 DMG creation with Applications shortcut
- 🧹 Automatic cleanup

</details>

<details>
<summary><b>Usage</b></summary>

```bash
# Navigate to your project
cd /path/to/your/macos/app

# Run the build script
./build_dmg.sh

# Output: ~/Desktop/YourApp.dmg
```

</details>

---

### 4. 🌳 Project Tree Visualizer (`project-tree.sh`)

Advanced directory structure viewer with colored output and file statistics.

<details>
<summary><b>Features</b></summary>

- 🎨 Color-coded file types
- 📏 Adjustable depth levels
- 📊 File size display
- 🙈 Hidden file toggle
- 📁 Directory-only mode

</details>

<details>
<summary><b>Usage</b></summary>

```bash
# Current directory
./project-tree.sh

# Specific directory with options
./project-tree.sh /path/to/project -d 3 -s

# Show only directories with sizes
./project-tree.sh -D -s

# Include hidden files
./project-tree.sh -a
```

</details>

<details>
<summary><b>Options</b></summary>

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-d, --depth LEVEL` | Maximum display depth |
| `-a, --all` | Show hidden files |
| `-D, --dirs-only` | Show only directories |
| `-c, --no-color` | Disable colored output |
| `-s, --size` | Show file/folder sizes |
| `-i, --ignore PATTERN` | Add ignore pattern |

</details>

<details>
<summary><b>Sample Output</b></summary>

```
MyProject/
├── 📁 src/ [2.3M]
│   ├── 📄 main.swift [12K]
│   ├── 📁 controllers/ [890K]
│   │   ├── 📄 HomeController.swift [45K]
│   │   └── 📄 SettingsController.swift [38K]
│   └── 📁 models/ [1.4M]
│       └── 📄 User.swift [15K]
├── 📁 tests/ [456K]
│   └── 📄 UserTests.swift [23K]
└── 📄 README.md [8K]

Summary: 4 directories, 6 files
```

</details>

## 🎯 Use Cases

### For iOS/macOS Developers
- Pre-release code quality checks
- App size optimization by finding unused resources
- Code review preparation
- CI/CD pipeline integration

### For Team Leads
- Code quality metrics tracking
- Technical debt assessment
- Code duplication analysis
- Project structure documentation

### For All Developers
- Quick project overview
- Code sharing and review
- Project cleanup and optimization
- Documentation generation

## 📊 Example Workflow

```bash
# 1. Visualize project structure
./project-tree.sh /path/to/project -d 2

# 2. Analyze code quality
./ios_code_analyzer.sh /path/to/project

# 3. Review the report
open code_analysis_report/*/SUMMARY.md

# 4. Collect code for review
./collect_code.sh /path/to/project review_code.txt

# 5. Build and package (for macOS apps)
./build_dmg.sh
```

## 🔧 Configuration

### Customizing Code Collector

Edit the `EXTENSIONS` array in `collect_code.sh`:

```bash
EXTENSIONS=(
    "swift"
    "m"
    "h"
    # Add your extensions here
)
```

### Customizing Ignore Patterns

```bash
# In collect_code.sh
exclude_dirs=("node_modules" ".git" "Pods" "YourCustomDir")

# In ios_code_analyzer.sh
EXCLUDE_DIRS=("Pods" "Carthage" "YourFramework")
```

## 🐛 Troubleshooting

<details>
<summary><b>Common Issues & Solutions</b></summary>

### Script Permission Denied
```bash
chmod +x script_name.sh
```

### Homebrew Not Found
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Python Errors
```bash
# Ensure Python 3 is installed
python3 --version

# Install if missing
brew install python3
```

### Xcode Command Line Tools
```bash
xcode-select --install
```

</details>

## 📈 Performance Tips

- **Large Projects**: Use `--exclude` flags to skip unnecessary directories
- **Faster Analysis**: Run with `--no-install` if tools are already installed
- **Memory Usage**: For very large projects, consider analyzing modules separately

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [SwiftLint](https://github.com/realm/SwiftLint) for Swift code analysis
- [Periphery](https://github.com/peripheryapp/periphery) for unused code detection
- [PMD](https://pmd.github.io/) for copy-paste detection
- The open-source community for inspiration and tools

## 📮 Contact & Support

- 📧 Email: rohitsainier@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/rohitsainier/dev-scripts-suite/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/rohitsainier/dev-scripts-suite/discussions)

---

<div align="center">

**Made with ❤️ by developers, for developers**

⭐ Star this repo if you find it useful! ⭐

</div>