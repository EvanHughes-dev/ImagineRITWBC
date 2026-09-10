# Get Time Served Root Folder
$RootDir = $PSScriptRoot

# Ensure we are in Root Folder
Push-Location $RootDir

Write-Host "Checking system requirements..." -ForegroundColor Blue
Write-Host ""

# Ensure python exists
if (Get-Command "python" -ErrorAction SilentlyContinue) {
    Write-Host "python is installed!" -ForegroundColor Green
} else {
    Write-Host "python is not installed or shortcut has not been setup. Please install and set file path to python" -ForegroundColor Red
    Write-Host "This can be done via the official python installer found here https://www.python.org/downloads/windows/" -ForegroundColor Red
    exit 1
}

# Ensure pip is installed 
if (Get-Command "pip" -ErrorAction SilentlyContinue) {
    Write-Host "pip is installed!" -ForegroundColor Green
} else {
    Write-Host "pip is NOT installed." -ForegroundColor Red
    Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py
    python get-pip.py
}

# Ensure scons is installed
if (Get-Command "scons" -ErrorAction SilentlyContinue) {
    Write-Host "scons is installed!" -ForegroundColor Green
} else {
    Write-Host "scons is not installed. Attempting to install now." -ForegroundColor Yellow
    pip install scons
}

$compilerFound = $false

# 1. Check for g++ (MinGW / MSYS2)
if (Get-Command "g++" -ErrorAction SilentlyContinue) {
    $ver = & g++ --version | Select-Object -First 1
    Write-Host "g++ found: $ver" -ForegroundColor Green
    $compilerFound = $true
}

# 2. Check for clang++ 
if (Get-Command "clang++" -ErrorAction SilentlyContinue) {
    $ver = & clang++ --version | Select-Object -First 1
    Write-Host "clang++ found: $ver" -ForegroundColor Green
    $compilerFound = $true
}

# 3. Check for MSVC (cl.exe) - only works in a Developer Command Prompt
if (Get-Command "cl" -ErrorAction SilentlyContinue) {
    $ver = & cl 2>&1 | Select-Object -First 1
    Write-Host "MSVC (cl.exe) found: $ver" -ForegroundColor Green
    $compilerFound = $true
}

# 4. Fallback — only reached if none of the above found anything
if (-not $compilerFound) {
    $vcpp = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                             "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "Microsoft Visual C++*" } |
            Select-Object DisplayName, DisplayVersion, InstallDate

    if ($vcpp) {
        Write-Host "No compiler found in PATH, but Visual C++ redistributables are installed:" -ForegroundColor Yellow
        $vcpp | Format-Table -AutoSize
        Write-Host "Note: cl.exe may not be in your PATH. Try opening a 'Developer Command Prompt for VS'." -ForegroundColor Yellow
        $compilerFound = $true
    }
}

# 5. Nothing found — hard stop
if (-not $compilerFound) {
    Write-Host "ERROR: No C++ compiler found (g++, clang++, or MSVC cl.exe)." -ForegroundColor Red
    Write-Host "Please install one of the following:" -ForegroundColor Red
    Write-Host "  - MinGW-w64 (g++):  https://www.mingw-w64.org/" -ForegroundColor Red
    Write-Host "  - LLVM (clang++):   https://releases.llvm.org/" -ForegroundColor Red
    Write-Host "  - Visual Studio:    https://visualstudio.microsoft.com/" -ForegroundColor Red
    exit 1
}

Write-Host ""

Write-Host "Updating submodules..." -ForegroundColor Blue
git submodule update --init --recursive --quiet
Write-Host "Submodules updated" -ForegroundColor Blue

Write-Host "" -ForegroundColor Blue
Write-Host "Checking scons install..." -ForegroundColor Blue

$godotCppDir = Join-Path $PSScriptRoot "godot-cpp"

# Check if godot-cpp bindings are already built by looking for the generated
# scons produces 'gen/include' after a successful build
$bindingsReady = Test-Path (Join-Path $godotCppDir "gen\include")

if ($bindingsReady) {
    Write-Host "godot-cpp bindings already built, skipping scons." -ForegroundColor Green
} else {
    Write-Host "Building godot-cpp bindings..." -ForegroundColor Blue
    Push-Location $godotCppDir
    scons api_version=4.6 --quiet 2>&1 | Where-Object { $_ -notmatch "^\s*$" }
    Pop-Location
    Write-Host "godot-cpp bindings built successfully." -ForegroundColor Green
}

Pop-Location


Write-Host ""
Write-Host "cpp setup for Godot successful. File structure displayed below" -ForegroundColor Blue

Write-Host ""

Write-Host "TimeServed/" -ForegroundColor Cyan
Write-Host '|-- godot-cpp/                      ' -NoNewline; Write-Host '# submodule - C++ bindings (do not edit)' -ForegroundColor DarkGray
Write-Host '|-- src/                            ' -NoNewline; Write-Host '# your extension source code' -ForegroundColor DarkGray
Write-Host '|-- TimeServed-Godot/               ' -NoNewline; Write-Host '# Godot Project' -ForegroundColor DarkGray
Write-Host '|   |-- bin/' 
Write-Host '|   |   |-- time-served.gdextension ' -NoNewline; Write-Host '# compiled cpp code' -ForegroundColor DarkGray
Write-Host '|-- SConstruct                      ' -NoNewline; Write-Host '# build configuration' -ForegroundColor DarkGray
Write-Host '|-- .gitmodules                     ' -NoNewline; Write-Host '# submodule config (auto-managed by Git)' -ForegroundColor DarkGray