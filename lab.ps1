param(
    [ValidateSet('install','start','stop','test','capture','erp','mgmt','branch','deny','status','wan','tunnel','log','revoke','restore')]
    [string]$Action = 'status',
    [string]$Distro = 'Ubuntu-24.04'
)
$ErrorActionPreference = 'Stop'
$linuxPath = (& wsl.exe -d $Distro -- wslpath -a $PSScriptRoot).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Cannot locate repo in WSL. Check distro name and WSL installation.' }
$scripts = @{install='install.sh'; start='start-lab.sh'; stop='stop-lab.sh'; test='test-lab.sh'; capture='test-capture.sh'; revoke='revoke-br2.sh'; restore='restore-br2.sh'}
if ($scripts.ContainsKey($Action)) {
    & wsl.exe -d $Distro -u root -- bash "$linuxPath/scripts/$($scripts[$Action])"
} else {
    & wsl.exe -d $Distro -u root -- bash "$linuxPath/scripts/demo.sh" $Action
}
exit $LASTEXITCODE
