# file    : babun.ps1
# author  : seb! <sebi@sebi.one.pl>
# license : MIT

# This script:
# * downloads babun from official website.
# * unzip downloaded archive within user profile environment.
# * locates babun installation batch file.
# * makes a very silent installer for vagrant environment:
#   - every 'pause' command is removed,
#   - babun is not started just after installation.
#   It is required for provisioning babun well.
# * runs the modified babun installation batch file.
# * updates babun immediately after installation.
# * registers mintty.exe as VPN connection trigger.

$babunPath = Join-Path $env:USERPROFILE ".babun"
$babunHome = Join-Path $babunPath "cygwin\home\vagrant"

if (-Not (Test-Path ($babunPath)))
{
    $getFrom = 'http://projects.reficio.org/babun/download'
    $putTo   = Join-Path $env:LOCALAPPDATA 'Temp/babun'

    Start-BitsTransfer -Source $getFrom -Destination $putTo'.zip'
    unzip -o $putTo'.zip' -d $putTo

    $setup  = Get-ChildItem -Path $putTo -Recurse -Filter install.bat |
        Select-Object -First 1

    $silent = Join-Path $setup.Directory "silent-$($setup.Name)"
    $update = Join-Path $babunPath "update.bat"

    Get-Content        $setup.FullName |
        Select-String -Pattern 'babun.bat', 'pause' -NotMatch |
        Out-File      -Encoding ascii -Force $silent

    Start-Process $silent -NoNewWindow -PassThru -Wait

    git -C $babunHome init
    git -C $babunHome config user.name seb\!
    git -C $babunHome config user.email sebi@sebi.one.pl
    git -C $babunHome remote add matrix http://192.168.99.100:8082/sebi/my-babun.git
    git -C $babunHome fetch --all
    git -C $babunHome checkout --force BARBAKAN-10-V
    git -C $babunHome reset --hard HEAD
    git -C $babunHome submodule update --init --recursive

    Start-Process $update -NoNewWindow -PassThru -Wait

    Get-VpnConnection |
       % {
            Add-VpnConnectionTriggerApplication                         `
                  -ConnectionName $_.Name                               `
                  -ApplicationID  "$babunPath\cygwin\bin\mintty.exe"
       }
}
