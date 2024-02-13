$SW_HIDE, $SW_SHOW = 0, 5
$TypeDef='[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $TypeDef -Namespace Win32 -Name Functions
$hWnd=(Get-Process -Id $PID).MainWindowHandle
$Null=[Win32.Functions]::ShowWindow($hWnd,$SW_HIDE)
$global:Playing=0
$global:file
$global:files
$global:Fullname
$global:icurrent
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
function TogglePlay(){
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
function NextTrack(){
	$file = $files[$icurrent++]
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$FullName="$path\$file"
	$mediaPlayer.open($FullName)
	$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	$mediaPlayer.Play()
	trackLength
	Update-Gui
	WaitForSong
}
function PrevTrack(){
	$file = $files[$icurrent--]
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$FullName="$path\$file"
	$mediaPlayer.open($FullName)
	$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	$mediaPlayer.Play()
	trackLength
	Update-Gui
	WaitForSong
}
function trackLength(){
	$Shell = New-Object -COMObject Shell.Application
	$Folder = $shell.Namespace($(Split-Path $FullName))
	$File = $Folder.ParseName($(Split-Path $FullName -Leaf))
	[int]$h, [int]$m, [int]$s = ($Folder.GetDetailsOf($File, 27)).split(":")
	$global:totaltime=$h*60*60 + $m*60 +$s
}
function WaitForSong(){
	$meter=(Get-Date).ToString("ss")
	:waiting while($true){
		if($meter -ne (Get-Date).ToString("ss")){
			$meter=(Get-Date).ToString("ss")
			$totaltime--
		}
		Update-Gui
		Start-Sleep -milliseconds 50
		if($totaltime -le .01){
			break waiting
		}
	}
}
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration, presentationCore
Add-Type -TypeDefinition 'using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  // f(), g(), ... are unused COM method slots. Define these if you care
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
  int j();
  int GetMasterVolumeLevelScalar(out float pfLevel);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
  int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
  int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
  int f(); // Unused
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class Audio {
  static IAudioEndpointVolume Vol() {
var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
IMMDevice dev = null;
Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
IAudioEndpointVolume epv = null;
var epvid = typeof(IAudioEndpointVolume).GUID;
Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
return epv;
  }
  public static float Volume {
get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
  }
  public static bool Mute {
get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
  }
}'
[xml]$xaml='
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="PowerPlayer" Height="180" Width="300" WindowStyle="None" AllowsTransparency="True" Background="Transparent" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
<Border CornerRadius="10" BorderBrush="#111111" BorderThickness="15" Background="#111111">
<Grid Name="MainWindow">
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
				<Button Name="minWin" Canvas.Left="225" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22">___</Button>
				<Button Name="X" Canvas.Left="248" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="22" FontWeight="Bold">X</Button>
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
				<Slider Name="Volume" Canvas.Left="175" Canvas.Top="45" Height="6" Width="60" Orientation="Horizontal" Minimum="0" Maximum="1" SmallChange=".01" LargeChange=".1" Background="#728FCE" Opacity="0.9" />
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
$VolumeSlider=$Window.FindName("Volume")
$VolumeSlider.Value=[audio]::Volume
$VolumeSlider.Add_PreviewMouseUp({
	[audio]::Volume=$VolumeSlider.Value
})
$VolumeSlider.Add_PreviewMouseUp({
	[audio]::Volume=$VolumeSlider.Value
})
$BG=$Window.FindName("BGimage")
$BG.Source='.\resources\bg.png'
$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap=$BG.Source
$window.Icon=$bitmap
$window.TaskbarItemInfo.Overlay=$bitmap
$window.TaskbarItemInfo.Description=$window.Title
$window.add_MouseLeftButtonDown({
$window.DragMove()
})
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
	dropDownMenu
	$getFile=New-Object System.Windows.Forms.OpenFileDialog -Property @{
		InitialDirectory="$env:UserProfile\Music"
		Title='Select a MP3 file...'
		Filter='MP3 (*.mp3)|*.mp3'
	}
	$null=$getFile.ShowDialog()
	$file=$getFile.Filename
	$FullName=$file
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$mediaPlayer.open("$file")
	$CurrentTrack.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	TogglePlay
	trackLength
	Update-GUI
	WaitForSong
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
	$folder = New-Object System.Windows.Forms.FolderBrowserDialog
	$folder.SelectedPath = "$env:UserProfile\Music"
	$null = $folder.ShowDialog()
	$path = $folder.SelectedPath
	$files=@()
	Get-ChildItem -Path $path -Filter *.mp3 -File -Name| ForEach-Object {
		$files+=$_
	}
	for($icurrent = 0; $icurrent -lt $files.Length;$icurrent++)
	{
	NextTrack
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
	$Window.WindowState = 'Minimized'
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
	if($checkposition -le 2){
		$global:totaltime=0
		PrevTrack
		break waiting
	} else {
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	}
})
$Play=$Window.FindName("Play")
$PlayImage=$Window.FindName("PlayButton")
$PlayImage.Source='.\resources\Play.png'
$Play.Add_Click({
	TogglePlay;
})
$Next=$Window.FindName("Next")
$NextImage=$Window.FindName("NextButton")
$NextImage.Source='.\resources\Next.png'
$Next.Add_Click({
	$global:totaltime=0
	break waiting
})
$window.Show()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)