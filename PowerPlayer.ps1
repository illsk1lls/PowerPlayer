Add-Type -MemberDefinition '[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Namespace Win32 -Name Functions
$closeConsoleUseGUI=[Win32.Functions]::ShowWindow((Get-Process -Id $PID).MainWindowHandle,0)
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
			. $PSCommandPath
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
$global:ShowPlaylist=0
$global:tracking=0
$global:icurrent=-1
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
function TogglePlayButton(){
	if($files -ne $null){
		Switch($Playing){
			0{
				$PlayImage.Source=$resourcepath + 'Pause.png'
				$mediaPlayer.Play()
				$global:Playing=1
				$StatusInfo.Text="Now Playing:"
				$background.Play()
			}
			1{
				$PlayImage.Source=$resourcepath + 'Play.png'
				$mediaPlayer.Pause()
				$global:Playing=0
				$StatusInfo.Text="Paused:"
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
	$Shell = New-Object -COMObject Shell.Application
	$FolderL = $shell.Namespace($(Split-Path $FullName))
	$FileL = $FolderL.ParseName($(Split-Path $FullName -Leaf))
	[int]$h, [int]$m, [int]$s = ($FolderL.GetDetailsOf($FileL, 27)).split(":")
	$global:totaltime=$h*60*60 + $m*60 +$s
	$ReadableTotal=[timespan]::fromseconds($totaltime - 2)
	$TimerB.Text=("{0:mm\:ss}" -f $ReadableTotal)
	$PositionSlider.Maximum=$totaltime
}
function WaitForSong(){
	while(([Math]::Ceiling(([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds)) -lt ([ref] $totaltime).Value){
		if(([ref] $tracking).Value -eq 0){
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
			<Setter Property="Foreground" Value="#728FCE"/>
			<Setter Property="Background" Value="Transparent"/>
			<Setter Property="Width" Value="8"/>
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
			<Setter Property="Background" Value="#222222"/>
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
			<Setter Property="Foreground" Value="#CCCCCC"/>
			<Style.Triggers>
				<Trigger Property="ItemsControl.AlternationIndex" Value="1">                            
					<Setter Property="Background" Value="#111111"/>
					<Setter Property="Foreground" Value="#CCCCCC"/>                                
				</Trigger>                            
			</Style.Triggers>
		</Style>
    </Window.Resources>
    <Border CornerRadius="5" BorderBrush="#111111" BorderThickness="10" Background="#111111">
        <Grid Name="MainWindow">
            <MediaElement Name="Background" Height="300" Width="500" LoadedBehavior="Manual" Stretch="Fill" SpeedRatio="1" IsMuted="True"/>
            <Canvas>
                <TextBlock Canvas.Left="90" Canvas.Top="74" Foreground="#CCCCCC">
                    <TextBlock.Inlines>
                        <Run Name="Status" FontStyle="Italic"/>
                    </TextBlock.Inlines>
                </TextBlock>
                <TextBlock Name="CurrentTrack" Canvas.Top="135" Foreground="#CCCCCC" FontSize="16" FontWeight="Bold" Text="No Media Loaded" TextAlignment="Center" Width="490"/>
                <Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Template="{StaticResource NoMouseOverButtonTemplate}">Menu</Button>
                <Button Name="MenuPlaylist" Canvas.Left="207" Canvas.Top="0" Visibility="Hidden" FontSize="10" BorderBrush="#111111" Foreground="#CCCCCC" Background="#111111" Height="18" Width="70" Template="{StaticResource NoMouseOverButtonTemplate}">Playlist</Button>
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
				<ListBox Canvas.Left="80" Canvas.Top="18" Name="Playlist" Visibility="Hidden" Foreground="#DDDDDD" Width="320" Height="245" Opacity="0.95" ItemsSource="{Binding ActorList}" Style="{DynamicResource lbStyle}" AlternationCount="2" ItemContainerStyle="{StaticResource AlternatingRowStyle}"/>
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
	$MenuPlaylist.Visibility="Hidden"
	$global:icurrent=-1
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$mediaPlayer.Stop()
	$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
	$PlayImage.Source=$resourcepath + 'Play.png'
	$CurrentTrack.Text='No Media Loaded'
	$background.Stop()
	$global:Playing=0
	$StatusInfo.Text=''
	$TimerA.Text=''
	$TimerB.Text=''
	}
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
	Switch($Muted){
		0{
			$MuteImage.Source=$resourcepath + 'Muted.png'
			$global:UnMutedVolume=$mediaPlayer.Volume
			$mediaPlayer.Volume=0
			$global:Muted=1
			$VolumeSlider.Value=$mediaPlayer.Volume
			$VolumePercent.Text=([double]$mediaPlayer.Volume).tostring("P0")
		}
		1{
			if($UnMutedVolume -eq $null){
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
$Playlist=$Window.FindName('Playlist')
$Playlist.Add_MouseDoubleClick({
	$global:icurrent=$Playlist.SelectedIndex - 1
	NextTrack
})
$VolumeSlider=$Window.FindName("Volume")
$VolumeSlider.Value=$mediaPlayer.Volume
$VolumeSlider.Add_PreviewMouseUp({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
	$global:tracking=1
})
$background=$Window.FindName("Background")
$background.Source=$resourcepath + 'bg.gif'
$background.Position=New-Object System.TimeSpan(0, 0, 0, 1, 0)
$background.Add_MediaEnded({
	if($Playing -eq 1){
		$background.Position=New-Object System.TimeSpan(0, 0, 0, 0, 1)
	}
})
$bitmap=New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap=$background.Source
$window.Icon=$bitmap
$window.TaskbarItemInfo.Overlay=$bitmap
$window.TaskbarItemInfo.Description=$window.Title
$window.add_MouseLeftButtonDown({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent		
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
	dropDownMenu
})
$MenuPlaylist=$Window.FindName("MenuPlaylist")
$MenuPlaylist.Add_MouseEnter({
	$MenuPlaylist.Background='#222222'
	$MenuPlaylist.Foreground='#CCCCCC'
})
$MenuPlaylist.Add_MouseLeave({
	$MenuPlaylist.Background='#111111'
	$MenuPlaylist.Foreground='#CCCCCC'
})
$MenuPlaylist.Add_Click({
	if($MenuFile.Visibility -eq 'Visible'){
		dropDownMenu
	}
	Switch($ShowPlaylist){
		0{
			$Playlist.Visibility="Visible"
			$global:ShowPlaylist=1
		}
		1{
			$Playlist.Visibility="Hidden"
			$global:ShowPlaylist=0
			$Playlist.SelectedIndex=$icurrent
		}
	}
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
		$Playlist.ItemsSource=$files -ireplace '.mp3$',''
		if($files -ne ""){
		$MenuPlaylist.Visibility="Visible"
		}
		NextTrack
		FileIdle
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
			$Playlist.ItemsSource=$filesShuffled
		} else {
			$Playlist.ItemsSource=$files -ireplace '.mp3$',''
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
		$MenuPlaylist.Visibility="Visible"
		}
		FolderIdle
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
	$window.Close()
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
	$window.Close()
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
	Switch($ShuffleOn){
		0{
			$Shuffle.BorderBrush='#5D3FD3'
			$global:ShuffleOn=1
			$global:filesShuffled=$files | Sort-Object {Get-Random}
			$Playlist.ItemsSource=$filesShuffled -ireplace '.mp3$',''
		}
		1{
			$Shuffle.BorderBrush='#728FCE'
			$global:ShuffleOn=0
			$Playlist.ItemsSource=$files -ireplace '.mp3$',''
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
	if($Playing -eq 0){
		if($CurrentTrack.Text -ne 'No Media Loaded'){
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
	if($Playlist.Visibility -eq 'Visible'){
		$Playlist.Visibility="Hidden"
		$global:ShowPlaylist=0
		$Playlist.SelectedIndex=$icurrent
	}
	Switch($Repeating){
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
$window.Show()
$window.Activate() | Out-Null
$background.Play()
$background.Pause()
$appContext=New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)