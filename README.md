# Get-RibbonSbcUptime.ps1
Query your Ribbon SBC to see how long it's been running.

<p>&nbsp;</p>
<p><strong><span style="font-size: small; color: #ff0000;">This version is v1.0 - 16th November 2019.</span></strong></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><span style="font-size: small;">Get-RibbonSbcUptime.ps1 invokes a REST login to your Sonus/Ribbon SBC 1k/2k/SWe-Lite and reports how long it's been running: the CpuUptime.</span></p>
<p><span style="font-size: small;">&nbsp;</span><br /> <span style="font-size: small;">It outputs either a timespan object to the pipeline, or a literal string in the same format the SBC displays on its System / Overview tab.</span></p>
<p>&nbsp;</p>
<p><img id="225550" src="/site/view/file/225550/1/Get-RibbonSbcUptime-Example.png" alt="" width="789" height="294" /></p>
<p>&nbsp;</p>
<h3><span style="font-size: small;">Usage</span></h3>
<p><span style="font-size: small;">The minimum parameters are the SBC FQDN, the REST login name and REST password. An optional parameter is "-AsTimeString".</span></p>
<p>&nbsp;</p>
<pre><span style="font-size: small;">PS C:\&gt;.\Get-RibbonSbcUptime.ps1 -SbcFQDN 10.10.16.82 -RestLogin REST -RestPassword MyRe$tPwD -AsTimeString</span></pre>
<p><span style="font-size: x-small;"><br /> </span></p>
<p><span style="font-size: small;">If you fail to provide any of the required parameters, the script will prompt you for them.</span></p>
<p><span style="font-size: small;">The default output is a timespan object:</span></p>
<pre><span style="font-size: small;">Days              : 2
Hours             : 20
Minutes           : 3
Seconds           : 10
Milliseconds      : 0
Ticks             : 2449900000000
TotalDays         : 2.83553240740741
TotalHours        : 68.0527777777778
TotalMinutes      : 4083.16666666667
TotalSeconds      : 244990
TotalMilliseconds : 244990000</span></pre>
<p><span style="font-size: x-small;"><br /> </span></p>
<p><span style="font-size: small;">If you add the "-AsTimeString" switch the script will output a literal version of the uptime, in the same format as the SBC shows on its System/Overview tab:</span></p>
<pre><span style="font-size: small;">3 days, 20 hrs, 4 mins, 48 secs</span></pre>
<h3>Automation</h3>
<p><span style="font-size: small;">If you're automating this script, you can capture its output into a variable to review in subsequent handling. If you ARE doing this, make sure you add the "-SkipUpdateCheck" switch, otherwise an update to the script will derail  the automation:</span></p>
<pre><span style="font-size: small;">PS C:\&gt; $SbcUptime = (.\Get-RibbonSbcUptime.ps1 -SbcFQDN 10.10.16.82 -RestLogin REST -RestPassword P@ssw0rd1 -Verbose <span style="background-color: #ffff99;">-SkipUpdateCheck</span>)</span></pre>
<h3>Known Issue</h3>
<p><span style="font-size: small;">SBC firmware versions prior to v8.0.3 have a known bug: the CpuUptime reports zero. This is not a problem with the script. If the script reports zero but system/Overview reports an expected value, you'll need to update the SBC's  firmware.</span></p>
<h3>Revision History</h3>
<p><span style="font-size: small;">1.0 - 16th November 2019.</span></p>
<ul>
<li><span style="font-size: small;">This is the initial release.</span> </li>
</ul>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p><span style="font-size: small;">- G.</span></p>
