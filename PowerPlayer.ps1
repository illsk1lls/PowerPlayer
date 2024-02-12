$SW_HIDE, $SW_SHOW = 0, 5
$TypeDef='[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $TypeDef -Namespace Win32 -Name Functions
$hWnd=(Get-Process -Id $PID).MainWindowHandle
$Null=[Win32.Functions]::ShowWindow($hWnd,$SW_HIDE)
function Update-Gui {
    $window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}
function dropDownMenu () {
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
function PlayOrPause () {
	Switch($global:Playing){
		0{
			$PlayImage.Source='.\resources\Pause.png'
			$mediaPlayer.Play()
			$global:Playing=1
		}
		1{
			$PlayImage.Source='.\resources\Play.png'
			$mediaPlayer.Pause()
			$global:Playing=0
		}
	}
}
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration, presentationCore
[xml]$xaml='
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="PowerPlayer" Height="180" Width="300" WindowStyle="None" AllowsTransparency="True" Background="Transparent" WindowStartupLocation="CenterScreen">
    <Border CornerRadius="10" BorderBrush="#111111" BorderThickness="15" Background="#111111">
        <Grid Name="MainWindow" >
            <Grid.Background>
                <VisualBrush>
                    <VisualBrush.Visual>
                        <Image Name="BGimage"/>
                    </VisualBrush.Visual>
                </VisualBrush>
            </Grid.Background>
            <Canvas>
                <TextBlock Name="Status" Canvas.Left="18" Canvas.Top="40" Foreground="#CCCCCC" Text="Now Playing:"/>
                <TextBlock Name="CurrentTrack" Canvas.Top="63" Foreground="#CCCCCC" FontSize="12" FontWeight="Bold" Text="TrackName" TextAlignment="Center" Width="270"/>
                <Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="50">Menu</Button>
                <Button Name="File" Canvas.Left="0" Canvas.Top="17" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Open File</Button>
                <Button Name="Folder" Canvas.Left="0" Canvas.Top="34" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Open Folder</Button>
                <Button Name="Exit" Canvas.Left="0" Canvas.Top="51" FontSize="10" BorderBrush="#CCCCCC" Foreground="#CCCCCC" Background="#111111" Height="18" Width="90" Visibility="Collapsed">Exit</Button>
                <Button Name="Prev" Canvas.Left="35" Canvas.Top="105" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PrevButton" Height="23" Width="40"></Image>
                </Button>
                <Button Name="Play" Canvas.Left="109" Canvas.Top="105" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="PlayButton" Height="23" Width="50"></Image>
                </Button>
                <Button Name="Next" Canvas.Left="190" Canvas.Top="105" BorderBrush="#2F539B" Background="#728FCE" Opacity="0.9">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="10"/>
                        </Style>
                    </Button.Resources>
                    <Image Name="NextButton" Height="23" Width="40"></Image>
                </Button>
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
$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})
$BG=$Window.FindName("BGimage")
$BG.Source='.\resources\bg.png'
$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap=$BG.Source
$window.Icon=$bitmap
$window.TaskbarItemInfo.Overlay=$bitmap
$window.TaskbarItemInfo.Description=$window.Title
$CurrentTrack=$Window.FindName("CurrentTrack")
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
	$getFile=New-Object System.Windows.Forms.OpenFileDialog -Property @{
		InitialDirectory="$env:UserProfile\Music"
		Title='Select a MP3 file...'
		Filter='MP3 (*.mp3)|*.mp3'
	}
	$null=$getFile.ShowDialog()
	$file=$getFile.Filename
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$mediaPlayer.Volume = 1
	$mediaPlayer.open("$file")
	$mediaPlayer.Play()
	$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	dropDownMenu
	$PlayImage.Source='.\resources\Pause.png'
	$global:Playing=1
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
	$folder = New-Object System.Windows.Forms.FolderBrowserDialog
	$folder.SelectedPath = "$env:UserProfile\Music"
	$null = $folder.ShowDialog()
	$path = $folder.SelectedPath
	$files=@()
	dropDownMenu
	PlayOrPause
	Get-ChildItem -Path $path -Filter *.mp3 -File -Name| ForEach-Object {
		$files+=$_
	}
	for($i = 0; $i -lt $files.Length;$i++)
	{
		$file = $files[$i]
		if($i -gt 0){
			$global:behind = $files[$i - 1]
		}

		if($i -lt ($files.Length - 1)){
			$global:ahead = $files[$i + 1]
		}
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$mediaPlayer.Volume = 1
		$FullName="$path\$file"
		$mediaPlayer.open($FullName)
		$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
		$mediaPlayer.Play()
		$Shell = New-Object -COMObject Shell.Application
		$Folder = $shell.Namespace($(Split-Path $FullName))
		$File = $Folder.ParseName($(Split-Path $FullName -Leaf))
		[int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
		$totaltime=$h*60*60 + $m*60 +$s
		Update-Gui
		Start-Sleep -seconds $totaltime
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
$Prev=$Window.FindName("Prev")
$PrevImage=$Window.FindName("PrevButton")
$PrevImage.Source='.\resources\Prev.png'
$Prev.Add_Click({
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
})
$Play=$Window.FindName("Play")
$PlayImage=$Window.FindName("PlayButton")
$PlayImage.Source='.\resources\Play.png'
$Play.Add_Click({
	PlayOrPause
})
$Next=$Window.FindName("Next")
$NextImage=$Window.FindName("NextButton")
$NextImage.Source='.\resources\Next.png'
$Next.Add_Click({
	write-host 'Unfinished'
	Exit
})
$window.Show()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
