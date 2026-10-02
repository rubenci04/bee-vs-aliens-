param([string]$ReviewDir = 'dev/audio_basic_review')
$beeGodot = 'C:\Users\rea_0\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$beeRoot = 'D:\proyectos\bee_alien_3d'
Set-Location -LiteralPath $beeRoot
$beeTests = @(Get-ChildItem tests -Recurse -Filter 'validate*.gd' | Sort-Object FullName)
$beeResults = @()
foreach ($beeTest in $beeTests) {
    $beeRelative = $beeTest.FullName.Substring($beeRoot.Length + 1).Replace('\','/')
    $beeOutput = & $beeGodot --headless --path $beeRoot --script ('res://' + $beeRelative) 2>&1
    $beeCode = $LASTEXITCODE
    $beeText = ($beeOutput | Out-String)
    $beeOutput | Set-Content -LiteralPath ($ReviewDir + '/suite_' + $beeTest.BaseName + '.log')
    $beePass = $beeCode -eq 0 -and $beeText -notmatch 'SCRIPT ERROR|ERROR:|(^|\n)FAIL'
    $beeResults += [pscustomobject]@{test=$beeRelative;exit=$beeCode;pass=$beePass}
    Write-Output (($beeResults.Count.ToString() + '/' + $beeTests.Count.ToString()) + ' ' + $(if ($beePass) {'PASS'} else {'FAIL'}) + ' ' + $beeTest.BaseName)
}
$beeResults | ConvertTo-Json | Set-Content -LiteralPath ($ReviewDir + '/suite_results.json')
$beePassed = @($beeResults | Where-Object pass).Count
Write-Output ('BEE_SUITE ' + $beePassed + '/' + $beeTests.Count)
if ($beePassed -ne $beeTests.Count) { exit 1 }
exit 0
