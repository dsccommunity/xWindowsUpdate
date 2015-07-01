# This will configure Automatic Updates on the localhost per the properties
# 	WUServer is the URL to your server
#	UseWUServer = 1 => Use the one defined.   0 => Use Microsoft's Windows Update Servers
# 	NoAutoUpdate = 1 => Disables Automatic Updates, NoAutoUpdate = 0 enables Automatic Updates
# 	AUOptions:    2 => notify before download, 3 => auto download and user notified of installation, 4 => auto download and installed per schedule
# 	ScheduledInstallDay = 0 => Daily, 1 => Sunday, etc, 7 => Saturday
# 	ScheduledInstallTime = 0 => midnight, 1 => 1am, etc. 
# 	DetectionFrequency is the number of hours between checks
# 	DetectionFrequencyEnabled = 0 => Not Enabled, 1 => Enabled
configuration ConfigureAutoUpdates
{
	Import-DSCResource -ModuleName xWindowsUpdates

	Node localhost
	{
		AutoUpdates WSUS
		{
			WUServer=	'https://<Your_WSUS_Server_Here>:<Port>'
			UseWUServer= '1'
			NoAutoUpdate=	'0'
			AUOptions= '4'
			ScheduledInstallDay= '0'
			ScheduledInstallTime= '0'
			DetectionFrequency = '1'
			DetectionFrequencyEnabled='1'
		}
	}
}
ConfigureAutoUpdates
Start-DscConfiguration -path ConfigureAutoUpdates -wait -verbose -force

