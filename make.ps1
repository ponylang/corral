Param(
  [Parameter(Position=0, HelpMessage="The action to take (build, test, buildtest, install, package, clean).")]
  [string]
  $Command = 'build',

  [Parameter(HelpMessage="The build configuration (Release, Debug).")]
  [string]
  $Config = "Release",

  [Parameter(HelpMessage="The version number to set.")]
  [string]
  $Version = "",

  [Parameter(HelpMessage="The architecture to use for compiling, e.g. `"X64`", `"Arm64`"")]
  [string]
  $Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture,

  [Parameter(HelpMessage="Directory to install to.")]
  [string]
  $Destdir = "build/install"
)

if ($Arch -ieq 'x64')
{
  $Arch = 'x86-64'
  $CPU = 'x86-64'
}
elseif ($Arch -ieq 'arm64')
{
  $Arch = 'arm64'
  $CPU = 'generic'
}

$ErrorActionPreference = "Stop"

$rootDir = Split-Path $script:MyInvocation.MyCommand.Path
$srcDir = Join-Path -Path $rootDir -ChildPath "corral"

if ($Config -ieq "Release")
{
  $configFlag = ""
  $buildDir = Join-Path -Path $rootDir -ChildPath "build/release"
}
elseif ($Config -ieq "Debug")
{
  $configFlag = "--debug"
  $buildDir = Join-Path -Path $rootDir -ChildPath "build/debug"
}
else
{
  throw "Invalid -Config path '$Config'; must be one of (Debug, Release)."
}

if ($Version -eq "")
{
  $Version = (Get-Content "$rootDir\VERSION") + "-" + (git rev-parse --short --verify HEAD^)
}

Write-Output "Configuration:    $Config"
Write-Output "Version:          $Version"
Write-Output "Root directory:   $rootDir"
Write-Output "Source directory: $srcDir"
Write-Output "Build directory:  $buildDir"

# generate pony templated files if necessary
if ($Command -ne "clean")
{
  $versionTimestamp = (Get-ChildItem -Path "$rootDir\VERSION").LastWriteTimeUtc
  Get-ChildItem -Path $srcDir -Include "*.pony.in" -Recurse | ForEach-Object {
    $templateFile = $_.FullName
    $ponyFile = $templateFile.Substring(0, $templateFile.Length - 3)
    $ponyFileTimestamp = [DateTime]::MinValue
    if (Test-Path $ponyFile)
    {
      $ponyFileTimestamp = (Get-ChildItem -Path $ponyFile).LastWriteTimeUtc
    }
    if (($ponyFileTimestamp -lt $versionTimestamp) -or ($ponyFileTimestamp -lt $_.LastWriteTimeUtc))
    {
      Write-Output "$templateFile -> $ponyFile"
      ((Get-Content -Path $templateFile) -replace '%%VERSION%%', $Version) | Set-Content -Path $ponyFile
    }
  }
}

function BuildCorral
{
  $binaryFile = Join-Path -Path $buildDir -ChildPath "corral.exe"
  $binaryTimestamp = [DateTime]::MinValue
  if (Test-Path $binaryFile)
  {
    $binaryTimestamp = (Get-ChildItem -Path $binaryFile).LastWriteTimeUtc
  }

  :buildFiles foreach ($file in (Get-ChildItem -Path $srcDir -Include "*.pony" -Recurse))
  {
    if ($binaryTimestamp -lt $file.LastWriteTimeUtc)
    {
      ponyc "$configFlag" --cpu "$CPU" --output "$buildDir" "$srcDir"
      break buildFiles
    }
  }
}

function BuildTest
{
  $testFile = Join-Path -Path $buildDir -ChildPath "test.exe"
  $testTimestamp = [DateTime]::MinValue
  if (Test-Path $testFile)
  {
    $testTimestamp = (Get-ChildItem -Path $testFile).LastWriteTimeUtc
  }

  :testFiles foreach ($file in (Get-ChildItem -Path $srcDir -Include "*.pony" -Recurse))
  {
    if ($testTimestamp -lt $file.LastWriteTimeUtc)
    {
      $testDir = Join-Path -Path $srcDir -ChildPath "test"
      Write-Output "ponyc `"$configFlag`" --cpu `"$CPU`" --output `"$buildDir`" --bin-name `"test`" `"$testDir`""
      ponyc "$configFlag" --cpu "$CPU" --output "$buildDir" --bin-name test "$testDir"
      break testFiles
    }
  }

  Write-Output "test.exe is built"
  return $testFile
}

switch ($Command.ToLower())
{
  "build"
  {
    BuildCorral
    break
  }

  "buildtest"
  {
    BuildTest
    break
  }

  "test"
  {
    BuildCorral
    $testFile = (BuildTest)[-1]

    & "$testFile" --exclude=integration --sequential

    $env:CORRAL_BIN = Join-Path -Path $buildDir -ChildPath "corral.exe"
    & "$testFile" --only=integration --sequential
    break
  }

  "unit-tests"
  {
    BuildCorral
    $testFile = (BuildTest)[-1]

    & "$testFile" --exclude=integration --sequential
    break
  }

  "integration-tests"
  {
    BuildCorral
    $testFile = (BuildTest)[-1]

    $env:CORRAL_BIN = Join-Path -Path $buildDir -ChildPath "corral.exe"
    & "$testFile" --only=integration --sequential
    break
  }

  "clean"
  {
    if (Test-Path "$buildDir")
    {
      Remove-Item -Path "$buildDir" -Recurse -Force
    }
    break
  }

  "install"
  {
    $binDir = Join-Path -Path $Destdir -ChildPath "bin"

    if (-not (Test-Path $binDir))
    {
      mkdir "$binDir"
    }

    $corral = Join-Path -Path $buildDir -ChildPath "corral.exe"
    Copy-Item -Path $corral -Destination $binDir -Force
    break
  }

  "package"
  {
    $binDir = Join-Path -Path $Destdir -ChildPath "bin"
    $package = "corral-$Arch-pc-windows-msvc.zip"
    Write-Output "Creating $package..."

    Compress-Archive -Path $binDir -DestinationPath "$buildDir\..\$package" -Force
    break
  }

  default
  {
    throw "Unknown command '$Command'; must be one of (build, test, buildtest, install, package, clean)"
  }
}
