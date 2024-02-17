$TypeDef='[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $TypeDef -Namespace Win32 -Name Functions
$hWnd=(Get-Process -Id $PID).MainWindowHandle
$Null=[Win32.Functions]::ShowWindow($hWnd,0)
$resourcepath=$env:ProgramData + '\PowerPlayer\'
function updateResources(){
	$ProgressPreference='SilentlyContinue'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/bg.gif -o $resourcepath'bg.gif'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Muted.png -o $resourcepath'Muted.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Next.png -o $resourcepath'Next.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Pause.png -o $resourcepath'Pause.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Play.png -o $resourcepath'Play.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Prev.png -o $resourcepath'Prev.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/RepeatAll.png -o $resourcepath'RepeatAll.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/RepeatOne.png -o $resourcepath'RepeatOne.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/Shuffle.png -o $resourcepath'Shuffle.png'
	irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/UnMuted.png -o $resourcepath'UnMuted.png'
	$ProgressPreference='Continue'
}
if(!(Test-Path -Path $resourcepath)){
	if(Test-Path -Path '.\resources'){
		New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
		Copy-Item -Path '.\resources\bg.gif' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Muted.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Next.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Pause.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Play.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Prev.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\RepeatAll.png' -Destination $resourcepath -Force 
		Copy-Item -Path '.\resources\RepeatOne.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\Shuffle.png' -Destination $resourcepath -Force
		Copy-Item -Path '.\resources\UnMuted.png' -Destination $resourcepath -Force
	} else {
		$FirstRun=New-Object -ComObject Wscript.Shell;$FirstRun.Popup("Click OK to download ~2mb of resources from the projects resources folder on GitHub. They will be stored in:`n`n" + $resourcepath + "`n`nOr press Cancel to Quit",0,'GUI Resources are missing!',0x1) | Tee-Object -Variable GetButtons
		if($GetButtons -eq 1){
			New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
			updateResources
		}
	}
} else {
$ctrlkey = '0x11'
$CheckCtrlHeldAtLaunch=@'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
	Add-Type -MemberDefinition $CheckCtrlHeldAtLaunch -Name Keyboard -Namespace PsOneApi
	if([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($ctrlkey) -eq -32767)){ 
		$FirstRun=New-Object -ComObject Wscript.Shell;$FirstRun.Popup("Would you like to retrieve the latest PowerPlayer resources from Github?",0,'Update Mode Initialized',0x1) | Tee-Object -Variable GetButtons
		if($GetButtons -eq 1){
			Remove-Item -Path $resourcepath -Recurse -Force
			New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
			updateResources
			irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/PowerPlayer.ps1 -o '.\PowerPlayer.ps1'
			. $PSCommandPath
			Exit
		}
	}	
}
$global:Playing=0
$global:Repeating=0
$global:ShuffleOn=0
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
			$MenuMain.BorderBrush='#333333'
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
				$PlayImage.Source=$resourcepath + 'Pause.png'
				$mediaPlayer.Play()
				$global:Playing=1
				$StatusInfo.Text="Now Playing:"
				$BG.Play()
			}
			1{
				$PlayImage.Source=$resourcepath + 'Play.png'
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
		if(!($global:Repeating -eq 1)){
			$global:icurrent++
		}
		if($global:ShuffleOn -eq 0){
			$file = $files[$icurrent]
		} else {
			$file = $filesShuffled[$icurrent]
		}
		PlayTrack	
	} else {
		$global:icurrent=0
		if($global:ShuffleOn -eq 0){
			$file = $files[$icurrent]
		} else {
			$file = $filesShuffled[$icurrent]
		}
		PlayTrack	
	}
}
function PrevTrack(){
	if($icurrent -ge 1){
		if(!($global:Repeating -eq 1)){
			$global:icurrent--
		}
		if($global:ShuffleOn -eq 0){
			$file = $files[$icurrent]
		} else {
			$file = $filesShuffled[$icurrent]
		}		
		PlayTrack
	} else {
		if($global:Repeating -eq 2){
			$global:icurrent=$files.Length - 1
			if($global:ShuffleOn -eq 0){
				$file = $files[$icurrent]
			} else {
				$file = $filesShuffled[$icurrent]
			}
			PlayTrack	
		}
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
		Title="PowerPlayer" Height="300" Width="500" WindowStyle="None" AllowsTransparency="True" Background="Transparent" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
	<Window.Resources>
		<ControlTemplate x:Key="NoMouseOverButtonTemplate" TargetType="Button">
			<Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
				<ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
			</Border>
			<ControlTemplate.Triggers>
				<Trigger Property="IsEnabled" Value="False">
					<Setter Property="Background" Value="{x:Static SystemColors.ControlLightBrush}"/>
					<Setter Property="Foreground" Value="{x:Static SystemColors.GrayTextBrush}"/>
				</Trigger>
			</ControlTemplate.Triggers>
		</ControlTemplate>
	</Window.Resources>
    <Border CornerRadius="5" BorderBrush="#111111" BorderThickness="10" Background="#111111">
        <Grid Name="MainWindow">
			<MediaElement Name="BG" Height="300" Width="500" LoadedBehavior="Manual" Stretch="Fill" SpeedRatio="1" IsMuted="True"/>
            <Canvas>
                <TextBlock Canvas.Left="90" Canvas.Top="74" Foreground="#CCCCCC">
					<TextBlock.Inlines>
						<Run Name="Status" FontStyle="Italic"/>
					</TextBlock.Inlines>
				</TextBlock>
                <TextBlock Name="CurrentTrack" Canvas.Top="135" Foreground="#CCCCCC" FontSize="16" FontWeight="Bold" Text="No Media Loaded" TextAlignment="Center" Width="490"/>
                <Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Template="{StaticResource NoMouseOverButtonTemplate}">Menu</Button>
                <Button Name="minWin" Canvas.Left="436" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22" Template="{StaticResource NoMouseOverButtonTemplate}">___</Button>
                <Button Name="X" Canvas.Left="458" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22" FontWeight="Bold" Template="{StaticResource NoMouseOverButtonTemplate}">X</Button>
                <Button Name="File" Canvas.Left="0" Canvas.Top="17" FontSize="10" BorderBrush="#333333" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.85">&#160;&#160;&#160;File</Button>
                <Button Name="Folder" Canvas.Left="0" Canvas.Top="34" FontSize="10" BorderBrush="#333333" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.85">&#160;&#160;&#160;Folder</Button>
                <Button Name="Exit" Canvas.Left="0" Canvas.Top="51" FontSize="10" BorderBrush="#333333" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.85">&#160;&#160;&#160;Exit</Button>
                <Button Name="Mute" Canvas.Left="286" Canvas.Top="76" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="MuteButton" Height="12" Width="16"></Image>
                </Button>
                <Button Name="Shuffle" Canvas.Left="85" Canvas.Top="220" BorderThickness="2" BorderBrush="#728FCE" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="ShuffleButton" Height="15" Width="20"></Image>
                </Button>
                <Button Name="Prev" Canvas.Left="125" Canvas.Top="215" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PrevButton" Height="27" Width="55"></Image>
                </Button>
                <Button Name="Play" Canvas.Left="215" Canvas.Top="215" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PlayButton" Height="27" Width="65"></Image>
                </Button>
                <Button Name="Next" Canvas.Left="315" Canvas.Top="215" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="NextButton" Height="27" Width="55"></Image>
                </Button>
                <Button Name="Repeat" Canvas.Left="390" Canvas.Top="220" BorderThickness="2" BorderBrush="#728FCE" Background="#728FCE" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="RepeatButton" Height="15" Width="20"></Image>
                </Button>
				<Slider Name="Volume" Canvas.Left="310" Canvas.Top="80" Height="6" Width="90" Orientation="Horizontal" Minimum="0" Maximum="1" SmallChange=".01" LargeChange=".1" Background="#728FCE" Opacity="0.85"/>
                <Slider Name="Position" Canvas.Left="90" Canvas.Top="180" Height="6" Width="310" Orientation="Horizontal" Minimum="0" Maximum="1" Background="#728FCE" Opacity="0.85"/>
                <TextBlock Name="TimerA" Canvas.Left="53" Canvas.Top="175" Foreground="#CCCCCC" FontWeight="Bold"/>
                <TextBlock Name="TimerB" Canvas.Left="406" Canvas.Top="175" Foreground="#CCCCCC" FontWeight="Bold"/>
                <TextBlock Name="VolumePercent" Canvas.Left="406" Canvas.Top="75" Foreground="#CCCCCC" FontWeight="Bold"/>
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
	$global:icurrent=-1
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$mediaPlayer.Stop()
	$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
	$PlayImage.Source=$resourcepath + 'Play.png'
	$CurrentTrack.Text='No Media Loaded'
	$BG.Stop()
	$global:Playing=0
	$StatusInfo.Text=''
	$TimerA.Text=''
	$TimerB.Text=''
})
$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})
$Mute=$Window.FindName("Mute")
$MuteImage=$Window.FindName("MuteButton")
$Mute.Add_MouseEnter({
	$Mute.Background='#6495ED'
	$Mute.Opacity='1'
})
$Mute.Add_MouseLeave({
	$Mute.Background='#728FCE'
	$Mute.Opacity='0.85'
})
$Mute.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	Switch($global:Muted){
		0{
			$MuteImage.Source=$resourcepath + 'Muted.png'
			$global:UnMutedVolume=$mediaPlayer.Volume
			$mediaPlayer.Volume=0
			$global:Muted=1
			$VolumeSlider.Value=$mediaPlayer.Volume
			$VolumePercent.Text=([double]$mediaPlayer.Volume).tostring("P0")
		}
		1{
			if($global:UnMutedVolume -eq $null){
				$global:UnMutedVolume=0.5
			}
			$MuteImage.Source=$resourcepath + 'UnMuted.png'
			$mediaPlayer.Volume=$global:UnMutedVolume
			$global:Muted=0
			$VolumeSlider.Value=$mediaPlayer.Volume
			$VolumePercent.Text=([double]$mediaPlayer.Volume).tostring("P0")
		}
	}
})
if(!($mediaPlayer.IsMuted)){
	$MuteImage.Source=$resourcepath + 'UnMuted.png'
	$global:Muted=0
} else {
	$MuteImage.Source=$resourcepath + 'Muted.png'
	$global:Muted=1
}
$VolumeSlider=$Window.FindName("Volume")
$VolumeSlider.Value=$mediaPlayer.Volume
$VolumeSlider.Add_PreviewMouseUp({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	$mediaPlayer.Volume=$VolumeSlider.Value
	$VolumePercent.Text=([double]$mediaPlayer.Volume).tostring("P0")
})
$PositionSlider=$Window.FindName("Position")
$PositionSlider.Add_PreviewMouseUp({
	$mediaPlayer.Position=("{0:hh\:mm\:ss\.fff}" -f ([timespan]::fromseconds([Math]::Truncate($PositionSlider.Value))))
	$global:tracking=0
})
$PositionSlider.Add_PreviewMouseDown({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	$global:tracking=1
})
$BG=$Window.FindName("BG")
$BG.Source=$resourcepath + 'bg.gif'
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
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}	
$window.DragMove()
})
$StatusInfo=$Window.FindName("Status")
$StatusInfo.Text=''
$CurrentTrack=$Window.FindName("CurrentTrack")
$TimerA=$Window.FindName("TimerA")
$TimerB=$Window.FindName("TimerB")
$VolumePercent=$Window.FindName("VolumePercent")
$VolumePercent.Text=([double]$mediaPlayer.Volume).tostring("P0")
$MenuMain=$Window.FindName("Menu")
$MenuMain.Add_MouseEnter({
	$MenuMain.Background='#222222'
	$MenuMain.Foreground='#CCCCCC'
})
$MenuMain.Add_MouseLeave({
	$MenuMain.Background='#111111'
	$MenuMain.Foreground='#CCCCCC'
})
$MenuMain.Add_Click({
	dropDownMenu
})
$MenuFile=$Window.FindName("File")
$MenuFile.Add_MouseEnter({
	$MenuFile.Background='#222222'
	$MenuFile.Foreground='#CCCCCC'
})
$MenuFile.Add_MouseLeave({
	$MenuFile.Background='#111111'
	$MenuFile.Foreground='#CCCCCC'
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
		$global:singlefilemode=1
		$global:icurrent=-1
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$mediaPlayer.Stop()
		$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
		$PlayImage.Source=$resourcepath + 'Play.png'
		$global:Playing=0
		$path = Split-Path $file -Parent
		$path = $path+'\'
		$files=$null
		$files=@()
		$files+=Split-Path $file -leaf
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
		if($global:Playing -eq 0){
			TogglePlayButton
		}
		NextTrack
		while(([ref] $script:Repeating).Value -ge 1){
			$global:icurrent=-1
			NextTrack
		}
	}
})
$MenuFolder=$Window.FindName("Folder")
$MenuFolder.Add_MouseEnter({
	$MenuFolder.Background='#222222'
	$MenuFolder.Foreground='#CCCCCC'
})
$MenuFolder.Add_MouseLeave({
	$MenuFolder.Background='#111111'
	$MenuFolder.Foreground='#CCCCCC'
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
		$global:singlefilemode=0
		$FileDialogInterfaceType.GetMethod('GetResult',@('NonPublic','Public','Static','Instance'))
		$path = $OpenFileDialog.FileName+'\'
		$files=$null
		$files=@()
		Get-ChildItem -Path $path -Filter *.mp3 -File -Name| ForEach-Object {
			$files+=$_
		}
		if($global:ShuffleOn -eq 1){
			$global:filesShuffled=$files | Sort-Object {Get-Random}
		}
		if($global:Repeating -eq 1){
			$global:icurrent=0			
		}
		if($global:Playing -eq 0){
			TogglePlayButton
		} else {
			$global:icurrent--
		}
		while(([ref] $script:icurrent).Value -lt $files.Length - 1 -or $global:Repeating -eq 2 -and $global:singlefilemode -ne 1){
			if($global:Repeating -eq 2){
				if(([ref] $script:icurrent).Value -eq $files.Length - 1){
					$global:icurrent=-1
					if($global:ShuffleOn -eq 1) {
						$global:filesShuffled=$files | Sort-Object {Get-Random}
					}
				}
			}
			NextTrack
		}
	}
})
$MenuExit=$Window.FindName("Exit")
$MenuExit.Add_MouseEnter({
	$MenuExit.Background='#222222'
	$MenuExit.Foreground='#CCCCCC'
})
$MenuExit.Add_MouseLeave({
	$MenuExit.Background='#111111'
	$MenuExit.Foreground='#CCCCCC'
})
$MenuExit.Add_Click({
	Exit
})
$minWin=$Window.FindName("minWin")
$minWin.Add_MouseEnter({
	$minWin.Background='#222222'
	$minWin.Foreground='#CCCCCC'
})
$minWin.Add_MouseLeave({
	$minWin.Background='#111111'
	$minWin.Foreground='#CCCCCC'
})
$minWin.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	$Window.WindowState='Minimized'
})
$Xbutton=$Window.FindName("X")
$Xbutton.Add_MouseEnter({
	$Xbutton.Background='#ff0000'
	$Xbutton.Foreground='#CCCCCC'
})
$Xbutton.Add_MouseLeave({
	$Xbutton.Background='#111111'
	$Xbutton.Foreground='#CCCCCC'
})
$Xbutton.Add_Click({
	Exit
})
$Shuffle=$Window.FindName("Shuffle")
$ShuffleImage=$Window.FindName("ShuffleButton")
$ShuffleImage.Source=$resourcepath + 'Shuffle.png'
$Shuffle.Add_MouseEnter({
	$Shuffle.Background='#6495ED'
	$Shuffle.Opacity='1'
})
$Shuffle.Add_MouseLeave({
	$Shuffle.Background='#728FCE'
	$Shuffle.Opacity='0.85'
})
$Shuffle.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	Switch($global:ShuffleOn){
		0{
			$Shuffle.BorderBrush='#5D3FD3'
			$global:ShuffleOn=1
			$global:filesShuffled=$files | Sort-Object {Get-Random}
		}
		1{
			$Shuffle.BorderBrush='#728FCE'
			$global:ShuffleOn=0
		}
	}
})
$Prev=$Window.FindName("Prev")
$PrevImage=$Window.FindName("PrevButton")
$PrevImage.Source=$resourcepath + 'Prev.png'
$Prev.Add_MouseEnter({
	$Prev.Background='#6495ED'
	$Prev.Opacity='1'
})
$Prev.Add_MouseLeave({
	$Prev.Background='#728FCE'
	$Prev.Opacity='0.85'
})
$Prev.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
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
			if($global:singlefilemode -eq 1 -or ([ref] $script:icurrent).Value -lt 1){
				$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
			} else {
				PrevTrack
			}
		} else {
			$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		}
	}
})
$Play=$Window.FindName("Play")
$PlayImage=$Window.FindName("PlayButton")
$PlayImage.Source=$resourcepath + 'Play.png'
$Play.Add_MouseEnter({
	$Play.Background='#6495ED'
	$Play.Opacity='1'
})
$Play.Add_MouseLeave({
	$Play.Background='#728FCE'
	$Play.Opacity='0.85'
})
$Play.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	TogglePlayButton
})
$Next=$Window.FindName("Next")
$NextImage=$Window.FindName("NextButton")
$NextImage.Source=$resourcepath + 'Next.png'
$Next.Add_MouseEnter({
	$Next.Background='#6495ED'
	$Next.Opacity='1'
})
$Next.Add_MouseLeave({
	$Next.Background='#728FCE'
	$Next.Opacity='0.85'
})
$Next.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
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
		if($global:singlefilemode -eq 0){
			if($icurrent -eq $files.Length - 1){
				$global:icurrent--
			}
		}
		NextTrack
	}
})
$Repeat=$Window.FindName("Repeat")
$RepeatImage=$Window.FindName("RepeatButton")
$RepeatImage.Source=$resourcepath + 'RepeatAll.png'
$Repeat.Add_MouseEnter({
	$Repeat.Background='#6495ED'
	$Repeat.Opacity='1'
})
$Repeat.Add_MouseLeave({
	$Repeat.Background='#728FCE'
	$Repeat.Opacity='0.85'
})
$Repeat.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	Switch($global:Repeating){
		0{
			$RepeatImage.Source=$resourcepath + 'RepeatOne.png'
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=1
		}
		1{
			$RepeatImage.Source=$resourcepath + 'RepeatAll.png'
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=2
		}
		2{
			$RepeatImage.Source=$resourcepath + 'RepeatAll.png'
			$Repeat.BorderBrush='#728FCE'
			$global:Repeating=0
		}
	}
})
$BG.Play()
$window.Show()
$window.Activate()
$BG.Pause()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)