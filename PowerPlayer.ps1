Add-Type -MemberDefinition '[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Namespace Win32 -Name Functions
$closeConsoleUseGUI=[Win32.Functions]::ShowWindow((Get-Process -Id $PID).MainWindowHandle,0)
$ReLaunchInProgress=$args[0]
$AppId='PowerPlayer';$oneInstance=$false
$script:SingleInstanceEvent=New-Object Threading.EventWaitHandle $true,([Threading.EventResetMode]::ManualReset),"Global\PowerPlayer",([ref] $oneInstance)
if($ReLaunchInProgress -ne 'Relaunching'){
	if( -not $oneInstance){
		$alreadyRunning=New-Object -ComObject Wscript.Shell;$alreadyRunning.Popup("PowerPlayer is already running!",0,'ERROR:',0x0) | Out-Null
		Exit
	}
}
$localResources=([IO.Path]::GetFullPath('.\resources\'))
$resourcepath=$env:ProgramData + '\PowerPlayer\'
$resourcecheck='bg.gif','Muted.png','Next.png','Pause.png','Play.png','Prev.png','RepeatAll.png','RepeatOne.png','Shuffle.png','UnMuted.png'
$isMissing=0
function updateResources(){
	$ProgressPreference='SilentlyContinue'
		foreach($item in $resourcecheck){
			irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/resources/$item -o $resourcepath$item
		}
	$ProgressPreference='Continue'
}
function missingResources(){
	$resourcesMissing=New-Object -ComObject Wscript.Shell;$resourcesMissing.Popup("Click OK to download ~2mb of resources from the projects resources folder on GitHub. They will be stored in:`n`n" + $resourcepath + "`n`nOr press Cancel to Quit",0,'GUI Resources are missing!',0x1) | Tee-Object -Variable DoResources | Out-Null
	if($DoResources -eq 1){
		if(Test-Path -Path $resourcepath){
			Remove-Item -Path $resourcepath -Recurse -Force | out-null
		}
		New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
		updateResources
	} else {
		Exit
	}	
}
if($PSCommandPath -eq $null){function GetPSCommandPath(){return $MyInvocation.PSCommandPath;}$PSCommandPath=GetPSCommandPath}
$CtrlKey = '0x11'
$CheckCtrlHeldAtLaunch='[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]public static extern short GetAsyncKeyState(int virtualKeyCode);'
Add-Type -MemberDefinition $CheckCtrlHeldAtLaunch -Name Keyboard -Namespace PsOneApi
if([bool]([PsOneApi.Keyboard]::GetAsyncKeyState($CtrlKey) -eq -32767)){ 
	$Updater=New-Object -ComObject Wscript.Shell;$Updater.Popup("Would you like to retrieve the latest version of PowerPlayer from Github?",0,'Update Mode Initialized',0x1) | Tee-Object -Variable DoFullUpdate | Out-Null
	if($DoFullUpdate -eq 1){
		Remove-Item -Path $resourcepath -Recurse -Force | out-null
		New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
		updateResources
		irm https://raw.githubusercontent.com/illsk1lls/PowerPlayer/main/PowerPlayer.ps1 -o $PSCommandPath
		$ReLauncher=New-Object -ComObject Wscript.Shell;$ReLauncher.Popup("Re-Launch PowerPlayer now?",0,'Update Mode Completed!',0x1) | Tee-Object -Variable DoRelaunch | Out-Null
		if($DoRelaunch -eq 1){
			. $PSCommandPath 'Relaunching'
			Exit
		} else {
			Exit
		}
	} else {
		$NoUpdate=New-Object -ComObject Wscript.Shell;$NoUpdate.Popup("No changes were made.",0,'Update Mode Aborted',0x0) | Out-Null
	}
}
if(!(Test-Path -Path $resourcepath)){
	if(Test-Path -Path $localResources){
		foreach ($item in $resourcecheck){
			if(![System.IO.File]::Exists($localResources + $item)){
				$isMissing++
			}
		}
		if($isMissing -eq 0){
			New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
			foreach($item in $resourcecheck) {
				Copy-Item -Path .\resources\$item -Destination $resourcepath -Force
			}
		} else {
			missingResources
		}
	} else {
		missingResources
	}
} else {
	foreach($item in $resourcecheck){
		if(![System.IO.File]::Exists($resourcepath + $item)){
			$isMissing++
		}
	}
	if($isMissing -ne 0){
		if(Test-Path -Path $localResources){
			$isMissing=0
			foreach($item in $resourcecheck){
				if(![System.IO.File]::Exists($localResources + $item)){
					$isMissing++
				}
			}
			if($isMissing -eq 0){
				Remove-Item -Path $resourcepath -Recurse -Force | out-null
				New-Item -Path $env:ProgramData -Name "PowerPlayer" -ItemType "directory" | out-null
				foreach($item in $resourcecheck){
					Copy-Item -Path .\resources\$item -Destination $resourcepath -Force
				}
			} else {
				missingResources
			}
		} else {
			missingResources
		}
	}
}
$global:Playing=0
$global:Repeating=0
$global:ShuffleOn=0
$global:tracking=0
$global:icurrent=-1
$global:AnimationStarted=0
$global:AnimationThread=0
$global:flyoutPressed=0
$global:VolMax=0
$global:CounterB=0
function Update-Gui(){
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
function closeMenus(){
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.SelectedIndex=$icurrent
		toggleFlyOut
	}
}
function toggleFlyOut(){
	Switch($FlyOutPressed){
	0{
		$global:AnimationThread=1
		$ButtonData.Text='1'
		$MenuPlaylist1.Height="18"
		$MenuPlaylist1.Width="70"
		$MenuPlaylist1.Visibility="Visible"
		$MenuPlaylist2.Visibility="Hidden"
		$MenuPlaylist2.Content=">>"
		$MenuPlaylist1.Content="Playlist"
		$Playlist.Visibility="visible"
		$global:flyoutPressed=1
	}
	1{
		$global:AnimationThread=1
		$ButtonData.Text='0'
		$MenuPlaylist1.Height="18"
		$MenuPlaylist1.Width="25"
		$MenuPlaylist1.Visibility="Hidden"
		$MenuPlaylist2.Visibility="Visible"
		$Playlist.Visibility="Hidden"
		$global:flyoutPressed=0
	}
	}	
}
function TogglePlayButton(){
	if($files -ne $null){
		Switch($Playing){
			0{
				$PlayImage.ImageSource=$resourcepath + 'Pause.png'
				$mediaPlayer.Play()
				$window.TaskbarItemInfo.Overlay=$resourcepath + 'Play.png'
				$window.TaskbarItemInfo.Description='Playing...'
				$global:Playing=1
				$StatusInfo1.Text="Now Playing"
				$StatusInfo2.Text=$StatusInfo1.Text
				$StatusInfo3.Text=$StatusInfo1.Text
				$StatusInfo4.Text=$StatusInfo1.Text
				$StatusInfo5.Text=$StatusInfo1.Text
				$background.Play()
				if($AnimationStarted -eq 0){
					$AnimationStarted=1
					$background.Opacity="1"
					$backgroundstatic.Opacity="0"
				}
			}
			1{
				$PlayImage.ImageSource=$resourcepath + 'Play.png'
				$mediaPlayer.Pause()
				$window.TaskbarItemInfo.Overlay=$resourcepath + 'Pause.png'
				$window.TaskbarItemInfo.Description='Paused...'
				$global:Playing=0
				$StatusInfo1.Text="Paused"
				$StatusInfo2.Text=$StatusInfo1.Text
				$StatusInfo3.Text=$StatusInfo1.Text
				$StatusInfo4.Text=$StatusInfo1.Text
				$StatusInfo5.Text=$StatusInfo1.Text
				$background.Pause()
			}
		}
	}
}
function NextTrack(){
	if($icurrent -lt $files.Length - 1){
		if(!($Repeating -eq 1)){
			$global:icurrent++
		}
		if($ShuffleOn -eq 0){
			$file = $files[$icurrent]
		} else {
			if($singlefilemode -eq 1){
				$file = $files[$icurrent]				
			} else {
				$file = $filesShuffled[$icurrent]				
			}
		}
		$Playlist.SelectedIndex=$icurrent
		PlayTrack	
	} else {
		if($Repeating -eq 2){
			$global:icurrent=0
			if($ShuffleOn -eq 0){
				$file = $files[$icurrent]
			} else {
				$global:icurrent=0
				if($singlefilemode -eq 1){
					$file = $files[$icurrent]				
				} else {
					$file = $filesShuffled[$icurrent]
				}
			}
		}
		$Playlist.SelectedIndex=$icurrent
		PlayTrack	
	}
}
function PrevTrack(){
	if($icurrent -ge 1){
		if(!($Repeating -eq 1)){
			$global:icurrent--
		}
		if($ShuffleOn -eq 0){
			$file = $files[$icurrent]
		} else {
			if($singlefilemode -eq 1){
				$file = $files[$icurrent]				
			} else {
				$file = $filesShuffled[$icurrent]				
			}
		}
		$Playlist.SelectedIndex=$icurrent
		PlayTrack
	} else {
		if($Repeating -eq 2){
			$global:icurrent=$files.Length - 1
			if($ShuffleOn -eq 0){
				$file = $files[$icurrent]
			} else {
				if($script:singlefilemode -eq 1){
					$file = $files[$icurrent]					
				} else {
					$file = $filesShuffled[$icurrent]					
				}
			}
			$Playlist.SelectedIndex=$icurrent
			PlayTrack	
		}
	}
}
function trackLength(){
	if($TimeLeft.Visibility -eq "Hidden"){
		$TimeLeft.Visibility="Visible"
	}
	$Shell = New-Object -COMObject Shell.Application
	$FolderL = $shell.Namespace($(Split-Path $FullName))
	$FileL = $FolderL.ParseName($(Split-Path $FullName -Leaf))
	[int]$h, [int]$m, [int]$s = ($FolderL.GetDetailsOf($FileL, 27)).split(":")
	$global:totaltime=$h*60*60 + $m*60 +$s
	$global:ReadableTotal=[timespan]::fromseconds($totaltime - 2)
	$global:RemainingTotal=[timespan]::fromseconds($totaltime - 1)
	$TimerB1.Text=("{0:mm\:ss}" -f $ReadableTotal)
	$TimerB2.Text=$TimerB1.Text
	$TimerB3.Text=$TimerB1.Text
	$TimerB4.Text=$TimerB1.Text
	$TimerB5.Text=$TimerB1.Text
	$PositionSlider.Maximum=$totaltime
}
function WaitForSong(){
	while(([Math]::Ceiling(([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds)) -lt ([ref] $totaltime).Value){
		if(([ref] $tracking).Value -eq 0){
			$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
			$TimePassed=[timespan]::fromseconds(([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds)
			$TimerA1.Text=("{0:mm\:ss}" -f $TimePassed)
			$TimerA2.Text=$TimerA1.Text
			$TimerA3.Text=$TimerA1.Text
			$TimerA4.Text=$TimerA1.Text
			$TimerA5.Text=$TimerA1.Text
		}
		if(([ref] $CounterB).Value -eq 1){
			$TimeRemaining=$RemainingTotal - $TimePassed
			$TimerB1.Text=("{0:mm\:ss}" -f $TimeRemaining) + '-'
			$TimerB2.Text=$TimerB1.Text
			$TimerB3.Text=$TimerB1.Text
			$TimerB4.Text=$TimerB1.Text
			$TimerB5.Text=$TimerB1.Text			
		}
		Update-Gui
		if($AnimationThread -eq 0){
			Start-Sleep -milliseconds 50
		}
		if($AnimationThread -eq 1){
			$i++
			if($i -ge 300){
				$global:AnimationThread=0
				$i=0
			}
		}
	}
}
function PlayTrack(){
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$FullName="$path\$file"
	$mediaPlayer.open($FullName)
	$CurrentTrack1.Text=[System.IO.Path]::GetFileNameWithoutExtension($file)
	$CurrentTrack2.Text=$CurrentTrack1.Text
	$CurrentTrack3.Text=$CurrentTrack1.Text
	$CurrentTrack4.Text=$CurrentTrack1.Text
	$CurrentTrack5.Text=$CurrentTrack1.Text
	if($Playing -eq 1){
		$mediaPlayer.Play()		
	}
	trackLength
	WaitForSong	
}
function FileIdle(){
	while(([ref] $Repeating).Value -ge 1){
		$global:icurrent=-1
		NextTrack
	}	
}
function FolderIdle(){
	while(([ref] $icurrent).Value -lt $files.Length -1 -or ([ref] $Repeating).Value -eq 2 -and ([ref] $singlefilemode).Value -ne 1){
		if($Repeating -ne 0){
			if($icurrent -eq $files.Length - 1){
				$global:icurrent=-1
				if($ShuffleOn -eq 1){
					$global:filesShuffled=$files | Sort-Object {Get-Random}
				}
			}
		}
		NextTrack
	}	
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
		<Style x:Key="ScrollThumbs" TargetType="{x:Type Thumb}">
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type Thumb}">
						<Grid x:Name="Grid">
							<Rectangle HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Width="Auto" Height="Auto" Fill="Transparent"/>
							<Border x:Name="Rectangle1" CornerRadius="5" HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Width="Auto" Height="Auto" Background="{TemplateBinding Background}"/>
						</Grid>
						<ControlTemplate.Triggers>
							<Trigger Property="Tag" Value="Horizontal">
								<Setter TargetName="Rectangle1" Property="Width" Value="Auto"/>
								<Setter TargetName="Rectangle1" Property="Height" Value="7"/>
							</Trigger>
						</ControlTemplate.Triggers>
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollBarStyle" TargetType="{x:Type ScrollBar}">
			<Setter Property="Foreground" Value="#6495ED"/>
			<Setter Property="Background" Value="Transparent"/>
			<Setter Property="Width" Value="8"/>
			<Setter Property="Opacity" Value="0.85"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type ScrollBar}">
						<Grid x:Name="GridRoot" Width="8" Background="{TemplateBinding Background}">
							<Grid.RowDefinitions>
								<RowDefinition Height="0.00001*"/>
							</Grid.RowDefinitions>
							<Track x:Name="PART_Track" Grid.Row="0" IsDirectionReversed="true" Focusable="false">
								<Track.Thumb>
									<Thumb x:Name="Thumb" Background="{TemplateBinding Foreground}" Style="{StaticResource ScrollThumbs}"/>
								</Track.Thumb>
								<Track.IncreaseRepeatButton>
									<RepeatButton x:Name="PageUp" Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="false"/>
								</Track.IncreaseRepeatButton>
								<Track.DecreaseRepeatButton>
									<RepeatButton x:Name="PageDown" Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="false"/>
								</Track.DecreaseRepeatButton>
							</Track>
						</Grid>
						<ControlTemplate.Triggers>
							<Trigger Property="IsEnabled" Value="false">
								<Setter TargetName="Thumb" Property="Visibility" Value="Collapsed"/>
							</Trigger>
							<Trigger Property="Orientation" Value="Horizontal">
								<Setter TargetName="GridRoot" Property="LayoutTransform">
									<Setter.Value>
										<RotateTransform Angle="-90"/>
									</Setter.Value>
								</Setter>
								<Setter TargetName="PART_Track" Property="LayoutTransform">
									<Setter.Value>
										<RotateTransform Angle="-90"/>
									</Setter.Value>
								</Setter>
								<Setter Property="Width" Value="Auto"/>
								<Setter Property="Height" Value="8"/>
								<Setter TargetName="Thumb" Property="Tag" Value="Horizontal"/>
								<Setter TargetName="PageDown" Property="Command" Value="ScrollBar.PageLeftCommand"/>
								<Setter TargetName="PageUp" Property="Command" Value="ScrollBar.PageRightCommand"/>
							</Trigger>
						</ControlTemplate.Triggers>
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollViewerStyle" TargetType="{x:Type ScrollViewer}">
			<Setter Property="OverridesDefaultStyle" Value="True"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type ScrollViewer}">
						<Grid>
							<Grid.ColumnDefinitions>
								<ColumnDefinition Width="16"/>
								<ColumnDefinition />
								<ColumnDefinition Width="16"/>
							</Grid.ColumnDefinitions>
							<Grid.RowDefinitions>
								<RowDefinition />
							</Grid.RowDefinitions>
							<ScrollContentPresenter Grid.ColumnSpan="3" />
							<ScrollBar x:Name="PART_VerticalScrollBar" Grid.Column="2" Value="{TemplateBinding VerticalOffset}" Maximum="{TemplateBinding ScrollableHeight}" ViewportSize="{TemplateBinding ViewportHeight}" Style="{DynamicResource ScrollBarStyle}" Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"/>
						</Grid>
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="lbStyle" TargetType="{x:Type ListBox}">
			<Setter Property="Background" Value="#333333"/>
			<Setter Property="BorderBrush" Value="#111111"/>
			<Setter Property="BorderThickness" Value="1"/>
			<Setter Property="Foreground" Value="{DynamicResource {x:Static SystemColors.ControlTextBrushKey}}"/>
			<Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Hidden"/>
			<Setter Property="ScrollViewer.VerticalScrollBarVisibility" Value="Auto"/>
			<Setter Property="ScrollViewer.CanContentScroll" Value="True"/>
			<Setter Property="ScrollViewer.PanningMode" Value="Both"/>
			<Setter Property="Stylus.IsFlicksEnabled" Value="False"/>
			<Setter Property="VerticalContentAlignment" Value="Center"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type ListBox}">
						<Border x:Name="Border1" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}" Padding="1" SnapsToDevicePixels="True">
							<ScrollViewer Style="{StaticResource ScrollViewerStyle}" Focusable="False" Padding="{TemplateBinding Padding}">
								<ItemsPresenter SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"/>
							</ScrollViewer>
						</Border>
						<ControlTemplate.Triggers>
							<Trigger Property="IsEnabled" Value="False">
								<Setter Property="Background" TargetName="Border1" Value="#111111"/>
								<Setter Property="BorderBrush" TargetName="Border1" Value="#333333"/>
							</Trigger>
							<MultiTrigger>
								<MultiTrigger.Conditions>
									<Condition Property="IsGrouping" Value="True"/>
									<Condition Property="VirtualizingPanel.IsVirtualizingWhenGrouping" Value="False"/>
								</MultiTrigger.Conditions>
								<Setter Property="ScrollViewer.CanContentScroll" Value="False"/>
							</MultiTrigger>
						</ControlTemplate.Triggers>
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="AlternatingRowStyle" TargetType="{x:Type Control}" >
			<Setter Property="Background" Value="#222222"/>
			<Setter Property="Foreground" Value="#EEEEEE"/>
			<Style.Triggers>
				<Trigger Property="ItemsControl.AlternationIndex" Value="1">                            
					<Setter Property="Background" Value="#111111"/>
					<Setter Property="Foreground" Value="#EEEEEE"/>                                
				</Trigger>                            
			</Style.Triggers>
		</Style>
    </Window.Resources>
    <Border CornerRadius="5" BorderBrush="#111111" BorderThickness="10" Background="#111111">
        <Grid Name="MainWindow">
			<Image Name="BackgroundStatic" Height="300" Width="500" Stretch="Fill"/>
            <MediaElement Name="Background" Height="300" Width="500" LoadedBehavior="Manual" Stretch="Fill" SpeedRatio="1" IsMuted="True" Opacity="0"/>
            <Canvas>
				<TextBlock Visibility="Hidden" Name="ButtonData"/>
                <TextBlock Name="Status5" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="Purple" Margin="-1,-1"/>
                <TextBlock Name="Status4" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="MediumPurple" Margin="-1,1"/>
                <TextBlock Name="Status3" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="RoyalBlue" Margin="1,-1"/>
                <TextBlock Name="Status2" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="LightBlue" Margin="1,1"/>
                <TextBlock Name="Status1" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="LightGray"/>
				<TextBlock Name="CurrentTrack5" Canvas.Top="133" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="CurrentTrack4" Canvas.Top="133" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="CurrentTrack3" Canvas.Top="133" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="CurrentTrack2" Canvas.Top="133" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="CurrentTrack1" Canvas.Top="133" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="LightGray"/>
                <Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#EEEEEE" Background="#111111" Height="18" Width="70" Template="{StaticResource NoMouseOverButtonTemplate}">Menu</Button>
				<Button Name="MenuPlaylist1" Canvas.Left="70" Canvas.Top="0" Visibility="Hidden" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#DDDDDD" Background="#111111" Height="18" Width="25" Template="{StaticResource NoMouseOverButtonTemplate}">>>
					<Button.Style>
						<Style>
							<Style.Triggers>
								<DataTrigger Binding="{Binding ElementName=ButtonData, Path=Text}" Value="1">
									<DataTrigger.EnterActions>
										<BeginStoryboard>
											<Storyboard>
												<DoubleAnimation From="70" To="207" Duration="0:0:0.25" Storyboard.TargetProperty="(Canvas.Left)" AutoReverse="False"/>
											</Storyboard>
										</BeginStoryboard>
									</DataTrigger.EnterActions>
								</DataTrigger>
							</Style.Triggers>
						</Style>
					</Button.Style>
				</Button>
				<Button Name="MenuPlaylist2" Canvas.Left="207" Canvas.Top="0" Visibility="Hidden" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#DDDDDD" Background="#111111" Height="18" Width="25" Template="{StaticResource NoMouseOverButtonTemplate}">Playlist
					<Button.Style>
						<Style>
							<Style.Triggers>
								<DataTrigger Binding="{Binding ElementName=ButtonData, Path=Text}" Value="0">
									<DataTrigger.EnterActions>
										<BeginStoryboard>
											<Storyboard>
												<DoubleAnimation From="233" To="70" Duration="0:0:0.25" Storyboard.TargetProperty="(Canvas.Left)" AutoReverse="False"/>
											</Storyboard>
										</BeginStoryboard>
									</DataTrigger.EnterActions>
								</DataTrigger>
							</Style.Triggers>
						</Style>
					</Button.Style>
				</Button>
                <Button Name="minWin" Canvas.Left="436" Canvas.Top="0" FontSize="12" BorderBrush="#111111" Foreground="#EEEEEE" Background="#111111" Height="18" Width="22" Template="{StaticResource NoMouseOverButtonTemplate}">__</Button>
                <Button Name="X" Canvas.Left="458" Canvas.Top="0" FontSize="12" FontWeight="Bold" BorderBrush="#111111" Foreground="#EEEEEE" Background="#111111" Height="18" Width="22" Template="{StaticResource NoMouseOverButtonTemplate}">X</Button>
                <Button Name="File" Canvas.Left="0" Canvas.Top="17" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#333333" Foreground="#EEEEEE" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.9">&#160;&#160;&#160;File</Button>
                <Button Name="Folder" Canvas.Left="0" Canvas.Top="34" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#333333" Foreground="#EEEEEE" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.9">&#160;&#160;&#160;Folder</Button>
                <Button Name="Exit" Canvas.Left="0" Canvas.Top="51" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#333333" Foreground="#EEEEEE" Background="#111111" Height="18" Width="70" Visibility="Collapsed" HorizontalContentAlignment="Left" Template="{StaticResource NoMouseOverButtonTemplate}" Opacity="0.9">&#160;&#160;&#160;Exit</Button>
                <Button Name="Mute" Canvas.Left="286" Canvas.Top="76" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="12" Width="16">
						<Border.Background>
							<ImageBrush x:Name="MuteButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border BorderThickness="0"  CornerRadius="0" Margin="0" >
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Button Name="Shuffle" Canvas.Left="80" Canvas.Top="220" BorderThickness="2" BorderBrush="#6495ED" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="15" Width="20">
						<Border.Background>
							<ImageBrush x:Name="ShuffleButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border BorderThickness="0"  CornerRadius="0" Margin="0" >
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Button Name="Prev" Canvas.Left="122" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="27" Width="55">
						<Border.Background>
							<ImageBrush x:Name="PrevButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border BorderThickness="0"  CornerRadius="0" Margin="0" >
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Button Name="Play" Canvas.Left="211" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="27" Width="65">
						<Border.Background>
							<ImageBrush x:Name="PlayButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border CornerRadius="0" Margin="0">
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Button Name="Next" Canvas.Left="312" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="5"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="27" Width="55">
						<Border.Background>
							<ImageBrush x:Name="NextButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border CornerRadius="0" Margin="0">
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Button Name="Repeat" Canvas.Left="386" Canvas.Top="220" BorderThickness="2" BorderBrush="#6495ED" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
                    <Button.Resources>
                        <Style TargetType="Border">
                            <Setter Property="CornerRadius" Value="3"/>
                        </Style>
                    </Button.Resources>
					<Border CornerRadius="5" Height="15" Width="20">
						<Border.Background>
							<ImageBrush x:Name="RepeatButton" Stretch="Uniform"/>
						</Border.Background>
						<Border.Effect>
							<DropShadowEffect BlurRadius="10" ShadowDepth="5" Direction="315"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Border CornerRadius="0" Margin="0" >
							<Border.Background>
								<RadialGradientBrush GradientOrigin="0.7,-0.6" RadiusY="0.5" RadiusX="1.001">
									<RadialGradientBrush.RelativeTransform>
										<TransformGroup>
											<ScaleTransform CenterY="0.5" CenterX="0.5" ScaleY="1" ScaleX="1"/>
											<SkewTransform AngleY="0" AngleX="0" CenterY="0.5" CenterX="0.5"/>
											<RotateTransform Angle="-29.285" CenterY="0.5" CenterX="0.5"/>
											<TranslateTransform/>
										</TransformGroup>
									</RadialGradientBrush.RelativeTransform>
									<GradientStop Color="#B6FFFFFF"/>
									<GradientStop Color="#0BFFFFFF" Offset="0.478"/>
								</RadialGradientBrush>
							</Border.Background>
						</Border>
					</Border>
                </Button>
                <Slider Name="Volume" Canvas.Left="310" Canvas.Top="80" Height="6" Width="90" Orientation="Horizontal" Minimum="0" Maximum="1" SmallChange=".01" LargeChange=".1" Background="#6495ED" Opacity="0.7"/>
                <Slider Name="Position" Canvas.Left="90" Canvas.Top="180" Height="6" Width="310" Orientation="Horizontal" Background="#6495ED" Opacity="0.7"/>
				<TextBlock Name="TimerA5" Canvas.Left="49" Canvas.Top="172" FontSize="14" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="TimerA4" Canvas.Left="49" Canvas.Top="172" FontSize="14" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="TimerA3" Canvas.Left="49" Canvas.Top="172" FontSize="14" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="TimerA2" Canvas.Left="49" Canvas.Top="172" FontSize="14" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="TimerA1" Canvas.Left="49" Canvas.Top="172" FontSize="14" Foreground="LightGray"/>
				<TextBlock Name="TimerB5" Canvas.Left="407" Canvas.Top="172" FontSize="14" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="TimerB4" Canvas.Left="407" Canvas.Top="172" FontSize="14" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="TimerB3" Canvas.Left="407" Canvas.Top="172" FontSize="14" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="TimerB2" Canvas.Left="407" Canvas.Top="172" FontSize="14" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="TimerB1" Canvas.Left="407" Canvas.Top="172" FontSize="14" Foreground="LightGray"/>
				<TextBlock Name="VolumePercent5" Canvas.Left="407" Canvas.Top="72" FontSize="14" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="VolumePercent4" Canvas.Left="407" Canvas.Top="72" FontSize="14" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="VolumePercent3" Canvas.Left="407" Canvas.Top="72" FontSize="14" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="VolumePercent2" Canvas.Left="407" Canvas.Top="72" FontSize="14" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="VolumePercent1" Canvas.Left="407" Canvas.Top="72" FontSize="14" Foreground="LightGray"/>
                <Button Name="MaxVolume" Canvas.Left="407" Canvas.Top="75" Height="15" Width="28" Opacity="0" Template="{StaticResource NoMouseOverButtonTemplate}"/>
                <Button Name="TimeLeft" Canvas.Left="407" Canvas.Top="175" Visibility="Hidden" Height="15" Width="35" Opacity="0" Template="{StaticResource NoMouseOverButtonTemplate}"/>
				<ListBox Canvas.Left="85" Canvas.Top="18" Name="Playlist" Visibility="Hidden" Width="320" Height="245" Opacity="0.95" ItemsSource="{Binding ActorList}" Style="{DynamicResource lbStyle}" AlternationCount="2" ItemContainerStyle="{StaticResource AlternatingRowStyle}"/>
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
	if($Repeating -ne 0){
		if($icurrent -eq $files.Length - 1){
			$global:icurrent=-1
			if($ShuffleOn -eq 1){
				$global:filesShuffled=$files | Sort-Object {Get-Random}
			}
		}
	} else {
	$MenuPlaylist1.Visibility="Hidden"
	$MenuPlaylist2.Visibility="Hidden"
	$Playlist.Visibility="Hidden"
	$TimeLeft.Visibility="Hidden"
	$global:icurrent=-1
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$mediaPlayer.Stop()
	$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
	$PlayImage.ImageSource=$resourcepath + 'Play.png'
	$CurrentTrack1.Text='No Media Loaded'
	$CurrentTrack2.Text=$CurrentTrack1.Text
	$CurrentTrack3.Text=$CurrentTrack1.Text
	$CurrentTrack4.Text=$CurrentTrack1.Text
	$CurrentTrack5.Text=$CurrentTrack1.Text
	$background.Stop()
	$global:Playing=0
	$StatusInfo1.Text=''
	$StatusInfo2.Text=$StatusInfo1.Text
	$StatusInfo3.Text=$StatusInfo1.Text
	$StatusInfo4.Text=$StatusInfo1.Text
	$StatusInfo5.Text=$StatusInfo1.Text
	$TimerA1.Text=''
	$TimerA2.Text=$TimerA1.Text
	$TimerA3.Text=$TimerA1.Text
	$TimerA4.Text=$TimerA1.Text
	$TimerA5.Text=$TimerA1.Text	
	$TimerB1.Text=''
	$TimerB2.Text=$TimerB1.Text
	$TimerB3.Text=$TimerB1.Text
	$TimerB4.Text=$TimerB1.Text
	$TimerB5.Text=$TimerB1.Text
	}
})
$window.Add_Closing({[System.Windows.Forms.Application]::Exit();Stop-Process $pid})
$Mute=$Window.FindName("Mute")
$MuteImage=$Window.FindName("MuteButton")
$Mute.Add_MouseEnter({
	$Mute.Background='#6c9bf0'
	$Mute.Opacity='0.95'
})
$Mute.Add_MouseLeave({
	$Mute.Background='#6495ED'
	$Mute.Opacity='0.85'
})
$Mute.Add_Click({
	closeMenus
	Switch($Muted){
		0{
			$MuteImage.ImageSource=$resourcepath + 'Muted.png'
			$global:UnMutedVolume=$mediaPlayer.Volume
			$MaxVolume.Width=20
			$mediaPlayer.Volume=0
			$VolumeSlider.Value=$mediaPlayer.Volume
			$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
			$VolumePercent2.Text=$VolumePercent1.Text
			$VolumePercent3.Text=$VolumePercent1.Text
			$VolumePercent4.Text=$VolumePercent1.Text
			$VolumePercent5.Text=$VolumePercent1.Text
			$global:Muted=1
		}
		1{
			if($UnMutedVolume -eq $null){
				$global:UnMutedVolume=0.5
			}
			$MuteImage.ImageSource=$resourcepath + 'UnMuted.png'
			$mediaPlayer.Volume=$global:UnMutedVolume
			if($mediaPlayer.Volume -lt 0.1){
				$MaxVolume.Width=20
			} else {
				$MaxVolume.Width=28
			}
			if($mediaPlayer.Volume -eq 1){
				$MaxVolume.Width=35
			}
			$VolumeSlider.Value=$mediaPlayer.Volume
			$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
			$VolumePercent2.Text=$VolumePercent1.Text
			$VolumePercent3.Text=$VolumePercent1.Text
			$VolumePercent4.Text=$VolumePercent1.Text
			$VolumePercent5.Text=$VolumePercent1.Text
			$global:Muted=0
		}
	}
})
if($mediaPlayer.IsMuted){
	$MuteImage.ImageSource=$resourcepath + 'Muted.png'
	$global:Muted=1	
} else {
	$MuteImage.ImageSource=$resourcepath + 'UnMuted.png'
	$global:Muted=0
}
$Playlist=$Window.FindName('Playlist')
$Playlist.Add_MouseDoubleClick({
	if($Repeating -eq 1){
		$global:icurrent=$Playlist.SelectedIndex
	} else {
		$global:icurrent=$Playlist.SelectedIndex - 1
	}
	NextTrack
})
$VolumeSlider=$Window.FindName("Volume")
$VolumeSlider.Value=$mediaPlayer.Volume
$VolumeSlider.Add_PreviewMouseUp({
	closeMenus
	$global:UnMaxxed=$VolumeSlider.Value
	$global:UnMutedVolume=$VolumeSlider.Value
	if($Muted -eq 1){
		$MuteImage.ImageSource=$resourcepath + 'UnMuted.png'
		$global:Muted=0		
	}
	if($VolMax -eq 1){
		$global:VolMax=0		
	}
	$mediaPlayer.Volume=$VolumeSlider.Value
	if($mediaPlayer.Volume -lt 0.1){
		$MaxVolume.Width=20
	} else {
		$MaxVolume.Width=28
	}
	if($mediaPlayer.Volume -eq 1){
		$MaxVolume.Width=35
	}
	$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
	$VolumePercent2.Text=$VolumePercent1.Text
	$VolumePercent3.Text=$VolumePercent1.Text
	$VolumePercent4.Text=$VolumePercent1.Text
	$VolumePercent5.Text=$VolumePercent1.Text
})
$MaxVolume=$Window.FindName("MaxVolume")
$MaxVolume.Add_Click({
	closeMenus
	if(!($UnMaxxed -eq 1)){
		Switch($VolMax){
			0{
				$global:UnMaxxed=$mediaPlayer.Volume
				if($Muted -eq 1){
					$MuteImage.ImageSource=$resourcepath + 'UnMuted.png'
					$global:UnMutedVolume=0.5
					$global:UnMaxxed=0.5
					$global:Muted=0
				}
				$mediaPlayer.Volume=1
				$MaxVolume.Width=35
				$VolumeSlider.Value=$mediaPlayer.Volume
				$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
				$VolumePercent2.Text=$VolumePercent1.Text
				$VolumePercent3.Text=$VolumePercent1.Text
				$VolumePercent4.Text=$VolumePercent1.Text
				$VolumePercent5.Text=$VolumePercent1.Text
				$global:VolMax=1
			}
			1{
				$mediaPlayer.Volume=$UnMaxxed
				if($mediaPlayer.Volume -lt 0.1){
					$MaxVolume.Width=20
				} else {
					$MaxVolume.Width=28
				}
				$VolumeSlider.Value=$mediaPlayer.Volume
				$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
				$VolumePercent2.Text=$VolumePercent1.Text
				$VolumePercent3.Text=$VolumePercent1.Text
				$VolumePercent4.Text=$VolumePercent1.Text
				$VolumePercent5.Text=$VolumePercent1.Text
				$global:VolMax=0
			}
		}
	}
})
$PositionSlider=$Window.FindName("Position")
$PositionSlider.Add_PreviewMouseUp({
	$mediaPlayer.Position=("{0:hh\:mm\:ss\.fff}" -f ([timespan]::fromseconds([Math]::Truncate($PositionSlider.Value))))
	$global:tracking=0
})
$PositionSlider.Add_PreviewMouseDown({
	closeMenus
	$global:tracking=1
})
$TimeLeft=$Window.FindName("TimeLeft")
$TimeLeft.Add_Click({
	Switch($CounterB){
		0{
			$global:CounterB=1
			$TimeLeft.Width=40
		}
		1{
			$global:CounterB=0
			$TimeLeft.Width=35
			$TimerB1.Text=("{0:mm\:ss}" -f $ReadableTotal)
			$TimerB2.Text=$TimerB1.Text
			$TimerB3.Text=$TimerB1.Text
			$TimerB4.Text=$TimerB1.Text
			$TimerB5.Text=$TimerB1.Text	
		}
	}
})
$background=$Window.FindName("Background")
$background.Source=$resourcepath + 'bg.gif'
$background.Position=New-Object System.TimeSpan(0, 0, 0, 1, 0)
$background.Add_MediaEnded({
	if($Playing -eq 1){
		$background.Position=New-Object System.TimeSpan(0, 0, 0, 0, 1)
	}
})
$backgroundstatic=$Window.FindName("BackgroundStatic")
$backgroundstatic.Source=$resourcepath + 'bg.gif'
$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap=$background.Source
$window.Icon=$bitmap
$window.TaskbarItemInfo.Overlay=$bitmap
$window.TaskbarItemInfo.Description=$window.Title
$window.add_MouseLeftButtonDown({
	closeMenus
	$window.DragMove()
})
$StatusInfo1=$Window.FindName("Status1")
$StatusInfo2=$Window.FindName("Status2")
$StatusInfo3=$Window.FindName("Status3")
$StatusInfo4=$Window.FindName("Status4")
$StatusInfo5=$Window.FindName("Status5")
$StatusInfo1.Text=''
$CurrentTrack1=$Window.FindName("CurrentTrack1")
$CurrentTrack2=$Window.FindName("CurrentTrack2")
$CurrentTrack3=$Window.FindName("CurrentTrack3")
$CurrentTrack4=$Window.FindName("CurrentTrack4")
$CurrentTrack5=$Window.FindName("CurrentTrack5")
$TimerA1=$Window.FindName("TimerA1")
$TimerA2=$Window.FindName("TimerA2")
$TimerA3=$Window.FindName("TimerA3")
$TimerA4=$Window.FindName("TimerA4")
$TimerA5=$Window.FindName("TimerA5")
$TimerB1=$Window.FindName("TimerB1")
$TimerB2=$Window.FindName("TimerB2")
$TimerB3=$Window.FindName("TimerB3")
$TimerB4=$Window.FindName("TimerB4")
$TimerB5=$Window.FindName("TimerB5")
$VolumePercent1=$Window.FindName("VolumePercent1")
$VolumePercent2=$Window.FindName("VolumePercent2")
$VolumePercent3=$Window.FindName("VolumePercent3")
$VolumePercent4=$Window.FindName("VolumePercent4")
$VolumePercent5=$Window.FindName("VolumePercent5")
$VolumePercent1.Text=([double]$mediaPlayer.Volume).tostring("P0")
$VolumePercent2.Text=$VolumePercent1.Text
$VolumePercent3.Text=$VolumePercent1.Text
$VolumePercent4.Text=$VolumePercent1.Text
$VolumePercent5.Text=$VolumePercent1.Text
$MenuMain=$Window.FindName("Menu")
$MenuMain.Add_MouseEnter({
	$MenuMain.Background='#222222'
})
$MenuMain.Add_MouseLeave({
	$MenuMain.Background='#111111'
})
$MenuMain.Add_Click({
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.SelectedIndex=$icurrent
		toggleFlyOut
	}
	dropDownMenu
})
$ButtonData=$Window.FindName("ButtonData")
$MenuPlaylist1=$Window.FindName("MenuPlaylist1")
$MenuPlaylist1.Add_MouseEnter({
	$MenuPlaylist1.Background='#222222'
})
$MenuPlaylist1.Add_MouseLeave({
	$MenuPlaylist1.Background='#111111'
})
$MenuPlaylist1.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	toggleFlyout
})
$MenuPlaylist2=$Window.FindName("MenuPlaylist2")
$MenuPlaylist2.Add_MouseEnter({
	$MenuPlaylist2.Background='#222222'
})
$MenuPlaylist2.Add_MouseLeave({
	$MenuPlaylist2.Background='#111111'
})
$MenuPlaylist2.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	toggleFlyout
})
$MenuFile=$Window.FindName("File")
$MenuFile.Add_MouseEnter({
	$MenuFile.Background='#222222'
})
$MenuFile.Add_MouseLeave({
	$MenuFile.Background='#111111'
})
$MenuFile.Add_Click({
	dropDownMenu
	$getFile=New-Object System.Windows.Forms.OpenFileDialog -Property @{
		InitialDirectory="$env:UserProfile\Music"
		Title='Select a MP3 file...'
		Filter='MP3 (*.mp3)|*.mp3'
	}
	$filePicker=$getFile.ShowDialog()
	if($getFile.Filename -ne ""){
		$file=$getFile.Filename
		$global:singlefilemode=1
		$global:icurrent=-1
		$global:Playing=0
		$path = Split-Path $file -Parent
		$path = $path+'\'
		$files=$null
		$files=@()
		$files+=Split-Path $file -leaf
		if($Playing -eq 0){
			TogglePlayButton
		}
		$Playlist.ItemsSource=$files -ireplace ".mp3$",''
		if($files -ne ""){
			if($MenuPlaylist2.Visibility -ne "Visible"){
				$MenuPlaylist1.Visibility="Visible"
			}
		}
		NextTrack
		FileIdle
	}
})
$MenuFolder=$Window.FindName("Folder")
$MenuFolder.Add_MouseEnter({
	$MenuFolder.Background='#222222'
})
$MenuFolder.Add_MouseLeave({
	$MenuFolder.Background='#111111'
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
	if($OpenFileDialog.FileName -ne ""){
		$global:singlefilemode=0
		$path = $OpenFileDialog.FileName+'\'
		$files=$null
		$files=@()
		Get-ChildItem -Path $path -Filter *.mp3 -File -Name| ForEach-Object {
			$files+=$_
		}
		if($ShuffleOn -eq 1){
			$filesShuffled=$files | Sort-Object {Get-Random}			
			$Playlist.ItemsSource=$filesShuffled -ireplace ".mp3$",''
		} else {
			$Playlist.ItemsSource=$files -ireplace ".mp3$",''
		}
		if($Repeating -eq 1){
			$global:icurrent=0			
		}
		if($Playing -eq 0){
			TogglePlayButton
		} else {
			$global:icurrent=-1
		}
		if($files -ne ""){
			if($MenuPlaylist2.Visibility -ne "Visible"){
				$MenuPlaylist1.Visibility="Visible"
			}
		}
		FolderIdle
	}
})
$MenuExit=$Window.FindName("Exit")
$MenuExit.Add_MouseEnter({
	$MenuExit.Background='#222222'
})
$MenuExit.Add_MouseLeave({
	$MenuExit.Background='#111111'
})
$MenuExit.Add_Click({
	$window.Close()
	Exit
})
$minWin=$Window.FindName("minWin")
$minWin.Add_MouseEnter({
	$minWin.Background='#222222'
})
$minWin.Add_MouseLeave({
	$minWin.Background='#111111'
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
})
$Xbutton.Add_MouseLeave({
	$Xbutton.Background='#111111'
})
$Xbutton.Add_Click({
	$window.Close()
	Exit
})
$Shuffle=$Window.FindName("Shuffle")
$ShuffleImage=$Window.FindName("ShuffleButton")
$ShuffleImage.ImageSource=$resourcepath + 'Shuffle.png'
$Shuffle.Add_MouseEnter({
	$Shuffle.Background='#6c9bf0'
	$Shuffle.Opacity='0.95'
})
$Shuffle.Add_MouseLeave({
	$Shuffle.Background='#6495ED'
	$Shuffle.Opacity='0.85'
})
$Shuffle.Add_Click({
	closeMenus
	Switch($ShuffleOn){
		0{
			$Shuffle.BorderBrush='#5D3FD3'
			$global:ShuffleOn=1
			$global:filesShuffled=$files | Sort-Object {Get-Random}
			$Playlist.ItemsSource=$filesShuffled -ireplace ".mp3$",''
		}
		1{
			$Shuffle.BorderBrush='#728FCE'
			$global:ShuffleOn=0
			$Playlist.ItemsSource=$files -ireplace ".mp3$",''
		}
	}
})
$Prev=$Window.FindName("Prev")
$PrevImage=$Window.FindName("PrevButton")
$PrevImage.ImageSource=$resourcepath + 'Prev.png'
$Prev.Add_MouseEnter({
	$Prev.Background='#6c9bf0'
	$Prev.Opacity='0.95'
})
$Prev.Add_MouseLeave({
	$Prev.Background='#6495ED'
	$Prev.Opacity='0.85'
})
$Prev.Add_Click({
	closeMenus
	$checkposition=$mediaPlayer.Position.ToString()
	[int]$checkposition=$checkposition.Replace("(?=[.]).*",'').Replace(':','')
	if($Playing -eq 0){
		PrevTrack
	} else {
		if($checkposition -le 2){
			if($singlefilemode -eq 1){
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
$PlayImage.ImageSource=$resourcepath + 'Play.png'
$Play.Add_MouseEnter({
	$Play.Background='#6c9bf0'
	$Play.Opacity='0.95'
})
$Play.Add_MouseLeave({
	$Play.Background='#6495ED'
	$Play.Opacity='0.85'
})
$Play.Add_Click({
	closeMenus
	TogglePlayButton
})
$Next=$Window.FindName("Next")
$NextImage=$Window.FindName("NextButton")
$NextImage.ImageSource=$resourcepath + 'Next.png'
$Next.Add_MouseEnter({
	$Next.Background='#6c9bf0'
	$Next.Opacity='0.95'
})
$Next.Add_MouseLeave({
	$Next.Background='#6495ED'
	$Next.Opacity='0.85'
})
$Next.Add_Click({
	closeMenus
	if($Playing -eq 0){
		if($CurrentTrack1.Text -ne 'No Media Loaded'){
			NextTrack		
		}
	} else {
		if($singlefilemode -eq 1){
			if($icurrent -eq $files.Length - 1){
				$global:icurrent--
			}
		} else {
			if($Repeating -ne 0){
				if($icurrent -eq $files.Length - 1){
					$global:icurrent=-1
				}
			}
		}
		NextTrack
	}
})
$Repeat=$Window.FindName("Repeat")
$RepeatImage=$Window.FindName("RepeatButton")
$RepeatImage.ImageSource=$resourcepath + 'RepeatAll.png'
$Repeat.Add_MouseEnter({
	$Repeat.Background='#6c9bf0'
	$Repeat.Opacity='0.95'
})
$Repeat.Add_MouseLeave({
	$Repeat.Background='#6495ED'
	$Repeat.Opacity='0.85'
})
$Repeat.Add_Click({
	closeMenus
	Switch($Repeating){
		0{
			$RepeatImage.ImageSource=$resourcepath + 'RepeatOne.png'
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=1
		}
		1{
			$RepeatImage.ImageSource=$resourcepath + 'RepeatAll.png'
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=2
		}
		2{
			$RepeatImage.ImageSource=$resourcepath + 'RepeatAll.png'
			$Repeat.BorderBrush='#6495ED'
			$global:Repeating=0
		}
	}
})
$window.Show()
$window.Activate() | Out-Null
$background.Play()
$background.Pause()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)