#######################################################################################################################
###                                                                                                                 ###
###  	Script by Terry Munro -                                                                                     ###
###     Technical Blog -               http://365admin.com.au                                                       ###
###     Webpage -                      https://www.linkedin.com/in/terry-munro/                                     ###
###     TechNet Gallery Scripts -      http://tinyurl.com/TerryMunroTechNet                                         ###
###     Version -                      Version 1.1                                                                  ###
###     Version History                Version 1.0 - 03/12/2017                                                     ###
###                                    Version 1.1 - 25/03/2018                                                     ###
###                                                                                                                 ###
###     Change Log                     Version 1.1 - Added PowerShell variable - to prevent truncation of results   ###
###                                                                                                                 ###
###     Support                        http://www.365admin.com.au/2017/12/how-to-create-basic-document-of.html      ###
###                                                                                                                 ###
###     Download Link                  https://gallery.technet.microsoft.com/Exchange-Online-Configurati-5c6019b5   ###
###                                                                                                                 ###
#######################################################################################################################

##############################################################################################################################
###                                                                                                                        ###
###  	Script Notes                                                                                                       ###
###     Script has been created to document the current Exchange Online environment                                        ###
###     Script has been tested on Exchange Online                                                                          ###
###                                                                                                                        ###
###     Update the variable - $logpath - to set the location you want the reports to be generated                          ###
###                                                                                                                        ###
##############################################################################################################################

### Update the log path variable below before running the script ####

$logpath = "c:\reports"


### Do not change the variable below as it is needed to prevent truncation of data in the output

$FormatEnumerationLimit=-1


Get-AcceptedDomain | Select Name,DomainName,DomainType,Default | Out-File "$logpath\AcceptedDomain-EXOnline.txt" -NoClobber -Append

Get-InboundConnector | Select Name,Enabled,ProtocolLoggingLevel,FQDN,MaxMessageSize,Bindings,RemoteIPRanges,AuthMechanism,PermissionGroups | Out-File "$logpath\InboundConnector-EXOnline.txt" -NoClobber -Append

Get-OutboundConnector | Select Name,Enabled,ProtocolLoggingLevel,SmartHostsString,FQDN,MaxMessageSize,AddressSpaces,SourceTransportServers | Out-File "$logpath\OutboundConnectors-EXOnline.txt" -NoClobber -Append

Get-TransportRule | Select Name,Priority,Description,Comments,State | Out-File "$logpath\TransportRules-EXOnline.txt" -NoClobber -Append

Get-OwaMailboxPolicy | Select Name,ActiveSyncIntegrationEnabled,AllAddressListsEnabled,CalendarEnabled,ContactsEnabled,JournalEnabled,JunkEmailEnabled,RemindersAndNotificationsEnabled,NotesEnabled,PremiumClientEnabled,SearchFoldersEnabled,SignaturesEnabled,SpellCheckerEnabled,TasksEnabled,ThemeSelectionEnabled,UMIntegrationEnabled,ChangePasswordEnabled,RulesEnabled,PublicFoldersEnabled,SMimeEnabled,RecoverDeletedItemsEnabled,InstantMessagingEnabled,TextMessagingEnabled,DirectFileAccessOnPublicComputersEnabled,WebReadyDocumentViewingOnPublicComputersEnabled,DirectFileAccessOnPrivateComputersEnabled,WebReadyDocumentViewingOnPrivateComputersEnabled | Out-File "$logpath\OwaMailboxPolicies-EXOnline.txt" -NoClobber -Append

Get-MobileDeviceMailboxPolicy | Select Name,AllowNonProvisionableDevices,DevicePolicyRefreshInterval,PasswordEnabled,MaxCalendarAgeFilter,MaxEmailAgeFilter,MaxAttachmentSize,RequireManualSyncWhenRoaming,AllowHTMLEmail,AttachmentsEnabled,AllowStorageCard,AllowCameraTrue,AllowWiFi,AllowIrDA,AllowInternetSharing,AllowRemoteDesktop,AllowDesktopSync,AllowBluetooth,AllowBrowser,AllowConsumerEmail,AllowUnsignedApplications,AllowUnsignedInstallationPackages | Out-File "$logpath\MobileDevicePolices-EXOnline.txt" -NoClobber -Append

Get-MSOLCompanyInformation | Select DirectorySynchronizationEnabled,LastDirSyncTime,LastPasswordSyncTime,PasswordSynchronizationEnabled | Out-File "$logpath\DirectorySyncStatus.txt" -NoClobber -Append

Get-OrganizationRelationship | Select Name,DomainNames,FreeBusyEnabled,FreeBusyAccessLevel,FreeBusyAccessScope | export-csv -NoTypeInformation "$logpath\Free-Busy-EXOnline.csv"



# Tenant Administrators
$role = Get-MsolRole -RoleName "Company Administrator"
Get-MsolRoleMember -RoleObjectId $role.ObjectId | Out-File "$logpath\TenantAdministrators.txt" -NoClobber -Append


### The following scripts output mailbox permissions ###

Get-RecipientPermission | Where {($_.Trustee -ne 'nt authority\self') } | select Identity, Trustee, AccessRights | Export-Csv -NoTypeInformation "$logpath\MailboxSendAsAccess-EXOnline.csv"

Get-Mailbox -ResultSize Unlimited |  ? {$_.GrantSendOnBehalfTo -ne $null} | select Name,Alias,UserPrincipalName,PrimarySmtpAddress,GrantSendOnBehalfTo | export-csv -NoTypeInformation "$logpath\MailboxSendOnBehalfAccess-EXOnline.csv"

$a = Get-Mailbox $a |Get-MailboxPermission | Where { ($_.IsInherited -eq $False) -and -not ($_.User -like “NT AUTHORITY\SELF”) -and -not ($_.User -like '*Discovery Management*') } | Select Identity, user | Export-Csv -NoTypeInformation "$logpath\MailboxFullAccess-EXOnline.csv"



### The following scripts output mailbox statistics ###

$MailboxStats = get-mailbox -ResultSize Unlimited | group-object recipienttypedetails | select count, name
$MailboxStats | Out-File "$logpath\MailboxCount-EXOnline.txt" -NoClobber -Append


### The following scripts output mailbox details including database ###
Get-Mailbox -ResultSize Unlimited | Select DisplayName,Alias,PrimarySMTPAddress,Database | export-csv -NoTypeInformation "$logpath\MailboxDetails-EXOnline.csv" -append


### The following scripts output any forwarders configured on mailboxes ###
Get-Mailbox -ResultSize Unlimited | Where {($_.ForwardingAddress -ne $Null) -or ($_.ForwardingsmtpAddress -ne $Null)} | Select Name, DisplayName, PrimarySMTPAddress, UserPrincipalName, ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward | export-csv -NoTypeInformation "$logpath\MailboxesWithForwarding-EXOnline.csv"


### The following scripts output which accounts are configured for MFA ###
Get-MsolUser | Where {$_.StrongAuthenticationMethods -ne $null} | foreach {
    ForEach ($entry in $_.StrongAuthenticationMethods) {
        $Data = New-Object PSObject
        $Data | Add-Member -MemberType NoteProperty –name UserPrincipalName –value $($_.UserPrincipalName)
        $Data | Add-Member -MemberType NoteProperty –name Default –value $($entry.IsDefault)
        $Data | Add-Member -MemberType NoteProperty –name MethodType –value $($entry.MethodType)
        #write-output $Data
        $Data | export-csv -NoTypeInformation -append -Path "$logpath\MFA-Users-And-Configuration.csv"
    }
}