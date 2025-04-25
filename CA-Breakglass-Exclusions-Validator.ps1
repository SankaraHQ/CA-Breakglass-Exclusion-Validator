<#
#############################################################################  
#                                                                           #  
#   This Sample Code is provided for the purpose of illustration only       #  
#   and is not intended to be used in a production environment.  THIS       #  
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #  
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #  
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #  
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #  
#   right to use and modify the Sample Code and to reproduce and distribute #  
#   the object code form of the Sample Code, provided that You agree:       #  
#   (i) to not use Our name, logo, or trademarks to market Your software    #  
#   product in which the Sample Code is embedded; (ii) to include a valid   #  
#   copyright notice on Your software product in which the Sample Code is   #  
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #  
#   Our suppliers from and against any claims or lawsuits, including        #  
#   attorneys' fees, that arise or result from the use or distribution      #  
#   of the Sample Code.                                                     # 
#                                                                           # 
#   This posting is provided "AS IS" with no warranties, and confers        # 
#   no rights. Use of included script samples are subject to the terms      # 
#   specified at http://www.microsoft.com/info/cpyright.htm.                # 
#                                                                           #  
#   Author: Sankara Narayanan M S                                           #  
#   Version 1.0                                                             #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    Validates the exclusion of the provided breakglass account using Microsoft Graph API.
    Created by: Sankara Narayanan M S
    Creation Date: 21 April 2025
    Date Last Modified: 21 April 2025
.DESCRIPTION
    This PowerShell script verifies that specified breakglass users and groups are excluded from all Conditional Access policies in your Microsoft Entra ID tenant, ensuring uninterrupted emergency access.
.EXAMPLE
    As a user, you may run this to validate if the specified breakglass user account is excluded from all conditional access policies.
    PS C:\> .\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassUsers "<user_mail_id>" 
.EXAMPLE
    As a user, you may run this to validate if the specified breakglass group is excluded from all conditional access policies.
    PS C:\> .\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassGroups "<group_displayName>"
.EXAMPLE
    As a user, you may run this to validate if the specified breakglass user and group is excluded from all conditional access policies.
    PS C:\> .\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassUsers "<user_mail_id>" -BreakGlassGroups "<group_displayName>"
.NOTES
    - Either a breakglass user account or a breakglass group must be provided

    - The script will connect to the Microsoft Graph service and collect the required information. 
        To install the latest modules:
        Install-Module Microsoft.Graph -AllowClobber -Force

        If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.
        
        $MaximumFunctionCount = 8192 
        $MaximumVariableCount = 8192

.LINK
    Github 
    https://github.com/microsoftgraph/msgraph-sdk-powershell 
    Microsoft Graph PowerShell Module
    https://www.powershellgallery.com/packages/Microsoft.Graph
#>



[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $TenantId,

    [Parameter(Mandatory = $false)]
    [string[]] $BreakGlassUsers,

    [Parameter(Mandatory = $false)]
    [string[]] $BreakGlassGroups
)

#Requires -Modules Microsoft.Graph

Write-Host "`nWelcome to the Breakglass Exclusion Validator script!"

if (-not $BreakGlassUsers -and -not $BreakGlassGroups) {
    Write-Host "At least one of the parameters -BreakGlassUsers or -BreakGlassGroups must be provided." -ForegroundColor Red
    return
}

try { 
    Connect-MgGraph -TenantId $TenantId -Scopes "Policy.Read.All", "User.Read.All", "Group.Read.All" -NoWelcome 
} catch { throw $_ }

$context = Get-MgContext
if (!$context) {
    Write-Host "Unable to connect to MS Graph" -ForegroundColor Red
    return
}

Write-Host "`nSuccessfully connected to MSGraph" -ForegroundColor DarkGreen
$script:BGUsers = @()
$script:BGGroups = @()

# Lookup users
if ($BreakGlassUsers) {
    Write-Host "`nThe breakglass user accounts $BreakGlassUsers will be checked..." -ForegroundColor DarkYellow
    foreach ($user in $BreakGlassUsers) {
        try {
            $userDetails = Get-MgUser -UserId $user
            if ($userDetails) {
                Write-Host "Found the breakglass user `"$($userDetails.DisplayName)`"" -ForegroundColor Cyan
                $script:BGUsers += $userDetails
            }
        } catch {
            Write-Host "`nUnable to find the account `"$user`" in your directory. Try again." -ForegroundColor Red
        }
    }
}

# Lookup groups
if ($BreakGlassGroups) {
    Write-Host "`nThe breakglass groups $BreakGlassGroups will be checked..." -ForegroundColor DarkYellow
    foreach ($group in $BreakGlassGroups) {
        $groupDetails = Get-MgGroup -Filter "DisplayName eq '$($group)'"
        if ($groupDetails) {
            Write-Host "Found the breakglass group `"$($groupDetails.DisplayName)`"" -ForegroundColor Cyan
            $script:BGGroups += $groupDetails
        } else {
            Write-Host "`nUnable to find the group `"$group`" in your directory. Try again." -ForegroundColor Red
        }
    }
}

# Get all Conditional Access Policies
$AllPolicies = Get-MgIdentityConditionalAccessPolicy

# Initialize missing exclusions list
$MissingUserExclusions = @()
$MissingGroupExclusions = @()

# Check exclusions for users
foreach ($user in $script:BGUsers) {
    foreach ($policy in $AllPolicies) {
        if (-not ($policy.Conditions.Users.ExcludeUsers -contains $user.Id)) {
            $MissingUserExclusions += [PSCustomObject]@{
                PolicyName = $policy.DisplayName
                MissingUser = $user.UserPrincipalName
            }
        }
    }
}

# Check exclusions for groups
foreach ($group in $script:BGGroups) {
    foreach ($policy in $AllPolicies) {
        if (-not ($policy.Conditions.Users.ExcludeGroups -contains $group.Id)) {
            $MissingGroupExclusions += [PSCustomObject]@{
                PolicyName = $policy.DisplayName
                MissingGroup = $group.DisplayName
            }
        }
    }
}

# Output results
Write-Host "----------------------------------------------------------------------" -ForegroundColor Gray
Write-Host "`n### EXCLUSIONS SUMMARY REPORT ###" -ForegroundColor Yellow

if ($MissingUserExclusions.Count -eq 0 -and $MissingGroupExclusions.Count -eq 0) {
    Write-Host "`n✅ All breakglass users and groups are excluded from all policies." -ForegroundColor Green
} else {
    # Merge missing user and group exclusions into one summary
    $CombinedExclusions = @{}

    foreach ($entry in $MissingUserExclusions) {
        if (-not $CombinedExclusions.ContainsKey($entry.PolicyName)) {
            $CombinedExclusions[$entry.PolicyName] = @()
        }
        $CombinedExclusions[$entry.PolicyName] += $entry.MissingUser
    }

    foreach ($entry in $MissingGroupExclusions) {
        if (-not $CombinedExclusions.ContainsKey($entry.PolicyName)) {
            $CombinedExclusions[$entry.PolicyName] = @()
        }
        $CombinedExclusions[$entry.PolicyName] += $entry.MissingGroup
    }

    $FormattedResults = foreach ($policy in $CombinedExclusions.Keys) {
        [PSCustomObject]@{
            PolicyName     = $policy
            MissingEntities = ($CombinedExclusions[$policy] -join ", ")
        }
    }

    Write-Host "`n⚠️  Some policies are missing exclusions:" -ForegroundColor Red
    $FormattedResults | Sort-Object PolicyName | Format-Table PolicyName, MissingEntities -AutoSize
}

# Create timestamp for the filename
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ReportPath = "$PSScriptRoot\Breakglass_Exclusion_Report_$Timestamp.html"

if ($FormattedResults.Count -gt 0) {
    $htmlStyle = @"
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background-color: #f4f7fa;
            margin: 0;
            padding: 0;
            color: #333;
        }
        h2 {
            color: #2c3e50;
            font-size: 24px;
            padding: 20px;
            margin: 0;
            background-color: #ecf0f1;
            border-bottom: 2px solid #bdc3c7;
            text-align: left; /* Align title to the left */
        }
        table {
            width: 90%;
            margin: 30px auto;
            border-collapse: collapse;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
        }
        th {
            background-color: #2980b9;
            color: white;
            font-size: 16px;
        }
        td {
            background-color: #ecf0f1;
            font-size: 14px;
        }
        tr:nth-child(even) td {
            background-color: #f9f9f9;
        }
        tr:hover {
            background-color: #dfe6e9;
        }
        .footer-note {
            text-align: left; /* Align footer to the left */
            font-size: 12px;
            color: #7f8c8d;
            margin-top: 40px;
            padding-left: 20px; /* Add some left padding */
        }
        .footer-note a {
            color: #2980b9;
            text-decoration: none;
        }
    </style>
"@

    $htmlHeader = "<h2>Breakglass Exclusion Validator Report</h2>"
    $htmlBody = $FormattedResults | Sort-Object PolicyName | ConvertTo-Html -Property PolicyName, MissingEntities -Fragment
    $htmlFooter = "<div class='footer-note'><br/>Report generated on $(Get-Date -Format 'dd-MMM-yyyy hh:mm tt')</div>"
    $fullHtml = "<html><head>$htmlStyle</head><body>$htmlHeader$htmlBody$htmlFooter</body></html>"

    $fullHtml | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "`n📄 HTML report saved to: $ReportPath" -ForegroundColor Cyan
    Start-Process $ReportPath
}
