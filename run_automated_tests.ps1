# Automated Flutter Test Runner for Windows
# Usage: .\run_automated_tests.ps1 [-TestType all|unit|widget|integration] [-Coverage]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'unit', 'widget', 'integration')]
    [string]$TestType = 'all',

    [Parameter(Mandatory=$false)]
    [string]$DeviceId = '',

    [Parameter(Mandatory=$false)]
    [switch]$Coverage
)

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$LOG_DIR = Join-Path $SCRIPT_DIR "test_logs"
$RECORDINGS_DIR = Join-Path $LOG_DIR "recordings"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = Join-Path $LOG_DIR "test_run_$TIMESTAMP.log"

# Create log and recordings directories
if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR | Out-Null
}
if (-not (Test-Path $RECORDINGS_DIR)) {
    New-Item -ItemType Directory -Path $RECORDINGS_DIR | Out-Null
}

# Find ADB dynamically
function Find-ADB {
    # 1. Check if adb is already in PATH
    $adbInPath = Get-Command "adb" -ErrorAction SilentlyContinue
    if ($adbInPath) {
        return $adbInPath.Source
    }

    # 2. Check ANDROID_HOME environment variable
    $androidHome = $env:ANDROID_HOME
    if ($androidHome -and (Test-Path $androidHome)) {
        $adbPath = Join-Path $androidHome "platform-tools\adb.exe"
        if (Test-Path $adbPath) {
            return $adbPath
        }
    }

    # 3. Check ANDROID_SDK_ROOT environment variable
    $androidSdkRoot = $env:ANDROID_SDK_ROOT
    if ($androidSdkRoot -and (Test-Path $androidSdkRoot)) {
        $adbPath = Join-Path $androidSdkRoot "platform-tools\adb.exe"
        if (Test-Path $adbPath) {
            return $adbPath
        }
    }

    # 4. Check common Windows installation paths
    $commonPaths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\android-sdk\platform-tools\adb.exe",
        "C:\Program Files\Android\android-sdk\platform-tools\adb.exe",
        "C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\Android\Sdk\platform-tools\adb.exe"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    # 5. Check Flutter's bundled Android SDK
    try {
        $flutterDoctor = flutter doctor -v 2>&1 | Out-String
        if ($flutterDoctor -match "Android SDK at (.+)") {
            $sdkPath = $matches[1].Trim()
            $adbPath = Join-Path $sdkPath "platform-tools\adb.exe"
            if (Test-Path $adbPath) {
                return $adbPath
            }
        }
    } catch {
        # Flutter doctor failed, continue
    }

    return $null
}

# Initialize ADB path
$global:ADB = Find-ADB
if ($global:ADB) {
    Write-Host "ADB found at: $global:ADB" -ForegroundColor Green
} else {
    Write-Host "WARNING: ADB not found. Integration tests will be skipped." -ForegroundColor Yellow
    Write-Host "Please ensure Android SDK is installed and one of the following is set:" -ForegroundColor Yellow
    Write-Host "  - ANDROID_HOME environment variable" -ForegroundColor Yellow
    Write-Host "  - ANDROID_SDK_ROOT environment variable" -ForegroundColor Yellow
    Write-Host "  - ADB in your PATH" -ForegroundColor Yellow
}

# Helper function to run ADB commands
function Invoke-ADB {
    param([string[]]$Arguments)
    if (-not $global:ADB) {
        return $null
    }
    & $global:ADB @Arguments
}

# Logging function
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LOG_FILE -Value $logMessage

    switch ($Level) {
        "INFO" { Write-Host $Message -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
    }
}

# Screen Recording Functions
function Start-ScreenRecording {
    param(
        [string]$DeviceId,
        [string]$TestId
    )

    $recordingFile = "/sdcard/$TestId.mp4"
    Write-Log "Starting screen recording for test: $TestId" "INFO"

    # Start recording in background
    Start-Job -ScriptBlock {
        param($adbPath, $device, $file)
        & $adbPath -s $device shell screenrecord --time-limit 180 $file 2>&1 | Out-Null
    } -ArgumentList $global:ADB, $DeviceId, $recordingFile -Name "Recording_$TestId" | Out-Null

    Start-Sleep -Seconds 2  # Wait for recording to start
    return $recordingFile
}

function Stop-ScreenRecording {
    param(
        [string]$DeviceId,
        [string]$TestId,
        [string]$RemoteFile
    )

    Write-Log "Stopping screen recording for test: $TestId" "INFO"

    # Stop recording
    Stop-Job -Name "Recording_$TestId" -ErrorAction SilentlyContinue
    Remove-Job -Name "Recording_$TestId" -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2

    # Pull recording from device
    $localFile = Join-Path $RECORDINGS_DIR "$TestId.mp4"
    & $global:ADB -s $DeviceId pull $RemoteFile $localFile 2>&1 | Out-Null

    # Delete from device
    & $global:ADB -s $DeviceId shell rm $RemoteFile 2>&1 | Out-Null

    if (Test-Path $localFile) {
        Write-Log "Recording saved: $localFile" "SUCCESS"
        return $localFile
    } else {
        Write-Log "Failed to save recording for $TestId" "WARNING"
        return $null
    }
}

# Build APK function
function Build-APK {
    Write-Log "Building APK for testing..." "INFO"

    $buildOutput = flutter build apk --debug 2>&1
    $buildOutput | Out-File -Append -FilePath $LOG_FILE

    if ($LASTEXITCODE -eq 0) {
        Write-Log "[OK] APK built successfully" "SUCCESS"
        return $true
    } else {
        Write-Log "[FAIL] Failed to build APK" "ERROR"
        return $false
    }
}

# Detect APK location
function Find-APK {
    Write-Log "Searching for APK in project..." "INFO"

    $apkPaths = @(
        "build\app\outputs\flutter-apk\app-debug.apk",
        "build\app\outputs\flutter-apk\app-release.apk",
        "build\app\outputs\apk\debug\app-debug.apk",
        "build\app\outputs\apk\release\app-release.apk"
    )

    foreach ($path in $apkPaths) {
        if (Test-Path $path) {
            Write-Log "[OK] Found APK at: $path" "SUCCESS"
            return $path
        }
    }

    Write-Log "[WARNING] No APK found in standard locations" "WARNING"
    return $null
}

# Install APK on device
function Install-APK {
    param(
        [string]$DeviceId,
        [string]$ApkPath
    )

    if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
        Write-Log "[ERROR] APK not found at: $ApkPath" "ERROR"
        return $false
    }

    Write-Log "Installing APK on device $DeviceId..." "INFO"
    Write-Log "APK: $ApkPath" "INFO"

    $installOutput = & $global:ADB -s $DeviceId install -r $ApkPath 2>&1
    $installOutput | Out-File -Append -FilePath $LOG_FILE

    if ($LASTEXITCODE -eq 0) {
        Write-Log "[OK] APK installed successfully on $DeviceId" "SUCCESS"
        return $true
    } else {
        Write-Log "[FAIL] Failed to install APK on $DeviceId" "ERROR"
        Write-Log "Output: $installOutput" "ERROR"
        return $false
    }
}

# Launch app on device
function Launch-App {
    param(
        [string]$DeviceId,
        [string]$PackageName = "com.example.smart_hydroponic_app"
    )

    Write-Log "Launching app on device $DeviceId..." "INFO"

    # Launch app using monkey
    & $global:ADB -s $DeviceId shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
    Start-Sleep -Seconds 3

    Write-Log "[OK] App launched" "SUCCESS"
}

# Get device info
function Get-DeviceInfo {
    param([string]$DeviceId)

    try {
        $manufacturer = (& $global:ADB -s $DeviceId shell getprop ro.product.manufacturer 2>&1).Trim()
        $model = (& $global:ADB -s $DeviceId shell getprop ro.product.model 2>&1).Trim()
        $androidVersion = (& $global:ADB -s $DeviceId shell getprop ro.build.version.release 2>&1).Trim()

        return @{
            Manufacturer = $manufacturer
            Model = $model
            AndroidVersion = $androidVersion
        }
    } catch {
        return @{
            Manufacturer = "Unknown"
            Model = "Unknown"
            AndroidVersion = "Unknown"
        }
    }
}

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Flutter Automated Test Suite" -ForegroundColor Cyan
Write-Host " Hydroponic System" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Log "Test execution started at: $(Get-Date)" "INFO"
Write-Log "Test type: $TestType" "INFO"
Write-Log "Coverage enabled: $Coverage" "INFO"
Write-Log "Log file: $LOG_FILE" "INFO"
Write-Log "" "INFO"

# Check Flutter
Write-Log "Checking prerequisites..." "INFO"
try {
    $null = flutter --version 2>&1
    Write-Log "[OK] Flutter found" "SUCCESS"
} catch {
    Write-Log "[FAIL] Flutter not found. Please install Flutter SDK." "ERROR"
    exit 1
}

# Check ADB (use dynamically found path)
if ($global:ADB) {
    Write-Log "[OK] ADB found at: $global:ADB" "SUCCESS"
    $adbAvailable = $true
} else {
    Write-Log "[WARNING] ADB not found. Integration tests will be skipped." "WARNING"
    $adbAvailable = $false
}

# Check devices
if ($adbAvailable) {
    Write-Log "Checking for connected Android devices..." "INFO"
    $devices = & $global:ADB devices 2>&1 | Select-String -Pattern "device$"
    if ($devices.Count -eq 0) {
        Write-Log "No Android devices connected. Integration tests will be skipped." "WARNING"
    } else {
        Write-Log "Found $($devices.Count) device(s) connected" "SUCCESS"
    }
} else {
    $devices = @()
}

# Get dependencies
Write-Log "Getting Flutter dependencies..." "INFO"
$output = flutter pub get 2>&1
$output | Out-File -Append -FilePath $LOG_FILE
if ($LASTEXITCODE -eq 0) {
    Write-Log "[OK] Dependencies retrieved" "SUCCESS"
} else {
    Write-Log "[FAIL] Failed to get dependencies" "ERROR"
    exit 1
}

# Initialize counters
$totalPassed = 0
$totalFailed = 0
$testResults = @()
$deviceInfo = $null

# Run Unit Tests
if ($TestType -eq 'all' -or $TestType -eq 'unit') {
    Write-Log "" "INFO"
    Write-Log "========================================" "INFO"
    Write-Log "Running Unit Tests..." "INFO"
    Write-Log "========================================" "INFO"

    $unitTests = @(
        "test/viewmodels/login_viewmodel_test.dart",
        "test/models/sensor_data_test.dart",
        "test/utils/virtual_device_test.dart"
    )

    foreach ($test in $unitTests) {
        if (Test-Path $test) {
            Write-Log "Running $test..." "INFO"

            if ($Coverage) {
                $output = flutter test $test --coverage 2>&1
            } else {
                $output = flutter test $test 2>&1
            }

            $output | Out-File -Append -FilePath $LOG_FILE

            if ($LASTEXITCODE -eq 0) {
                Write-Log "[PASS] $test" "SUCCESS"
                $totalPassed++
                $status = "PASSED"
            } else {
                Write-Log "[FAIL] $test" "ERROR"
                $totalFailed++
                $status = "FAILED"
            }

            $testResults += @{
                Id = "unit_$(Split-Path $test -Leaf)"
                Name = (Split-Path $test -Leaf) -replace "_test.dart", ""
                Type = "Unit Test"
                Status = $status
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                VideoFile = $null
            }
        }
    }
}

# Run Widget Tests
if ($TestType -eq 'all' -or $TestType -eq 'widget') {
    Write-Log "" "INFO"
    Write-Log "========================================" "INFO"
    Write-Log "Running Widget Tests..." "INFO"
    Write-Log "========================================" "INFO"

    $widgetTests = @(
        "test/widgets/login_screen_test.dart"
    )

    foreach ($test in $widgetTests) {
        if (Test-Path $test) {
            Write-Log "Running $test..." "INFO"

            if ($Coverage) {
                $output = flutter test $test --coverage 2>&1
            } else {
                $output = flutter test $test 2>&1
            }

            $output | Out-File -Append -FilePath $LOG_FILE

            if ($LASTEXITCODE -eq 0) {
                Write-Log "[PASS] $test" "SUCCESS"
                $totalPassed++
                $status = "PASSED"
            } else {
                Write-Log "[FAIL] $test" "ERROR"
                $totalFailed++
                $status = "FAILED"
            }

            $testResults += @{
                Id = "widget_$(Split-Path $test -Leaf)"
                Name = (Split-Path $test -Leaf) -replace "_test.dart", ""
                Type = "Widget Test"
                Status = $status
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                VideoFile = $null
            }
        }
    }
}

# Run Integration Tests
if ($TestType -eq 'all' -or $TestType -eq 'integration') {
    Write-Log "" "INFO"
    Write-Log "========================================" "INFO"
    Write-Log "Running Integration Tests..." "INFO"
    Write-Log "========================================" "INFO"

    $integrationTests = @(
        #"integration_test/auth_flow_test.dart",
        "integration_test/comprehensive_auth_flow_test.dart"
        # NEW INTEGRATION TESTS - Uncomment to enable after local testing
        "integration_test/sensor_monitoring_flow_test.dart",
        "integration_test/actuator_control_flow_test.dart",
        "integration_test/analytics_history_flow_test.dart",
        "integration_test/alerts_notifications_flow_test.dart",
        "integration_test/settings_configuration_flow_test.dart",
        "integration_test/user_profile_flow_test.dart"
    )

    if ($DeviceId) {
        $selectedDevice = $DeviceId
    } elseif ($devices.Count -gt 0) {
        $selectedDevice = $devices[0].ToString().Split()[0]
    } else {
        Write-Log "No device available. Skipping integration tests." "WARNING"
        $selectedDevice = $null
    }

    if ($selectedDevice) {
        $deviceInfo = Get-DeviceInfo -DeviceId $selectedDevice
        Write-Log "Device: $($deviceInfo.Manufacturer) $($deviceInfo.Model) - Android $($deviceInfo.AndroidVersion)" "INFO"

        # Find and install APK
        Write-Log "" "INFO"
        Write-Log "========================================" "INFO"
        Write-Log "Preparing APK for Integration Tests..." "INFO"
        Write-Log "========================================" "INFO"

        $apkPath = Find-APK

        if (-not $apkPath) {
            Write-Log "APK not found. Building..." "WARNING"
            if (Build-APK) {
                $apkPath = Find-APK
            }
        }

        if (-not $apkPath) {
            Write-Log "Cannot find or build APK. Skipping integration tests." "ERROR"
        } else {
            # Install APK on device
            if (Install-APK -DeviceId $selectedDevice -ApkPath $apkPath) {
                Write-Log "Waiting for installation to complete..." "INFO"
                Start-Sleep -Seconds 3

                # Launch app
                Launch-App -DeviceId $selectedDevice

                Write-Log "" "INFO"
                Write-Log "========================================" "INFO"
                Write-Log "Running Integration Tests..." "INFO"
                Write-Log "========================================" "INFO"

                foreach ($test in $integrationTests) {
                    if (Test-Path $test) {
                        $testId = "integration_$(Split-Path $test -Leaf)"
                        Write-Log "Running $test on device $selectedDevice..." "INFO"

                        # Start background job to continuously grant permissions during test
                        # This handles flutter test reinstalling the app mid-test
                        $permissionJob = Start-Job -ScriptBlock {
                            param($adbPath, $device, $packageName)
                            $permissions = @(
                                "android.permission.POST_NOTIFICATIONS",
                                "android.permission.RECORD_AUDIO"
                            )
                            # Keep granting permissions for up to 5 minutes
                            for ($i = 0; $i -lt 60; $i++) {
                                foreach ($perm in $permissions) {
                                    try {
                                        & $adbPath -s $device shell pm grant $packageName $perm 2>&1 | Out-Null
                                    } catch { }
                                }
                                Start-Sleep -Seconds 5
                            }
                        } -ArgumentList $global:ADB, $selectedDevice, "com.example.smart_hydroponic_app" -Name "PermissionGrant_$testId"
                        
                        Write-Log "[OK] Permission grant background job started" "SUCCESS"

                        # Start screen recording
                        $recordingFile = Start-ScreenRecording -DeviceId $selectedDevice -TestId $testId

                        # Clear logcat
                        & $global:ADB -s $selectedDevice logcat -c 2>&1 | Out-Null

                        # Run test
                        $output = flutter test $test -d $selectedDevice 2>&1
                        $output | Out-File -Append -FilePath $LOG_FILE
                        
                        # Stop permission grant job
                        Stop-Job -Name "PermissionGrant_$testId" -ErrorAction SilentlyContinue
                        Remove-Job -Name "PermissionGrant_$testId" -ErrorAction SilentlyContinue

                        # Stop recording
                        $videoPath = Stop-ScreenRecording -DeviceId $selectedDevice -TestId $testId -RemoteFile $recordingFile

                        if ($LASTEXITCODE -eq 0) {
                            Write-Log "[PASS] $test" "SUCCESS"
                            $totalPassed++
                            $status = "PASSED"
                        } else {
                            Write-Log "[FAIL] $test" "ERROR"
                            $totalFailed++
                            $status = "FAILED"
                        }

                        $testResults += @{
                            Id = $testId
                            Name = (Split-Path $test -Leaf) -replace "_test.dart", ""
                            Type = "Integration Test"
                            Status = $status
                            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            VideoFile = if ($videoPath) { Split-Path $videoPath -Leaf } else { $null }
                        }
                    }
                }
            } else {
                Write-Log "No APK installed or build failed. Integration tests skipped." "WARNING"
            }
        }
    }
}

# Generate enhanced HTML report
$reportFile = Join-Path $LOG_DIR "test_report_$TIMESTAMP.html"
$deviceDisplay = if ($deviceInfo) { "$($deviceInfo.Manufacturer) $($deviceInfo.Model) - Android $($deviceInfo.AndroidVersion)" } else { "No device used" }
$overallStatus = if ($totalFailed -eq 0) { "PASSED" } else { "FAILED" }
$statusColor = if ($totalFailed -eq 0) { "#4CAF50" } else { "#f44336" }

$unitTests = $testResults | Where-Object { $_.Type -in @("Unit Test", "Widget Test") }
$integrationTests = $testResults | Where-Object { $_.Type -eq "Integration Test" }

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Report - $TIMESTAMP</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 30px;
        }
        .info-section {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .info-section p {
            margin: 5px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th {
            background-color: #3498db;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: bold;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .status-passed {
            color: #27ae60;
            font-weight: bold;
        }
        .status-failed {
            color: #e74c3c;
            font-weight: bold;
        }
        .video-link {
            color: #3498db;
            text-decoration: none;
        }
        .video-link:hover {
            text-decoration: underline;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
            gap: 15px;
        }
        .summary-box {
            padding: 20px;
            border-radius: 5px;
            text-align: center;
            flex: 1;
        }
        .summary-box h3 {
            margin: 0 0 10px 0;
            font-size: 14px;
            text-transform: uppercase;
        }
        .summary-box .number {
            font-size: 36px;
            font-weight: bold;
        }
        .total-box {
            background-color: #3498db;
            color: white;
        }
        .passed-box {
            background-color: #27ae60;
            color: white;
        }
        .failed-box {
            background-color: #e74c3c;
            color: white;
        }
        .type-badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 3px;
            font-size: 11px;
            font-weight: bold;
            text-transform: uppercase;
        }
        .badge-unit {
            background-color: #9b59b6;
            color: white;
        }
        .badge-widget {
            background-color: #16a085;
            color: white;
        }
        .badge-integration {
            background-color: #e67e22;
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Automated Test Report - SMART Hydroponic System</h1>

        <div class="info-section">
            <h2>Test Environment</h2>
            <p><strong>Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Device:</strong> $deviceDisplay</p>
            <p><strong>Test Type:</strong> $TestType</p>
            <p><strong>Coverage Enabled:</strong> $Coverage</p>
            <p><strong>Log File:</strong> $LOG_FILE</p>
        </div>

        <div class="summary">
            <div class="summary-box total-box">
                <h3>Total Tests</h3>
                <div class="number">$($testResults.Count)</div>
            </div>
            <div class="summary-box passed-box">
                <h3>Passed</h3>
                <div class="number">$totalPassed</div>
            </div>
            <div class="summary-box failed-box">
                <h3>Failed</h3>
                <div class="number">$totalFailed</div>
            </div>
        </div>

        <h2>Unit & Widget Tests ($($unitTests.Count))</h2>
        <table>
            <thead>
                <tr>
                    <th>Test ID</th>
                    <th>Test Name</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Timestamp</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($result in $unitTests) {
    $statusClass = if ($result.Status -eq "PASSED") { "status-passed" } else { "status-failed" }
    $badgeClass = if ($result.Type -eq "Unit Test") { "badge-unit" } else { "badge-widget" }

    $html += @"
                <tr>
                    <td>$($result.Id)</td>
                    <td>$($result.Name)</td>
                    <td><span class="type-badge $badgeClass">$($result.Type)</span></td>
                    <td class="$statusClass">$($result.Status)</td>
                    <td>$($result.Timestamp)</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>

        <h2>Integration Tests with Recordings ($($integrationTests.Count))</h2>
        <table>
            <thead>
                <tr>
                    <th>Test ID</th>
                    <th>Test Name</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Timestamp</th>
                    <th>Recording</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($result in $integrationTests) {
    $statusClass = if ($result.Status -eq "PASSED") { "status-passed" } else { "status-failed" }
    $videoLink = if ($result.VideoFile) {
        "<a href='recordings/$($result.VideoFile)' class='video-link' target='_blank'>&#128249; View Recording</a>"
    } else {
        "N/A"
    }

    $html += @"
                <tr>
                    <td>$($result.Id)</td>
                    <td>$($result.Name)</td>
                    <td><span class="type-badge badge-integration">$($result.Type)</span></td>
                    <td class="$statusClass">$($result.Status)</td>
                    <td>$($result.Timestamp)</td>
                    <td>$videoLink</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>

        <div style="margin-top: 30px; padding: 15px; background-color: #ecf0f1; border-radius: 5px;">
            <h3>Test Files</h3>
            <ul>
                <li><strong>Unit Tests:</strong> Located in <code>test/</code> folder</li>
                <li><strong>Integration Tests:</strong> Located in <code>integration_test/</code> folder</li>
                <li><strong>Recordings:</strong> Integration test recordings saved in <code>$RECORDINGS_DIR</code></li>
                <li><strong>Logs:</strong> Complete test logs available in log file</li>
            </ul>
        </div>
    </div>
</body>
</html>
"@

$html | Out-File -FilePath $reportFile -Encoding UTF8
Write-Log "[OK] Enhanced test report generated: $reportFile" "SUCCESS"

# Summary
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "TEST EXECUTION COMPLETED" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Total Passed: $totalPassed" "SUCCESS"
if ($totalFailed -gt 0) {
    Write-Log "Total Failed: $totalFailed" "ERROR"
}
Write-Log "" "INFO"
Write-Log "Detailed logs: $LOG_FILE" "INFO"
Write-Log "HTML Report: $reportFile" "INFO"

# Open report
try {
    Start-Process $reportFile
} catch {
    Write-Log "Could not open report automatically" "WARNING"
}

# Exit
if ($totalFailed -gt 0) {
    exit 1
} else {
    exit 0
}
