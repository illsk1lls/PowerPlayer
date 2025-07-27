<# :: Hybrid CMD / Powershell Launcher - Rename file to .CMD to Autolaunch with console settings (Double-Click) - Rename to .PS1 to run as Powershell script without console settings
@ECHO OFF
SET "0=%~f0"&SET "LEGACY={B23D10C0-E52E-411E-9D5B-C09FDF709C7D}"&SET "LETWIN={00000000-0000-0000-0000-000000000000}"&SET "TERMINAL={2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"&SET "TERMINAL2={E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"
POWERSHELL -nop -c "Get-WmiObject -Class Win32_OperatingSystem | Select -ExpandProperty Caption | Find 'Windows 11'">nul
IF ERRORLEVEL 0 (
	SET isEleven=1
	>nul 2>&1 REG QUERY "HKCU\Console\%%%%Startup" /v DelegationConsole
	IF ERRORLEVEL 1 (
		REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%LETWIN%" /f>nul
		REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%LETWIN%" /f>nul
	)
	FOR /F "usebackq tokens=3" %%# IN (`REG QUERY "HKCU\Console\%%%%Startup" /v DelegationConsole 2^>nul`) DO (
		IF NOT "%%#"=="%LEGACY%" (
			SET "DEFAULTCONSOLE=%%#"
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%LEGACY%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%LEGACY%" /f>nul
		)
	)
)
START /MIN "" POWERSHELL -nop -c "iex ([io.file]::ReadAllText('%~f0'))">nul
IF "%isEleven%"=="1" (
	IF DEFINED DEFAULTCONSOLE (
		IF "%DEFAULTCONSOLE%"=="%TERMINAL%" (
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%TERMINAL%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%TERMINAL2%" /f>nul
		) ELSE (
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationConsole /t REG_SZ /d "%DEFAULTCONSOLE%" /f>nul
			REG ADD "HKCU\Console\%%%%Startup" /v DelegationTerminal /t REG_SZ /d "%DEFAULTCONSOLE%" /f>nul
		)
	)
)
EXIT
#>if($env:0){$PSCommandPath="$env:0"}
Add-Type -MemberDefinition '[DllImport("User32.dll")]public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);' -Namespace Win32 -Name Functions
$closeConsoleUseGUI=[Win32.Functions]::ShowWindow((Get-Process -Id $PID).MainWindowHandle,0)
$AppId='PowerPlayer';$oneInstance=$false
$script:SingleInstanceEvent=New-Object Threading.EventWaitHandle $true,([Threading.EventResetMode]::ManualReset),"Global\PowerPlayer",([ref] $oneInstance)
if( -not $oneInstance){
	$alreadyRunning=New-Object -ComObject Wscript.Shell;$alreadyRunning.Popup("PowerPlayer is already running!",0,'ERROR:',0x0) | Out-Null
	Exit
}
$visualizer = @'
using System;
using System.Runtime.InteropServices;
using System.Threading;
using System.Numerics;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using System.Collections.Generic;

public class UnifiedVisualizer : FrameworkElement
{
	private List<Star> stars = new List<Star>();
	private List<Particle> particles = new List<Particle>();
	private Random rand = new Random();
	private double globalTime = 0;
	private double blinkSpeed = 0.05;
	private double colorSpeed = 0.03;
	private double pulseFrequency = 0.05;
	private double pulseAmplitude = 0.1;
	private double prevBassDB = double.NegativeInfinity;
	private double prevTrebleDB = double.NegativeInfinity;
	private double bassTriggerThreshold = 6.0;
	private double trebleTriggerThreshold = 3.0;
	private double starfieldOpacity = 1.0;
	private double fadeSpeed = 0.05;
	public DispatcherTimer timer;
	public AudioLevelCalculator AudioCalculator { get; set; }
	public double PulseFactor { get; set; }
	public double SpeedMultiplier { get; set; }

	public class Star
	{
		public double PosX { get; set; }
		public double PosY { get; set; }
		public double DirX { get; set; }
		public double DirY { get; set; }
		public double Speed { get; set; }
		public double Size { get; set; }
		public double BlinkPhase { get; set; }
		public double BlinkAmplitude { get; set; }
		public double CurveFactor { get; set; }
		public double ColorPhase { get; set; }
	}

	public class Particle
	{
		public double PosX { get; set; }
		public double PosY { get; set; }
		public double DirX { get; set; }
		public double DirY { get; set; }
		public double Speed { get; set; }
		public double Size { get; set; }
		public double DistTraveled { get; set; }
		public double MaxDist { get; set; }
		public double Strength { get; set; }
		public double CurveFactor { get; set; }
		public bool Switched { get; set; }
		public bool IsUp { get; set; }

	}

	public UnifiedVisualizer()
	{
		this.PulseFactor = 1.0;
		this.SpeedMultiplier = 0.7;

		int numStars = 225;
		for (int i = 0; i < numStars; i++)
		{
			double dirX = rand.NextDouble() * 2 - 1;
			double dirY = rand.NextDouble() * 2 - 1;
			double norm = Math.Sqrt(dirX * dirX + dirY * dirY);
			if (norm > 0)
			{
				dirX /= norm;
				dirY /= norm;
			}

			stars.Add(new Star
			{
				PosX = rand.NextDouble() * this.ActualWidth,
				PosY = rand.NextDouble() * this.ActualHeight,
				DirX = dirX,
				DirY = dirY,
				Speed = rand.NextDouble() * 0.5 + 0.1,
				Size = rand.NextDouble() * 5.5 + 0.5,
				BlinkPhase = rand.NextDouble() * Math.PI * 2,
				BlinkAmplitude = rand.NextDouble() * 0.3 + 0.2,
				CurveFactor = (rand.NextDouble() - 0.5) * 0.05,
				ColorPhase = rand.NextDouble() * Math.PI * 2
			});
		}

		timer = new DispatcherTimer();
		timer.Interval = TimeSpan.FromMilliseconds(16);
		timer.Tick += Timer_Tick;
		timer.Start();
	}

	private void CreateWave(bool isBass, double strength)
	{
		double centerX = this.ActualWidth / 2.0;
		double centerY = this.ActualHeight / 2.0;

		bool[] directions = new bool[] { true, false }; // up and down

		foreach (bool isUp in directions)
		{
			int numParticles = (int)(25 * strength) + 5; // Half for each direction

			for (int i = 0; i < numParticles; i++)
			{
				double startX = this.ActualWidth * ((double)i / (numParticles - 1));
				double lean = (startX - centerX) / centerX;

				double dirY = (isUp ? -1 : 1) * (0.7 + Math.Abs(lean) * 0.3);
				double dirX = lean * 1.0;
				double norm = Math.Sqrt(dirX * dirX + dirY * dirY);
				dirX /= norm;
				dirY /= norm;

				double particleSize;
				double particleSpeed;

				if (isBass)
				{
					particleSize = rand.NextDouble() * 4 + 2; // bigger for bass
					particleSpeed = (rand.NextDouble() * 3 + 1) * (1 + strength); // slower base, scales with strength
				}
				else
				{
					particleSize = rand.NextDouble() * 2 + 0.5; // smaller for treble
					particleSpeed = (rand.NextDouble() * 6 + 3) * (1 + strength); // faster base, scales with strength
				}

				particles.Add(new Particle
				{
					PosX = startX,
					PosY = centerY,
					DirX = dirX,
					DirY = dirY,
					Speed = particleSpeed,
					Size = particleSize,
					DistTraveled = 0,
					MaxDist = Math.Max(this.ActualWidth, this.ActualHeight) / 1.5,
					Switched = false,
					CurveFactor = (rand.NextDouble() - 0.5) * 0.1,
					IsUp = isUp,
					Strength = strength
				});
			}
		}
	}

	private void Timer_Tick(object sender, EventArgs e)
	{
		globalTime += timer.Interval.TotalSeconds;

		if (ActualWidth <= 0 || ActualHeight <= 0)
		{
			return;
		}

		// Update stars
		foreach (var star in stars)
		{
			star.DirX += star.CurveFactor * 0.01;
			star.DirY += star.CurveFactor * 0.01;
			double norm = Math.Sqrt(star.DirX * star.DirX + star.DirY * star.DirY);
			if (norm > 0)
			{
				star.DirX /= norm;
				star.DirY /= norm;
			}

			double moveDist = star.Speed;
			star.PosX += star.DirX * moveDist;
			star.PosY += star.DirY * moveDist;

			if (star.PosX < 0) star.PosX += this.ActualWidth;
			if (star.PosX > this.ActualWidth) star.PosX -= this.ActualWidth;
			if (star.PosY < 0) star.PosY += this.ActualHeight;
			if (star.PosY > this.ActualHeight) star.PosY -= this.ActualHeight;
		}

		// Update particles
		double currentBassDB = double.NegativeInfinity;
		double currentTrebleDB = double.NegativeInfinity;
		if (AudioCalculator != null)
		{
			currentBassDB = AudioCalculator.LatestBassRMSDB;
			currentTrebleDB = AudioCalculator.LatestTrebleRMSDB;
		}

		if (currentBassDB > prevBassDB + bassTriggerThreshold)
		{
			double strength = Math.Max(0, Math.Min(1, (currentBassDB + 60) / 60));
			CreateWave(true, strength);
		}
		if (currentTrebleDB > prevTrebleDB + trebleTriggerThreshold)
		{
			double strength = Math.Max(0, Math.Min(1, (currentTrebleDB + 60) / 60));
			CreateWave(false, strength);
		}
		prevBassDB = currentBassDB;
		prevTrebleDB = currentTrebleDB;

		for (int i = particles.Count - 1; i >= 0; i--)
		{
			var p = particles[i];
			double moveDist = p.Speed * SpeedMultiplier;
			p.DistTraveled += moveDist;

			if (p.DistTraveled > p.MaxDist * 0.2)
			{
				p.DirX *= 0.97;
			}

			p.DirX += p.CurveFactor * (moveDist / p.MaxDist);
			double norm = Math.Sqrt(p.DirX * p.DirX + p.DirY * p.DirY);
			if (norm > 0)
			{
				p.DirX /= norm;
				p.DirY /= norm;
			}

			p.PosX += p.DirX * moveDist;
			p.PosY += p.DirY * moveDist;

			if (p.DistTraveled > p.MaxDist || p.PosX < 0 || p.PosX > this.ActualWidth || p.PosY < 0 || p.PosY > this.ActualHeight || Math.Abs(p.DirY) < 0.01)
			{
				particles.RemoveAt(i);
			}
		}

		// Adjust starfield opacity
		if (particles.Count > 0)
		{
			starfieldOpacity = Math.Max(0, starfieldOpacity - fadeSpeed);
		}
		else
		{
			starfieldOpacity = Math.Min(1, starfieldOpacity + fadeSpeed);
		}

		this.InvalidateVisual();
	}

	protected override void OnRender(DrawingContext drawingContext)
	{
		double rmsDB = double.NegativeInfinity;
		if (AudioCalculator != null)
		{
			rmsDB = AudioCalculator.LatestRMSDB;
		}
		double normalized = (rmsDB == double.NegativeInfinity) ? 0 : Math.Max(0, Math.Min(1, (rmsDB + 60) / 60));

		double lineLength = this.ActualWidth * normalized;
		double centerX = this.ActualWidth / 2;
		double centerY = this.ActualHeight / 2;
		double startX = centerX - lineLength / 2;
		double endX = centerX + lineLength / 2;
		double upperY = centerY - 12; // Upper line 12 pixels above center
		double lowerY = centerY + 12; // Lower line 12 pixels below center

		Color centerColor = Color.FromRgb(0, 191, 255);
		Color endColor = Color.FromRgb((byte)(148 * normalized), 0, (byte)(211 * normalized));

		if (lineLength > 0)
		{
			// Draw upper line
			LinearGradientBrush upperLeftBrush = new LinearGradientBrush();
			upperLeftBrush.MappingMode = BrushMappingMode.Absolute;
			upperLeftBrush.StartPoint = new Point(startX, upperY);
			upperLeftBrush.EndPoint = new Point(centerX, upperY);
			upperLeftBrush.GradientStops.Add(new GradientStop(endColor, 0.0));
			upperLeftBrush.GradientStops.Add(new GradientStop(centerColor, 1.0));

			Pen upperLeftPen = new Pen(upperLeftBrush, 1.0);
			drawingContext.DrawLine(upperLeftPen, new Point(startX, upperY), new Point(centerX, upperY));

			LinearGradientBrush upperRightBrush = new LinearGradientBrush();
			upperRightBrush.MappingMode = BrushMappingMode.Absolute;
			upperRightBrush.StartPoint = new Point(centerX, upperY);
			upperRightBrush.EndPoint = new Point(endX, upperY);
			upperRightBrush.GradientStops.Add(new GradientStop(centerColor, 0.0));
			upperRightBrush.GradientStops.Add(new GradientStop(endColor, 1.0));

			Pen upperRightPen = new Pen(upperRightBrush, 1.0);
			drawingContext.DrawLine(upperRightPen, new Point(centerX, upperY), new Point(endX, upperY));

			// Draw lower line
			LinearGradientBrush lowerLeftBrush = new LinearGradientBrush();
			lowerLeftBrush.MappingMode = BrushMappingMode.Absolute;
			lowerLeftBrush.StartPoint = new Point(startX, lowerY);
			lowerLeftBrush.EndPoint = new Point(centerX, lowerY);
			lowerLeftBrush.GradientStops.Add(new GradientStop(endColor, 0.0));
			lowerLeftBrush.GradientStops.Add(new GradientStop(centerColor, 1.0));

			Pen lowerLeftPen = new Pen(lowerLeftBrush, 1.0);
			drawingContext.DrawLine(lowerLeftPen, new Point(startX, lowerY), new Point(centerX, lowerY));

			LinearGradientBrush lowerRightBrush = new LinearGradientBrush();
			lowerRightBrush.MappingMode = BrushMappingMode.Absolute;
			lowerRightBrush.StartPoint = new Point(centerX, lowerY);
			lowerRightBrush.EndPoint = new Point(endX, lowerY);
			lowerRightBrush.GradientStops.Add(new GradientStop(centerColor, 0.0));
			lowerRightBrush.GradientStops.Add(new GradientStop(endColor, 1.0));

			Pen lowerRightPen = new Pen(lowerRightBrush, 1.0);
			drawingContext.DrawLine(lowerRightPen, new Point(centerX, lowerY), new Point(endX, lowerY));
		}

		double pulse = 1 + pulseAmplitude * Math.Sin(globalTime * pulseFrequency * 2 * Math.PI);
		double effectivePulse = pulse * PulseFactor;

		foreach (var p in particles)
		{
			double effectiveSize = p.Size * effectivePulse * (1 - (p.DistTraveled / p.MaxDist));

			if (effectiveSize > 0)
			{
				int alpha = (int)Math.Min(255, 255 * (1 - (p.DistTraveled / p.MaxDist)));
				Color pColor1 = Color.FromRgb(0, 191, 255);
				Color pColor2 = Color.FromRgb(148, 0, 211);
				double colorFactor = p.Strength * 0.8;
				byte r = (byte)(pColor1.R * (1 - colorFactor) + pColor2.R * colorFactor);
				byte green = (byte)(pColor1.G * (1 - colorFactor) + pColor2.G * colorFactor);
				byte b = (byte)(pColor1.B * (1 - colorFactor) + pColor2.B * colorFactor);
				Color color = Color.FromArgb((byte)alpha, r, green, b);

				SolidColorBrush brush = new SolidColorBrush(color);
				drawingContext.DrawEllipse(brush, null, new Point(p.PosX, p.PosY), effectiveSize / 2, effectiveSize / 2);
			}
		}

		Color sColor1 = Color.FromRgb(0, 191, 255);
		Color sColor2 = Color.FromRgb(148, 0, 211);

		foreach (var star in stars)
		{
			double blink = 0.3 + star.BlinkAmplitude * (Math.Sin(globalTime * blinkSpeed + star.BlinkPhase) + 1) / 2;
			byte alpha = (byte)(Math.Min(255, 255 * blink * starfieldOpacity));

			double colorFactor = (Math.Sin(globalTime * colorSpeed + star.ColorPhase) + 1) / 2;
			byte r = (byte)(sColor1.R * (1 - colorFactor) + sColor2.R * colorFactor);
			byte green = (byte)(sColor1.G * (1 - colorFactor) + sColor2.G * colorFactor);
			byte b = (byte)(sColor1.B * (1 - colorFactor) + sColor2.B * colorFactor);

			Color color = Color.FromArgb(alpha, r, green, b);

			SolidColorBrush brush = new SolidColorBrush(color);
			drawingContext.DrawEllipse(brush, null, new Point(star.PosX, star.PosY), star.Size / 2, star.Size / 2);
		}
	}

	protected override void OnRenderSizeChanged(SizeChangedInfo sizeInfo)
	{
		base.OnRenderSizeChanged(sizeInfo);
		foreach (var star in stars)
		{
			star.PosX = rand.NextDouble() * this.ActualWidth;
			star.PosY = rand.NextDouble() * this.ActualHeight;

			star.DirX = rand.NextDouble() * 2 - 1;
			star.DirY = rand.NextDouble() * 2 - 1;
			double norm = Math.Sqrt(star.DirX * star.DirX + star.DirY * star.DirY);
			if (norm > 0)
			{
				star.DirX /= norm;
				star.DirY /= norm;
			}
		}
	}
}

public class AudioLevelCalculator
{
	public enum EDataFlow
	{
		eRender = 0,
		eCapture = 1,
		eAll = 2
	}

	public enum ERole
	{
		eConsole = 0,
		eMultimedia = 1,
		eCommunications = 2
	}

	public enum AUDCLNT_SHAREMODE
	{
		AUDCLNT_SHAREMODE_SHARED,
		AUDCLNT_SHAREMODE_EXCLUSIVE
	}

	[Flags]
	public enum AUDCLNT_STREAMFLAGS : uint
	{
		AUDCLNT_STREAMFLAGS_LOOPBACK = 0x00020000
	}

	public enum CLSCTX : uint
	{
		CLSCTX_ALL = 0x17
	}

	[StructLayout(LayoutKind.Sequential, Pack = 2)]
	public struct WAVEFORMATEX
	{
		public ushort wFormatTag;
		public ushort nChannels;
		public uint nSamplesPerSec;
		public uint nAvgBytesPerSec;
		public ushort nBlockAlign;
		public ushort wBitsPerSample;
		public ushort cbSize;
	}

	[StructLayout(LayoutKind.Sequential, Pack = 2)]
	public struct WAVEFORMATEXTENSIBLE
	{
		public WAVEFORMATEX Format;
		public ushort wValidBitsPerSample;
		public uint dwChannelMask;
		public Guid SubFormat;
	}

	[ComImport]
	[Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
	internal class MMDeviceEnumerator { }

	[ComImport]
	[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	internal interface IMMDeviceEnumerator
	{
		void EnumAudioEndpoints(EDataFlow dataFlow, uint dwStateMask, out IMMDeviceCollection ppDevices);
		void GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice ppEndpoint);
	}

	[ComImport]
	[Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	internal interface IMMDeviceCollection
	{
		void GetCount(out uint pcDevices);
		void Item(uint nDevice, out IMMDevice ppDevice);
	}

	[ComImport]
	[Guid("D666063F-1587-4E43-81F1-B948E807363F")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	internal interface IMMDevice
	{
		void Activate(ref Guid iid, CLSCTX dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
	}

	[ComImport]
	[Guid("1CB9AD4C-DBFA-4c32-B178-C2F568A703B2")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	internal interface IAudioClient
	{
		void Initialize(AUDCLNT_SHAREMODE ShareMode, AUDCLNT_STREAMFLAGS StreamFlags, long hnsBufferDuration, long hnsPeriodicity, IntPtr pFormat, ref Guid AudioSessionGuid);
		void GetBufferSize(out uint pNumBufferFrames);
		void GetStreamLatency(out long phnsLatency);
		void GetCurrentPadding(out uint pNumPaddingFrames);
		void IsFormatSupported(AUDCLNT_SHAREMODE ShareMode, IntPtr pFormat, out IntPtr ppClosestMatch);
		void GetMixFormat(out IntPtr ppDeviceFormat);
		void GetDevicePeriod(out long phnsDefaultDevicePeriod, out long phnsMinimumDevicePeriod);
		void Start();
		void Stop();
		void Reset();
		void SetEventHandle(IntPtr eventHandle);
		void GetService(ref Guid riid, [MarshalAs(UnmanagedType.IUnknown)] out object ppv);
	}

	[ComImport]
	[Guid("C8ADBD64-E71E-48a0-A4DE-185C395CD317")]
	[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
	internal interface IAudioCaptureClient
	{
		void GetBuffer(out IntPtr ppData, out uint pNumFramesToRead, out uint pdwFlags, out long pu64DevicePosition, out long pu64QPCPosition);
		void ReleaseBuffer(uint numFramesRead);
		void GetNextPacketSize(out uint pNumFramesInNextPacket);
	}

	[DllImport("ole32.dll")]
	public static extern void CoTaskMemFree(IntPtr pv);

	private static readonly Guid KSDATAFORMAT_SUBTYPE_PCM = new Guid("00000001-0000-0010-8000-00aa00389b71");
	private static readonly Guid KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = new Guid("00000003-0000-0010-8000-00aa00389b71");

	private IAudioClient audioClient;
	private IAudioCaptureClient captureClient;
	private WAVEFORMATEX waveFormat;
	private Thread captureThread;
	private bool isCapturing;
	private double latestPeakDB = double.NegativeInfinity;
	private double latestRMSDB = double.NegativeInfinity;
	private double latestBassRMSDB = double.NegativeInfinity;
	private double latestTrebleRMSDB = double.NegativeInfinity;
	private readonly object lockObject = new object();
	private bool isFloat;
	private ushort bitsPerSample;

	public double LatestPeakDB
	{
		get
		{
			lock (lockObject)
			{
				return latestPeakDB;
			}
		}
	}

	public double LatestRMSDB
	{
		get
		{
			lock (lockObject)
			{
				return latestRMSDB;
			}
		}
	}

	public double LatestBassRMSDB
	{
		get
		{
			lock (lockObject)
			{
				return latestBassRMSDB;
			}
		}
	}

	public double LatestTrebleRMSDB
	{
		get
		{
			lock (lockObject)
			{
				return latestTrebleRMSDB;
			}
		}
	}

	public void StartCapture()
	{
		try
		{
			IMMDeviceEnumerator deviceEnumerator = (IMMDeviceEnumerator)new MMDeviceEnumerator();
			IMMDevice device;
			deviceEnumerator.GetDefaultAudioEndpoint(EDataFlow.eRender, ERole.eConsole, out device);

			Guid iidIAudioClient = typeof(IAudioClient).GUID;
			object o;
			device.Activate(ref iidIAudioClient, CLSCTX.CLSCTX_ALL, IntPtr.Zero, out o);
			audioClient = (IAudioClient)o;

			IntPtr pFormat;
			audioClient.GetMixFormat(out pFormat);
			waveFormat = (WAVEFORMATEX)Marshal.PtrToStructure(pFormat, typeof(WAVEFORMATEX));

			isFloat = false;
			bitsPerSample = waveFormat.wBitsPerSample;
			if (waveFormat.wFormatTag == 0xFFFE)
			{
				WAVEFORMATEXTENSIBLE extFormat = (WAVEFORMATEXTENSIBLE)Marshal.PtrToStructure(pFormat, typeof(WAVEFORMATEXTENSIBLE));
				if (extFormat.SubFormat == KSDATAFORMAT_SUBTYPE_IEEE_FLOAT)
				{
					isFloat = true;
				}
				else if (extFormat.SubFormat == KSDATAFORMAT_SUBTYPE_PCM)
				{
					isFloat = false;
				}
				else
				{
					CoTaskMemFree(pFormat);
					throw new Exception("Unsupported subformat in WAVEFORMATEXTENSIBLE");
				}
				bitsPerSample = extFormat.Format.wBitsPerSample;
			}
			else if (waveFormat.wFormatTag == 3)
			{
				isFloat = true;
			}
			else if (waveFormat.wFormatTag == 1)
			{
				isFloat = false;
			}
			else
			{
				CoTaskMemFree(pFormat);
				throw new Exception("Unsupported format tag");
			}

			if ((isFloat && bitsPerSample != 32 && bitsPerSample != 64) ||
				(!isFloat && bitsPerSample != 16 && bitsPerSample != 32))
			{
				CoTaskMemFree(pFormat);
				throw new Exception("Unsupported bit depth");
			}

			long bufferDuration = 10000000L / 10;
			Guid emptyGuid = Guid.Empty;
			audioClient.Initialize(AUDCLNT_SHAREMODE.AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS.AUDCLNT_STREAMFLAGS_LOOPBACK, bufferDuration, 0, pFormat, ref emptyGuid);
			CoTaskMemFree(pFormat);

			Guid iidIAudioCaptureClient = typeof(IAudioCaptureClient).GUID;
			object occ;
			audioClient.GetService(ref iidIAudioCaptureClient, out occ);
			captureClient = (IAudioCaptureClient)occ;

			audioClient.Start();

			isCapturing = true;
			captureThread = new Thread(CaptureLoop);
			captureThread.Start();
		}
		catch (Exception ex)
		{
			// For debugging, you can add a message box or log
			MessageBox.Show("Error starting capture: " + ex.Message);
		}
	}

	private static Complex[] ComputeFFT(double[] x)
	{
		int N = x.Length;
		Complex[] y = new Complex[N];

		if (N <= 1)
		{
			if (N == 1) y[0] = x[0];
			return y;
		}

		// Base case for N == 2
		if (N == 2)
		{
			y[0] = x[0] + x[1];
			y[1] = x[0] - x[1];
			return y;
		}

		// Split the input into two parts
		double[] x_even = new double[N / 2];
		double[] x_odd = new double[N / 2];
		for (int i = 0; i < N / 2; i++)
		{
			x_even[i] = x[2 * i];
			x_odd[i] = x[2 * i + 1];
		}

		// Recursively compute the FFT of each part
		Complex[] y_even = ComputeFFT(x_even);
		Complex[] y_odd = ComputeFFT(x_odd);

		// Combine the results
		for (int k = 0; k < N / 2; k++)
		{
			double angle = -2 * k * Math.PI / N;
			Complex w = Complex.FromPolarCoordinates(1, angle);
			y[k] = y_even[k] + w * y_odd[k];
			y[k + N / 2] = y_even[k] - w * y_odd[k];
		}

		return y;
	}

	private void CaptureLoop()
	{
		while (isCapturing)
		{
			Thread.Sleep(10);

			IntPtr pData;
			uint numFrames;
			uint flags;
			long pos;
			long qpc;
			captureClient.GetBuffer(out pData, out numFrames, out flags, out pos, out qpc);

			if (numFrames > 0)
			{
				int byteLength = (int)(numFrames * waveFormat.nBlockAlign);
				byte[] buffer = new byte[byteLength];
				Marshal.Copy(pData, buffer, 0, byteLength);

				int numSamples = (int)(numFrames * waveFormat.nChannels);
				double maxAbs = 0.0;
				double sumSquares = 0.0;
				int bytesPerSample = bitsPerSample / 8;

				for (int i = 0; i < byteLength; i += bytesPerSample)
			   {
					double norm;
					double value = 0.0;
					if (isFloat)
					{
						if (bitsPerSample == 32)
						{
							float sample = BitConverter.ToSingle(buffer, i);
							value = sample;
							norm = Math.Abs(sample);
						}
						else
						{
							double sample = BitConverter.ToDouble(buffer, i);
							value = sample;
							norm = Math.Abs(sample);
						}
					}
					else
					{
						if (bitsPerSample == 16)
						{
							short sample = BitConverter.ToInt16(buffer, i);
							value = sample / 32768.0;
							norm = Math.Abs(value);
						}
						else
						{
							int sample = BitConverter.ToInt32(buffer, i);
							value = sample / 2147483648.0;
							norm = Math.Abs(value);
						}
					}
					if (norm > maxAbs) maxAbs = norm;
					sumSquares += value * value;
				}

				double rms = (numSamples > 0) ? Math.Sqrt(sumSquares / numSamples) : 0.0;
				double peakDB = (maxAbs > 0) ? 20 * Math.Log10(maxAbs) : double.NegativeInfinity;
				double rmsDB = (rms > 0) ? 20 * Math.Log10(rms) : double.NegativeInfinity;

				double bassRMSDB = double.NegativeInfinity;
				double trebleRMSDB = double.NegativeInfinity;

				if (numFrames >= 4)
				{
					int log2N = (int)Math.Floor(Math.Log(numFrames, 2));
					int fftSize = 1 << log2N;
					if (fftSize >= 4)
					{
						double[] monoSamples = new double[fftSize];

						for (int frame = 0; frame < fftSize; frame++)
						{
							double sumChannels = 0.0;
							for (int ch = 0; ch < waveFormat.nChannels; ch++)
							{
								int offset = frame * waveFormat.nBlockAlign + ch * bytesPerSample;
								double value;
								if (isFloat)
								{
									if (bitsPerSample == 32)
									{
										value = BitConverter.ToSingle(buffer, offset);
									}
									else
									{
										value = BitConverter.ToDouble(buffer, offset);
									}
								}
								else
								{
									if (bitsPerSample == 16)
									{
										value = BitConverter.ToInt16(buffer, offset) / 32768.0;
									}
									else
									{
										value = BitConverter.ToInt32(buffer, offset) / 2147483648.0;
									}
								}
								sumChannels += value;
							}
							monoSamples[frame] = sumChannels / waveFormat.nChannels;
						}

						Complex[] spectrum = ComputeFFT(monoSamples);

						double deltaF = (double)waveFormat.nSamplesPerSec / fftSize;
						int nyquistBin = fftSize / 2;

						// Bass: 20-250 Hz
						int bassLowBin = (int)Math.Ceiling(20 / deltaF);
						int bassHighBin = (int)Math.Floor(250 / deltaF);
						if (bassHighBin > nyquistBin) bassHighBin = nyquistBin;
						double bassPower = 0.0;
						for (int k = bassLowBin; k <= bassHighBin; k++)
						{
							double mag2 = spectrum[k].Real * spectrum[k].Real + spectrum[k].Imaginary * spectrum[k].Imaginary;
							double factor = (k == 0 || k == nyquistBin) ? 1.0 : 2.0;
							bassPower += factor * mag2;
						}
						bassPower /= fftSize;
						double bassRMS = bassPower > 0 ? Math.Sqrt(bassPower) : 0;
						bassRMSDB = bassRMS > 0 ? 20 * Math.Log10(bassRMS) : double.NegativeInfinity;

						// Treble: 2000-20000 Hz
						int trebleLowBin = (int)Math.Ceiling(2000 / deltaF);
						int trebleHighBin = (int)Math.Floor(20000 / deltaF);
						if (trebleHighBin > nyquistBin) trebleHighBin = nyquistBin;
						double treblePower = 0.0;
						for (int k = trebleLowBin; k <= trebleHighBin; k++)
						{
							double mag2 = spectrum[k].Real * spectrum[k].Real + spectrum[k].Imaginary * spectrum[k].Imaginary;
							double factor = (k == 0 || k == nyquistBin) ? 1.0 : 2.0;
							treblePower += factor * mag2;
						}
						treblePower /= fftSize;
						double trebleRMS = treblePower > 0 ? Math.Sqrt(treblePower) : 0;
						trebleRMSDB = trebleRMS > 0 ? 20 * Math.Log10(trebleRMS) : double.NegativeInfinity;
					}
				}

				lock (lockObject)
				{
					latestPeakDB = peakDB;
					latestRMSDB = rmsDB;
					latestBassRMSDB = bassRMSDB;
					latestTrebleRMSDB = trebleRMSDB;
				}
			}

			captureClient.ReleaseBuffer(numFrames);
		}
	}

	public void StopCapture()
	{
		if (isCapturing)
		{
			isCapturing = false;
			captureThread.Join();
			audioClient.Stop();
		}
	}
}
'@
Add-Type -TypeDefinition $visualizer -ReferencedAssemblies PresentationFramework, PresentationCore, WindowsBase, System.Numerics, System.Xaml
$iconExtractor = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Interop;
using System.Windows.Media.Imaging;
using System.Windows;

namespace System
{
	public class IconExtractor
	{
		public static Icon Extract(string file, int number, bool largeIcon)
		{
			IntPtr large;
			IntPtr small;
			ExtractIconEx(file, number, out large, out small, 1);
			try
			{
				return Icon.FromHandle(largeIcon ? large : small);
			}
			catch
			{
				return null;
			}
		}
		public static BitmapSource IconToBitmapSource(Icon icon)
		{
			return Imaging.CreateBitmapSourceFromHIcon(
				icon.Handle,
				Int32Rect.Empty,
				BitmapSizeOptions.FromEmptyOptions());
		}
		[DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
		private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
	}
}
"@
Add-Type -TypeDefinition $iconExtractor -ReferencedAssemblies System.Windows.Forms, System.Drawing, PresentationCore, PresentationFramework, WindowsBase
$global:Playing=0
$global:Muted=0
$global:Repeating=0
$global:ShuffleOn=0
$global:tracking=0
$global:icurrent=-1
$global:AnimationThread=0
$global:flyoutPressed=0
$global:VolMax=0
$global:CounterB=0
function Update-Gui(){
	$window.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background,[action]{})
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
	$global:AnimationInterval=0
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
				$mediaPlayer.Play()
				$window.TaskbarItemInfo.Description='Playing...'
				$global:Playing=1
				$StatusInfo1.Text="Now Playing"
				$StatusInfo2.Text=$StatusInfo1.Text
				$StatusInfo3.Text=$StatusInfo1.Text
				$StatusInfo4.Text=$StatusInfo1.Text
				$StatusInfo5.Text=$StatusInfo1.Text
				$PlayPath.Visibility = "Hidden"
				$PausePath.Visibility = "Visible"
			}
			1{
				$mediaPlayer.Pause()
				$window.TaskbarItemInfo.Description='Paused...'
				$global:Playing=0
				$StatusInfo1.Text="Paused"
				$StatusInfo2.Text=$StatusInfo1.Text
				$StatusInfo3.Text=$StatusInfo1.Text
				$StatusInfo4.Text=$StatusInfo1.Text
				$StatusInfo5.Text=$StatusInfo1.Text
				$PlayPath.Visibility = "Visible"
				$PausePath.Visibility = "Hidden"
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
		Start-Sleep -milliseconds 10
	}
}
function PlayTrack(){
	$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
	$FullName="$file"
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
[xml]$playerCode='
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="PowerPlayer" Height="300" Width="500" WindowStyle="None" AllowsTransparency="True" Background="Transparent" WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize">
	<Window.Resources>
		<ControlTemplate x:Key="NoMouseOverButtonTemplate" TargetType="Button">
			<Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
				<ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
			</Border>
			<ControlTemplate.Triggers>
				<Trigger Property="IsEnabled" Value="False">
					<Setter Property="Background" Value="{x:Static SystemColors.ControlLightBrush}"/>
					<Setter Property="Foreground" Value="{x:Static SystemColors.ControlTextBrush}"/>
				</Trigger>
			</ControlTemplate.Triggers>
		</ControlTemplate>
		<Style x:Key="ScrollBarLineButtonStyle" TargetType="{x:Type RepeatButton}">
			<Setter Property="Focusable" Value="False"/>
			<Setter Property="BorderThickness" Value="1"/>
			<Setter Property="Background" Value="#111111"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type RepeatButton}">
						<Grid x:Name="grid" Background="{TemplateBinding Background}" >
							<Path x:Name="Arrow" HorizontalAlignment="Center" VerticalAlignment="Center" Data="{Binding Content, RelativeSource={RelativeSource TemplatedParent}}" Stretch="Uniform" Fill="#EEEEEE" Width="8" Height="8" />
						</Grid>
						<ControlTemplate.Triggers>
							<Trigger Property="IsEnabled" Value="False">
								<Setter TargetName="Arrow" Property="Fill" Value="#111111"/>
							</Trigger>
						</ControlTemplate.Triggers>
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollBarLineButtonArrowlessStyle" TargetType="{x:Type RepeatButton}">
			<Setter Property="Focusable" Value="False"/>
			<Setter Property="BorderThickness" Value="1"/>
			<Setter Property="Background" Value="#111111"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type RepeatButton}">
						<Grid x:Name="grid" Background="{TemplateBinding Background}" />
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollBarPageButtonStyle" TargetType="{x:Type RepeatButton}">
			<Setter Property="IsTabStop" Value="False"/>
			<Setter Property="Focusable" Value="False"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type RepeatButton}">
						<Border Background="Transparent" />
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollBarThumbStyle" TargetType="{x:Type Thumb}">
			<Setter Property="IsTabStop" Value="False"/>
			<Setter Property="Focusable" Value="False"/>
			<Setter Property="Margin" Value="1,0,1,0" />
			<Setter Property="Width" Value="8" />
			<Setter Property="Background" Value="#111111"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type Thumb}">
						<Rectangle Fill="#6495ED" RadiusX="4" RadiusY="4" />
					</ControlTemplate>
				</Setter.Value>
			</Setter>
		</Style>
		<Style x:Key="ScrollBarStyle" TargetType="{x:Type ScrollBar}">
			<Setter Property="MinWidth" Value="16"/>
			<Setter Property="MinHeight" Value="16"/>
			<Setter Property="Background" Value="#111111"/>
			<Setter Property="Template">
				<Setter.Value>
					<ControlTemplate TargetType="{x:Type ScrollBar}">
						<Grid x:Name="Root" Background="{TemplateBinding Background}">
							<Grid.RowDefinitions>
								<RowDefinition Height="Auto"/>
								<RowDefinition Height="*"/>
								<RowDefinition Height="Auto"/>
							</Grid.RowDefinitions>
							<RepeatButton Grid.Row="0" Style="{StaticResource ScrollBarLineButtonStyle}" Height="16" Command="ScrollBar.LineUpCommand" Content="M 0 4 L 8 4 L 4 0 Z" />
							<Track Name="PART_Track" Grid.Row="1" IsDirectionReversed="True">
								<Track.DecreaseRepeatButton>
									<RepeatButton Command="ScrollBar.PageUpCommand" Style="{StaticResource ScrollBarPageButtonStyle}"/>
								</Track.DecreaseRepeatButton>
								<Track.Thumb>
									<Thumb Style="{StaticResource ScrollBarThumbStyle}" />
								</Track.Thumb>
								<Track.IncreaseRepeatButton>
									<RepeatButton Command="ScrollBar.PageDownCommand" Style="{StaticResource ScrollBarPageButtonStyle}"/>
								</Track.IncreaseRepeatButton>
							</Track>
							<RepeatButton Grid.Row="2" Style="{StaticResource ScrollBarLineButtonStyle}" Height="16" Command="ScrollBar.LineDownCommand" Content="M 0 0 L 4 4 L 8 0 Z"/>
						</Grid>
						<ControlTemplate.Triggers>
							<Trigger Property="Orientation" Value="Horizontal">
								<Setter TargetName="Root" Property="LayoutTransform">
									<Setter.Value>
										<RotateTransform Angle="-90"/>
									</Setter.Value>
								</Setter>
								<Setter TargetName="PART_Track" Property="LayoutTransform">
									<Setter.Value>
										<RotateTransform Angle="-90"/>
									</Setter.Value>
								</Setter>
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
			<Canvas>
				<TextBlock Visibility="Hidden" Name="ButtonData"/>
				<TextBlock Name="Status5" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="Status4" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="Status3" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="Status2" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="Status1" Canvas.Left="90" Canvas.Top="74" FontSize="14" FontFamily="Calibri" FontWeight="Light" Foreground="LightGray"/>
				<TextBlock Name="CurrentTrack5" Canvas.Top="128" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="Purple" Margin="-1,-1"/>
				<TextBlock Name="CurrentTrack4" Canvas.Top="128" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="MediumPurple" Margin="-1,1"/>
				<TextBlock Name="CurrentTrack3" Canvas.Top="128" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="RoyalBlue" Margin="1,-1"/>
				<TextBlock Name="CurrentTrack2" Canvas.Top="128" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="LightBlue" Margin="1,1"/>
				<TextBlock Name="CurrentTrack1" Canvas.Top="128" FontSize="19" FontFamily="Calibri" Text="No Media Loaded" TextAlignment="Center" Width="490" Foreground="LightGray"/>
				<Button Name="Menu" Canvas.Left="0" Canvas.Top="0" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#EEEEEE" Background="#111111" Height="18" Width="70" Template="{StaticResource NoMouseOverButtonTemplate}">Menu</Button>
				<Button Name="MenuPlaylist1" Canvas.Left="70" Canvas.Top="0" Visibility="Hidden" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#DDDDDD" Background="#111111" Height="18" Width="25" Template="{StaticResource NoMouseOverButtonTemplate}">Playlist
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
				<Button Name="MenuPlaylist2" Canvas.Left="207" Canvas.Top="0" Visibility="Hidden" FontSize="12" FontFamily="Calibri" FontWeight="Light" BorderBrush="#111111" Foreground="#DDDDDD" Background="#111111" Height="18" Width="25" Template="{StaticResource NoMouseOverButtonTemplate}">>>
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
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path x:Name="MutedPath" Fill="#111111" Margin="0.5" Data="M12,4L9.91,6.09L12,8.18M4.27,3L3,4.27L7.73,9H3V15H7L12,20V13.27L16.25,17.53C15.58,18.04 14.83,18.46 14,18.7V20.77C15.38,20.45 16.63,19.82 17.68,18.96L19.73,21L21,19.73L12,10.73M19,12C19,12.94 18.8,13.82 18.46,14.64L19.97,16.15C20.62,14.91 21,13.5 21,12C21,7.72 18,4.14 14,3.23V5.29C16.89,6.15 19,8.83 19,12M16.5,12C16.5,10.23 15.5,8.71 14,7.97V10.18L16.45,12.63C16.5,12.43 16.5,12.21 16.5,12Z" Stretch="Uniform" Visibility="Hidden"/>
							<Path x:Name="UnMutedPath" Fill="#111111" Margin="0.5" Data="M14,3.23V5.29C16.89,6.15 19,8.83 19,12C19,15.17 16.89,17.84 14,18.7V20.77C18,19.86 21,16.28 21,12C21,7.72 18,4.14 14,3.23M16.5,12C16.5,10.23 15.5,8.71 14,7.97V16C15.5,15.29 16.5,13.76 16.5,12M3,9V15H7L12,20V4L7,9H3Z" Stretch="Uniform" Visibility="Visible"/>
							<Border BorderThickness="0" CornerRadius="0" Margin="0">
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
						</Grid>
					</Border>
				</Button>
				<Button Name="Shuffle" Canvas.Left="80" Canvas.Top="220" BorderThickness="2" BorderBrush="#6495ED" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
					<Button.Resources>
						<Style TargetType="Border">
							<Setter Property="CornerRadius" Value="3"/>
						</Style>
					</Button.Resources>
					<Border CornerRadius="5" Height="15" Width="20">
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path Fill="#111111" Data="M17,3L22.25,7.5L17,12L22.25,16.5L17,21V18H14.26L11.44,15.18L13.56,13.06L15.5,15H17V12L17,9H15.5L6.5,18H2V15H5.26L14.26,6H17V3M2,6H6.5L9.32,8.82L7.2,10.94L5.26,9H2V6Z" Stretch="Uniform"/>
							<Border BorderThickness="0" CornerRadius="0" Margin="0">
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
						</Grid>
					</Border>
				</Button>
				<Button Name="Prev" Canvas.Left="122" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
					<Button.Resources>
						<Style TargetType="Border">
							<Setter Property="CornerRadius" Value="5"/>
						</Style>
					</Button.Resources>
					<Border CornerRadius="5" Height="27" Width="55">
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path Fill="#111111" Margin="2" Data="M6,18V6H8V18H6M9.5,12L18,6V18L9.5,12Z" Stretch="Uniform"/>
							<Border BorderThickness="0" CornerRadius="0" Margin="0">
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
						</Grid>
					</Border>
				</Button>
				<Button Name="Play" Canvas.Left="211" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
					<Button.Resources>
						<Style TargetType="Border">
							<Setter Property="CornerRadius" Value="5"/>
						</Style>
					</Button.Resources>
					<Border CornerRadius="5" Height="27" Width="65">
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path x:Name="PlayPath" Margin="2" Fill="#111111" Data="M8,5.14V19.14L19,12.14L8,5.14Z" Stretch="Uniform" Visibility="Visible"/>
							<Path x:Name="PausePath" Margin="2" Fill="#111111" Data="M14,19H18V5H14M6,19H10V5H6V19Z" Stretch="Uniform" Visibility="Hidden"/>
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
						</Grid>
					</Border>
				</Button>
				<Button Name="Next" Canvas.Left="312" Canvas.Top="215" BorderBrush="#2F539B" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
					<Button.Resources>
						<Style TargetType="Border">
							<Setter Property="CornerRadius" Value="5"/>
						</Style>
					</Button.Resources>
					<Border CornerRadius="5" Height="27" Width="55">
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path Fill="#111111" Margin="2" Data="M16,18H18V6H16M6,18L14.5,12L6,6V18Z" Stretch="Uniform"/>
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
						</Grid>
					</Border>
				</Button>
				<Button Name="Repeat" Canvas.Left="386" Canvas.Top="220" BorderThickness="2" BorderBrush="#6495ED" Background="#6495ED" Opacity="0.85" Template="{StaticResource NoMouseOverButtonTemplate}">
					<Button.Resources>
						<Style TargetType="Border">
							<Setter Property="CornerRadius" Value="3"/>
						</Style>
					</Button.Resources>
					<Border CornerRadius="5" Height="15" Width="20">
						<Border.Effect>
							<DropShadowEffect Color="#800080" BlurRadius="8" ShadowDepth="0" Direction="0"/>
						</Border.Effect>
						<Border.BorderBrush>
							<LinearGradientBrush EndPoint="0.811,0.2" StartPoint="0.246,1.023">
								<GradientStop Color="#FF7C9FC8" Offset="0"/>
								<GradientStop Color="#FF7C9FC8" Offset="1"/>
								<GradientStop Color="#FF353535" Offset="0.491"/>
							</LinearGradientBrush>
						</Border.BorderBrush>
						<Grid>
							<Path x:Name="RepeatAllPath" Fill="#111111" Data="M17,17H7V14L3,18L7,22V19H19V13H17M7,7H17V10L21,6L17,2V5H5V11H7V7Z" Stretch="Uniform" Visibility="Visible"/>
							<Path x:Name="RepeatOnePath" Fill="#111111" Data="M13,15V9H12L10,10V11H11.5V15M17,17H7V14L3,18L7,22V19H19V13H17M7,7H17V10L21,6L17,2V5H5V11H7V7Z" Stretch="Uniform" Visibility="Hidden"/>
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
						</Grid>
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
				<ListBox Canvas.Left="85" Canvas.Top="18" Name="Playlist" Visibility="Hidden" Width="320" Height="245" Opacity="0.95" Style="{DynamicResource lbStyle}" AlternationCount="2" ItemContainerStyle="{StaticResource AlternatingRowStyle}"/>
			</Canvas>
		</Grid>
	</Border>
	<Window.TaskbarItemInfo>
		<TaskbarItemInfo/>
	</Window.TaskbarItemInfo>
</Window>'
[xml]$notifyCode='
<Window	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	x:Name="Window" WindowStyle="None"
	Width= "350" Height="110"
	Background="#333333"
	Opacity="0.8"
	AllowsTransparency="True">
	<Window.Clip>
		<RectangleGeometry Rect="0,0,350,110" RadiusX="20" RadiusY="20"/>
	</Window.Clip>
	<Canvas>
		<TextBlock Name="Notifier1" Canvas.Top="45" Canvas.Left="35" FontSize="14" FontWeight="Bold" FontFamily="Calibri" Text="PowerPlayer has been" Foreground="#EEEEEE"/>
		<TextBlock Name="Notifier2" Canvas.Top="62" Canvas.Left="35" FontSize="14" FontFamily="Calibri" Text="minimized to the SysTray" Foreground="#EEEEEE"/>
	</Canvas>
	<Window.TaskbarItemInfo>
		<TaskbarItemInfo/>
	</Window.TaskbarItemInfo>
</Window>
'
$playerCore=(New-Object System.Xml.XmlNodeReader $playerCode)
$notifyCore=(New-Object System.Xml.XmlNodeReader $notifyCode)
$window=[Windows.Markup.XamlReader]::Load($playerCore)
$Notify=[Windows.Markup.XamlReader]::Load($notifyCore)
$MainGrid = $window.FindName("MainWindow")
$particlefield = New-Object UnifiedVisualizer
$particlefield.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
$particlefield.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch
$MainGrid.Children.Insert(0, $particlefield)
$calculator = New-Object AudioLevelCalculator
$calculator.StartCapture()
$particlefield.AudioCalculator = $calculator
$window.Title='PowerPlayer'
$monitor=[System.Windows.Forms.Screen]::PrimaryScreen
[void]::$monitor.WorkingArea.Width
[void]::$monitor.WorkingArea.Height
$Notify.Left=$monitor.WorkingArea.Width - $Notify.Width - 10
$Notify.Top=$monitor.WorkingArea.Height - $Notify.Height - 10
$Notify.TopMost=$true
$NotifyAudio=New-Object System.Media.SoundPlayer
$NotifyAudio.SoundLocation=$env:WinDir + '\Media\Windows Notify System Generic.wav'
$extractedIcon = [System.IconExtractor]::Extract('C:\Windows\System32\wmploc.dll', 19, $true)
$bitmapSource = [System.IconExtractor]::IconToBitmapSource($extractedIcon)
$window.Icon = $bitmapSource
$window.TaskbarItemInfo.Overlay = $bitmapSource
$Notify.Icon = $bitmapSource
$Notify.TaskbarItemInfo.Overlay = $bitmapSource
$IconImage = [Drawing.Icon]::FromHandle($extractedIcon.Handle).ToBitmap()
$intPtr = New-Object IntPtr
$IconThumbnail = $IconImage.GetThumbnailImage(64, 64, $null, $intPtr)
$IconBitmap = New-Object Drawing.Bitmap $IconThumbnail
$IconBitmap.SetResolution(64, 64)
$TrayIcon = [System.Drawing.Icon]::FromHandle($IconBitmap.GetHicon())
$SysTrayIcon=New-Object System.Windows.Forms.NotifyIcon
$SysTrayIcon.Text="PowerPlayer"
$SysTrayIcon.Icon = $TrayIcon
$SysTrayIcon.Add_Click({
	$SysTrayIcon.Visible=$false
	$Window.Show()
	$Window.Activate() | Out-Null
})
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
		$window.TaskbarItemInfo.Overlay=$ShowIcon
		$window.TaskbarItemInfo.Description=$window.Title
		$MenuPlaylist1.Visibility="Hidden"
		$MenuPlaylist2.Visibility="Hidden"
		$Playlist.Visibility="Hidden"
		$TimeLeft.Visibility="Hidden"
		$global:icurrent=-1
		$mediaPlayer.Position=New-Object System.TimeSpan(0, 0, 0, 0, 0)
		$mediaPlayer.Stop()
		$PositionSlider.Value=([TimeSpan]::Parse($mediaPlayer.Position)).TotalSeconds
		$PlayPath.Visibility = "Visible"
		$PausePath.Visibility = "Hidden"
		$CurrentTrack1.Text='No Media Loaded'
		$CurrentTrack2.Text=$CurrentTrack1.Text
		$CurrentTrack3.Text=$CurrentTrack1.Text
		$CurrentTrack4.Text=$CurrentTrack1.Text
		$CurrentTrack5.Text=$CurrentTrack1.Text
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
		$window.Icon=$ShowIcon
	}
})
$window.Add_Closing({
	$calculator.StopCapture()
	$particlefield.timer.Stop()
	Stop-Process $pid
})
$MutedPath = $window.FindName("MutedPath")
$UnMutedPath = $window.FindName("UnMutedPath")
$PlayPath = $window.FindName("PlayPath")
$PausePath = $window.FindName("PausePath")
$RepeatAllPath = $window.FindName("RepeatAllPath")
$RepeatOnePath = $window.FindName("RepeatOnePath")
$MutedPath.Visibility = "Hidden"
$UnMutedPath.Visibility = "Visible"
$PlayPath.Visibility = "Visible"
$PausePath.Visibility = "Hidden"
$RepeatAllPath.Visibility = "Visible"
$RepeatOnePath.Visibility = "Hidden"
$Mute=$Window.FindName("Mute")
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
			$MutedPath.Visibility = "Visible"
			$UnMutedPath.Visibility = "Hidden"
		}
		1{
			if($UnMutedVolume -eq $null){
				$global:UnMutedVolume=0.5
			}
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
			$MutedPath.Visibility = "Hidden"
			$UnMutedPath.Visibility = "Visible"
		}
	}
})
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
		$MutedPath.Visibility = "Hidden"
		$UnMutedPath.Visibility = "Visible"
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
					$MutedPath.Visibility = "Hidden"
					$UnMutedPath.Visibility = "Visible"
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
	closeMenus
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
$Window.Add_ContentRendered({
	$ButtonData.Text='1'
	Start-Sleep -Milliseconds 50
	$ButtonData.Text='0'
})
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
		$path=Split-Path $file -Parent
		$path=$path+'\'
		$files=$null
		$files=@()
		$files+=$file
		if($Playing -eq 0){
			TogglePlayButton
		}
		$Playlist.ItemsSource=$files -ireplace "^.+[\\]",'' -ireplace ".mp3$",''
		if($files -ne ""){
			if($MenuPlaylist1.Visibility -ne "Visible"){
				$MenuPlaylist2.Visibility="Visible"
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
	$AssemblyFullName='System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
	$Assembly=[System.Reflection.Assembly]::Load($AssemblyFullName)
	$OpenFileDialog=[System.Windows.Forms.OpenFileDialog]::new()
	$OpenFileDialog.AddExtension=$false
	$OpenFileDialog.CheckFileExists=$false
	$OpenFileDialog.DereferenceLinks=$true
	$OpenFileDialog.Filter="Folders|`n"
	$OpenFileDialog.Multiselect=$false
	$OpenFileDialog.Title="Select a Folder"
	$OpenFileDialog.InitialDirectory="$env:UserProfile\Music"
	$OpenFileDialogType=$OpenFileDialog.GetType()
	$FileDialogInterfaceType=$Assembly.GetType('System.Windows.Forms.FileDialogNative+IFileDialog')
	$IFileDialog=$OpenFileDialogType.GetMethod('CreateVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null)
	$OpenFileDialogType.GetMethod('OnBeforeVistaDialog',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$IFileDialog)
	[uint32]$PickFoldersOption=$Assembly.GetType('System.Windows.Forms.FileDialogNative+FOS').GetField('FOS_PICKFOLDERS').GetValue($null)
	$FolderOptions=$OpenFileDialogType.GetMethod('get_Options',@('NonPublic','Public','Static','Instance')).Invoke($OpenFileDialog,$null) -bor $PickFoldersOption
	$FileDialogInterfaceType.GetMethod('SetOptions',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$FolderOptions)
	$VistaDialogEvent=[System.Activator]::CreateInstance($AssemblyFullName,'System.Windows.Forms.FileDialog+VistaDialogEvents',$false,0,$null,$OpenFileDialog,$null,$null).Unwrap()
	[uint32]$AdviceCookie=0
	$AdvisoryParameters=@($VistaDialogEvent,$AdviceCookie)
	$AdviseResult=$FileDialogInterfaceType.GetMethod('Advise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdvisoryParameters)
	$AdviceCookie=$AdvisoryParameters[1]
	$Result=$FileDialogInterfaceType.GetMethod('Show',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,[System.IntPtr]::Zero)
	$FileDialogInterfaceType.GetMethod('Unadvise',@('NonPublic','Public','Static','Instance')).Invoke($IFileDialog,$AdviceCookie)
	if($OpenFileDialog.FileName -ne ""){
		$global:singlefilemode=0
		$path=$OpenFileDialog.FileName+'\'
		$files=$null
		$files=@()
		Get-ChildItem -Path $path -Filter *.mp3 -Depth 5 -File -Name| ForEach-Object {
			$files+=$path + $_
		}
		if($ShuffleOn -eq 1){
			$filesShuffled=$files | Sort-Object {Get-Random}
			$Playlist.ItemsSource=$filesShuffled -ireplace "^.+[\\]",'' -ireplace ".mp3$",''
		} else {
			$Playlist.ItemsSource=$files -ireplace "^.+[\\]",'' -ireplace ".mp3$",''
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
			if($MenuPlaylist1.Visibility -ne "Visible"){
				$MenuPlaylist2.Visibility="Visible"
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
	$Notify.Close()
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
	$SysTrayIcon.Visible=$true
	if($TrayChecked -ne 1){
		$AllTrayIcons=Get-ChildItem 'HKCU:\Control Panel\NotifyIconSettings'
		$TrayIcons=$AllTrayIcons -ireplace 'HKEY_CURRENT_USER','HKCU:'
		$TrayIcons | Foreach {
			$Items = Get-ItemProperty "$_"
			$global:NotifyRegKey=$_
			if(![bool]((Get-ItemProperty -Path $NotifyRegKey).IgnoreIfPresent)){
				$Items.psobject.Properties | where name -notlike ps* | Foreach {
					if($_.Value -like "*powershell.exe"){
						if((Get-ItemProperty -Path $NotifyRegKey -Name IsPromoted).IsPromoted -ne 1){
							New-ItemProperty -Path $NotifyRegKey -Name IsPromoted -Value 1 -PropertyType DWORD -Force | Out-Null
							New-ItemProperty -Path $NotifyRegKey -Name IgnoreIfPresent -Value 1 -PropertyType DWORD -Force | Out-Null
						}
					}
				}
			}
		}
		$global:TrayChecked=1
	}
	$Window.Hide()
	$Notify.Show()
	if($notified -ne 1){
		$NotifyAudio.playsync()
		$global:notified=1
	}
	$delay=40
	while($delay -ge -1){
		Start-Sleep -Milliseconds 50
		Update-Gui
		$delay-=1
	}
	$Notify.Hide()
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
	$Notify.Close()
	Exit
})
$Shuffle=$Window.FindName("Shuffle")
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
			$Playlist.ItemsSource=$filesShuffled -ireplace "^.+[\\]",'' -ireplace ".mp3$",''
		}
		1{
			$Shuffle.BorderBrush='#728FCE'
			$global:ShuffleOn=0
			$Playlist.ItemsSource=$files -ireplace "^.+[\\]",'' -ireplace ".mp3$",''
		}
	}
})
$Prev=$Window.FindName("Prev")
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
			$RepeatAllPath.Visibility = "Hidden"
			$RepeatOnePath.Visibility = "Visible"
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=1
		}
		1{
			$RepeatAllPath.Visibility = "Visible"
			$RepeatOnePath.Visibility = "Hidden"
			$Repeat.BorderBrush='#5D3FD3'
			$global:Repeating=2
		}
		2{
			$RepeatAllPath.Visibility = "Visible"
			$RepeatOnePath.Visibility = "Hidden"
			$Repeat.BorderBrush='#6495ED'
			$global:Repeating=0
		}
	}
})
$app = New-Object System.Windows.Application
[void]$app.Run($window)