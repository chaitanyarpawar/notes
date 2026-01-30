# PebbleNote Release Build Script
# Automatically increments version code and builds signed AAB

param(
    [switch]$IncrementMajor,
    [switch]$IncrementMinor,
    [switch]$IncrementPatch,
    [switch]$SkipIncrement
)

$pubspecPath = "pubspec.yaml"

# Read pubspec.yaml
$content = Get-Content $pubspecPath -Raw

# Extract current version (e.g., 1.0.2+3)
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    $buildNumber = [int]$Matches[4]
    
    Write-Host "Current version: $major.$minor.$patch+$buildNumber" -ForegroundColor Cyan
    
    if (-not $SkipIncrement) {
        # Increment version
        if ($IncrementMajor) {
            $major++
            $minor = 0
            $patch = 0
        } elseif ($IncrementMinor) {
            $minor++
            $patch = 0
        } elseif ($IncrementPatch) {
            $patch++
        }
        
        # Always increment build number
        $buildNumber++
        
        $newVersion = "$major.$minor.$patch+$buildNumber"
        Write-Host "New version: $newVersion" -ForegroundColor Green
        
        # Update pubspec.yaml
        $content = $content -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion"
        Set-Content $pubspecPath $content -NoNewline
        
        Write-Host "Updated pubspec.yaml" -ForegroundColor Green
    }
} else {
    Write-Host "Could not parse version from pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Build AAB
Write-Host "`nBuilding release AAB..." -ForegroundColor Yellow
flutter build appbundle

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "Version: $major.$minor.$patch+$buildNumber" -ForegroundColor Cyan
    Write-Host "AAB: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
