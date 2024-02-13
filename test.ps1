$global:totaltime=20
function WaitForSong(){
	$meter=(Get-Date).ToString("ss")
	:waiting while($true){
		if($meter -ne (Get-Date).ToString("ss")){
			$meter=(Get-Date).ToString("ss")
			$totaltime--
		}
		write-host $totaltime
		Start-Sleep -milliseconds 50
		if($totaltime -le .01){
			break waiting
		}
	}
}
WaitForSong
Write-Host Done
cmd /c pause