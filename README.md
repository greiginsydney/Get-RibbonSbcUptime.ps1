# Get-RibbonSbcUptime.ps1
Query your Ribbon SBC to see how long it's been running.

**This version is v1.0 - 16th November 2019.**

Get-RibbonSbcUptime.ps1 invokes a REST login to your Sonus/Ribbon SBC 1k/2k/SWe-Lite and reports how long it's been running: the CpuUptime.

It outputs either a timespan object to the pipeline, or a literal string in the same format the SBC displays on its System / Overview tab.

<p><img id="225550" src="https://user-images.githubusercontent.com/11004787/79118705-ef9e7e80-7dd1-11ea-84fd-469d8e6932be.png" alt="" width="789" height="294" /></p>

### Usage

The minimum parameters are the SBC FQDN, the REST login name and REST password. An optional parameter is "-AsTimeString".

```powershell
PS C:\>.\Get-RibbonSbcUptime.ps1 -SbcFQDN 10.10.16.82 -RestLogin REST -RestPassword MyRe$tPwD -AsTimeString
```

If you fail to provide any of the required parameters, the script will prompt you for them.

The default output is a timespan object:

```powershell
Days              : 2
Hours             : 20
Minutes           : 3
Seconds           : 10
Milliseconds      : 0
Ticks             : 2449900000000
TotalDays         : 2.83553240740741
TotalHours        : 68.0527777777778
TotalMinutes      : 4083.16666666667
TotalSeconds      : 244990
TotalMilliseconds : 244990000
```

If you add the "-AsTimeString" switch the script will output a literal version of the uptime, in the same format as the SBC shows on its System/Overview tab:
```powershell
3 days, 20 hrs, 4 mins, 48 secs
```
### Automation
If you're automating this script, you can capture its output into a variable to review in subsequent handling. If you ARE doing this, make sure you add the "-SkipUpdateCheck" switch, otherwise an update to the script will derail  the automation:

<pre>PS C:\> $SbcUptime = (.\Get-RibbonSbcUptime.ps1 -SbcFQDN 10.10.16.82 -RestLogin REST -RestPassword P@ssw0rd1 -Verbose <strong>-SkipUpdateCheck</strong></pre>

### Known Issue
SBC firmware versions prior to v8.0.3 have a known bug: the CpuUptime reports zero. This is not a problem with the script. If the script reports zero but system/Overview reports an expected value, you'll need to update the SBC's  firmware.

### Revision History
1.0 - 16th November 2019.
- This is the initial release.

<br>

\- G.

<br>

This script was originally published at [https://greiginsydney.com/get-ribbonsbcuptime-ps1/](https://greiginsydney.com/get-ribbonsbcuptime-ps1/).
