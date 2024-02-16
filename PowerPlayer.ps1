$SW_HIDE, $SW_SHOW = 0, 5
$TypeDef='[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $TypeDef -Namespace Win32 -Name Functions
$hWnd=(Get-Process -Id $PID).MainWindowHandle
$Null=[Win32.Functions]::ShowWindow($hWnd,$SW_HIDE)
$global:Playing=0
$global:tracking=0
$global:icurrent=-1
function Update-Gui{
	$window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}
function dropDownMenu(){
	Switch($MenuFile.Visibility){
		'Visible'{
			$MenuMain.BorderBrush='#111111'
			$MenuFile.Visibility='Collapsed'
			$MenuFolder.Visibility='Collapsed'
			$MenuExit.Visibility='Collapsed'
		}
		'Collapsed'{
			$MenuMain.BorderBrush='#CCCCCC'
			$MenuFile.Visibility='Visible'
			$MenuFolder.Visibility='Visible'
			$MenuExit.Visibility='Visible'
		}
	}
}
function TogglePlayButton(){
	if($files -ne $null){
		Switch($global:Playing){
			0{
				$PlayImage.Source='.\resources\Pause.png'
				$mediaPlayer.Play()
				$global:Playing=1
				$StatusInfo.Text="Now Playing:"
				$BG.Play()
			}
			1{
				$PlayImage.Source='.\resources\Play.png'
				$mediaPlayer.Pause()
				$global:Playing=0
				$StatusInfo.Text="Paused:"
				$BG.Pause()
			}
		}
	}
}
function NextTrack(){
	if($icurrent -lt $files.Length - 1){
	$global:icurrent++
	$file = $files[$icurrent]
	PlayTrack
	}
}
function PrevTrack(){
	if($icurrent -ge 1){
	$global:icurrent--
	$file = $files[$icurrent]
	PlayTrack
	}
}
function trackLength(){
	$Shell = New-Object -COMObject Shell.Application
	$FolderL = $shell.Namespace($(Split-Path $FullName))
	$FileL = $FolderL.ParseName($(Split-Path $FullName -Leaf))
	[int]$h, [int]$m, [int]$s = ($FolderL.GetDetailsOf($FileL, 27)).split(":")
	$global:totaltime=$h*60*60 + $m*60 +$s
	$ReadableTotal=[timespan]::fromseconds($totaltime - 2)
	$TimerB.Text=("{0:mm\:ss}" -f $ReadableTotal)
	$global:PositionSlider.Maximum=$totaltime
}
function WaitForSong(){
	while(([Math]::Ceiling(([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds)) -lt ([ref] $script:totaltime).Value){
		if(([ref] $script:tracking).Value -eq 0){
			$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
			$TimePassed=[timespan]::fromseconds(([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds)
			$TimerA.Text=("{0:mm\:ss}" -f $TimePassed)
		}
		Update-Gui
		Start-Sleep -milliseconds 50
	}
}
function PlayTrack(){
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$FullName="$path\$file"
	$mediaPlayer.open($FullName)
	$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	$mediaPlayer.Play()
	trackLength
	WaitForSong	
}
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration, presentationCore
[xml]$xaml='
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="PowerPlayer" Height="180" Width="300" WindowStyle="None" AllowsTransparency="True" Background="Transparent" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Border CornerRadius="5" BorderBrush="#111111" BorderThickness="10" Background="#111111">
        <Grid Name="MainWindow">
			<MediaElement Name="BG" Height="160" Width="280" LoadedBehavior="Manual" Stretch="Fill" SpeedRatio="1" IsMuted="True"/>
            <Canvas>
                <TextBlock Canvas.Left="32" Canvas.Top="40" Foreground="#CCCCCC">
					<TextBlock.Inlines>
						<Run Name="Status" FontStyle="Italic"/>
					</TextBlock.Inlines>
				</TextBlock>
                <TextBlock Name="CurrentTrack" Canvas.Top="69" Foreground="#CCCCCC" FontSize="12" FontWeight="Bold" Text="No Media Loaded" TextAlignment="Center" Width="280"/>
                <Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="50">Menu</Button>
                <Button Name="minWin" Canvas.Left="236" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22">___</Button>
                <Button Name="X" Canvas.Left="258" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22" FontWeight="Bold">X</Button>
                <Button Name="File" Canvas.Left="0" Canvas.Top="17" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Open File</Button>
                <Button Name="Folder" Canvas.Left="0" Canvas.Top="34" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Open Folder</Button>
                <Button Name="Exit" Canvas.Left="0" Canvas.Top="51" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Exit</Button>
                <Button Name="Prev" Canvas.Left="39" Canvas.Top="119" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PrevButton" Height="23" Width="40"></Image>
                </Button>
                <Button Name="Play" Canvas.Left="116" Canvas.Top="119" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PlayButton" Height="23" Width="50"></Image>
                </Button>
                <Button Name="Next" Canvas.Left="199" Canvas.Top="119" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="NextButton" Height="23" Width="40"></Image>
                </Button>
                <Slider Name="Volume" Canvas.Left="179" Canvas.Top="45" Height="6" Width="60" Orientation="Horizontal" Minimum="0" Maximum="1" SmallChange=".01" LargeChange=".1" Background="#728FCE" Opacity="0.9" />
                <Slider Name="Position" Canvas.Left="54" Canvas.Top="100" Height="6" Width="173" Orientation="Horizontal" Minimum="0" Maximum="1" Background="#728FCE" Opacity="0.9" />
                <TextBlock Name="TimerA" Canvas.Left="18" Canvas.Top="95" Foreground="#CCCCCC" FontWeight="Bold"/>
                <TextBlock Name="TimerB" Canvas.Left="233" Canvas.Top="95" Foreground="#CCCCCC" FontWeight="Bold"/>
            </Canvas>
        </Grid>
    </Border>
    <Window.TaskbarItemInfo>
        <TaskbarItemInfo/>
    </Window.TaskbarItemInfo>
</Window>'
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$window=[Windows.Markup.XamlReader]::Load($reader)
$window.Title='PowerPlayer'
$mediaPlayer=New-Object system.windows.media.mediaplayer
$mediaPlayer.Add_MediaEnded({
	$mediaPlayer.Stop()
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
	$PlayImage.Source='.\resources\Play.png'
	$CurrentTrack.Text='No Media Loaded'
	$BG.Stop()
	$global:Playing=0
	$global:icurrent=-1
	$StatusInfo.Text=''
	$TimerA.Text=''
	$TimerB.Text=''	
})
$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})
$VolumeSlider=$Window.FindName("Volume")
$VolumeSlider.Value=$mediaPlayer.Volume
$VolumeSlider.Add_PreviewMouseUp({
	$mediaPlayer.Volume=$VolumeSlider.Value
})
$PositionSlider=$Window.FindName("Position")
$PositionSlider.Add_PreviewMouseUp({
	$mediaPlayer.Position=("{0:hh\:mm\:ss\.fff}" -f ([timespan]::fromseconds([Math]::Truncate($PositionSlider.Value))))
	$global:tracking=0
})
$PositionSlider.Add_PreviewMouseDown({
	$global:tracking=1
})
$BG=$Window.FindName("BG")
$FullBGPath=[IO.Path]::GetFullPath(".\resources\bg.gif")
$BG.Source=$FullBGPath
$BG.Add_MediaEnded({
	$BG.Stop()
	$BG.Position=New-Object System.TimeSpan(0, 0, 0, 0, 1)
	$BG.Play()
})
$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap=$BG.Source
$window.Icon=$bitmap
$window.TaskbarItemInfo.Overlay=$bitmap
$window.TaskbarItemInfo.Description=$window.Title
$window.add_MouseLeftButtonDown({
$window.DragMove()
})
$StatusInfo=$Window.FindName("Status")
$StatusInfo.Text=''
$CurrentTrack=$Window.FindName("CurrentTrack")
$TimerA=$Window.FindName("TimerA")
$TimerB=$Window.FindName("TimerB")
$MenuMain=$Window.FindName("Menu")
$MenuMain.Add_MouseEnter({
	$MenuMain.Background="#CCCCCC"
	$MenuMain.Foreground="#111111"
})
$MenuMain.Add_MouseLeave({
	$MenuMain.Background="#111111"
	$MenuMain.Foreground="#CCCCCC"
})
$MenuMain.Add_Click({
	dropDownMenu
})
$MenuFile=$Window.FindName("File")
$MenuFile.Add_MouseEnter({
	$MenuFile.Background="#CCCCCC"
	$MenuFile.Foreground="#111111"
})
$MenuFile.Add_MouseLeave({
	$MenuFile.Background="#111111"
	$MenuFile.Foreground="#CCCCCC"
})
$MenuFile.Add_Click({
	dropDownMenu
	$getFile=New-Object System.Windows.Forms.OpenFileDialog -Property @{
		InitialDirectory="$env:UserProfile\Music"
		Title='Select a MP3 file...'
		Filter='MP3 (*.mp3)|*.mp3'
	}
	$filePicker=$getFile.ShowDialog()
	$file=$getFile.Filename
	if($filePicker -ne [System.Windows.Forms.DialogResult]::Cancel){
		$path = Split-Path $file -Parent
		$path = $path+'\'
		$files=@()
		$files+=Split-Path $file -leaf
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
		TogglePlayButton
		NextTrack
	}
})
$MenuFolder=$Window.FindName("Folder")
$MenuFolder.Add_MouseEnter({
	$MenuFolder.Background="#CCCCCC"
	$MenuFolder.Foreground="#111111"
})
$MenuFolder.Add_MouseLeave({
	$MenuFolder.Background="#111111"
	$MenuFolder.Foreground="#CCCCCC"
})
$MenuFolder.Add_Click({
	dropDownMenu
	$AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
	$Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
	$OpenFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
	$OpenFileDialog.AddExtension = $false
	$OpenFileDialog.CheckFileExists = $false
	$OpenFileDialog.DereferenceLinks = $true
	$OpenFileDialog.Filter = "Folders|`n"
	$OpenFileDialog.Multiselect = $false
	$OpenFileDialog.Title = "Select a Folder"
	$OpenFileDialog.InitialDirectory="$env:UserProfile\Music"
	$OpenFileDialogType = $OpenFileDialog.GetType()
	$FileDialogInterfaceType = $Assembly.GetType('System.Windows.Forms.FileDialogNative+IFileDialog')
	$IFileDialog = $OpenFileDialogType.GetMethod('CreateVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null)
	$OpenFileDialogType.GetMethod('OnBeforeVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$IFileDialog)
	[uint32]$PickFoldersOption = $Assembly.GetType('System.Windows.Forms.FileDialogNative+FOS').GetField('FOS_PICKFOLDERS').GetValue($null)
	$FolderOptions = $OpenFileDialogType.GetMethod('get_Options',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null) -bor $PickFoldersOption
	$FileDialogInterfaceType.GetMethod('SetOptions',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$FolderOptions)
	$VistaDialogEvent = [System.Activator]::CreateInstance($AssemblyFullName,'System.Windows.Forms.FileDialog+VistaDialogEvents',$false,0,$null,$OpenFileDialog,$null,$null).Unwrap()
	[uint32]$AdviceCookie = 0
	$AdvisoryParameters = @($VistaDialogEvent,$AdviceCookie)
	$AdviseResult = $FileDialogInterfaceType.GetMethod('Advise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdvisoryParameters)
	$AdviceCookie = $AdvisoryParameters[1]
	$Result = $FileDialogInterfaceType.GetMethod('Show',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,[System.IntPtr]::Zero)
	$FileDialogInterfaceType.GetMethod('Unadvise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdviceCookie)
	if ($Result -ne [System.Windows.Forms.DialogResult]::Cancel) {
		$FileDialogInterfaceType.GetMethod('GetResult',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$null)
		$path = $OpenFileDialog.FileName+'\'
		$files=@()
		Get-ChildItem -Path $path -Filter *.mp3 -File -Name| ForEach-Object {
			$files+=$_
		}
		TogglePlayButton
		while(([ref] $script:icurrent).Value -lt $files.Length - 1){
			NextTrack
		}
	}
})
$MenuExit=$Window.FindName("Exit")
$MenuExit.Add_MouseEnter({
	$MenuExit.Background="#CCCCCC"
	$MenuExit.Foreground="#111111"
})
$MenuExit.Add_MouseLeave({
	$MenuExit.Background="#111111"
	$MenuExit.Foreground="#CCCCCC"
})
$MenuExit.Add_Click({
	Exit
})
$minWin=$Window.FindName("minWin")
$minWin.Add_MouseEnter({
	$minWin.Background="#CCCCCC"
	$minWin.Foreground="#111111"
})
$minWin.Add_MouseLeave({
	$minWin.Background="#111111"
	$minWin.Foreground="#CCCCCC"
})
$minWin.Add_Click({
	$Window.WindowState='Minimized'
})
$Xbutton=$Window.FindName("X")
$Xbutton.Add_MouseEnter({
	$Xbutton.Background="#CCCCCC"
	$Xbutton.Foreground="#ff0000"
})
$Xbutton.Add_MouseLeave({
	$Xbutton.Background="#111111"
	$Xbutton.Foreground="#CCCCCC"
})
$Xbutton.Add_Click({
	Exit
})
$Prev=$Window.FindName("Prev")
$PrevImage=$Window.FindName("PrevButton")
$PrevImage.Source='.\resources\Prev.png'
$Prev.Add_Click({
	$checkposition=$mediaPlayer.Position.ToString()
	[int]$checkposition=$checkposition.Replace("(?=[.]).*",'').Replace(':','')
		if($global:Playing -eq 0){
			if($icurrent -ge 1){
			$global:icurrent--
			$file = $files[$icurrent]
			$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
			$FullName="$path\$file"
			$mediaPlayer.open($FullName)
			$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
			trackLength
			WaitForSong	
			}			
		} else {
		if($checkposition -le 2){
			PrevTrack
		} else {
			$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		}
	}
})
$Play=$Window.FindName("Play")
$PlayImage=$Window.FindName("PlayButton")
$PlayImage.Source='.\resources\Play.png'
$Play.Add_Click({
	TogglePlayButton
})
$Next=$Window.FindName("Next")
$NextImage=$Window.FindName("NextButton")
$NextImage.Source='.\resources\Next.png'
$Next.Add_Click({
	if($global:Playing -eq 0){
		if($icurrent -lt $files.Length - 1){
		$global:icurrent++
		$file = $files[$icurrent]
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$FullName="$path\$file"
		$mediaPlayer.open($FullName)
		$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
		trackLength
		WaitForSong	
		}
	} else {
		NextTrack
	}
})
$BG.Play()
$window.Show()
$BG.Pause()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)