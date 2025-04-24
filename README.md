# CA Breakglass Exclusions Validator
 A script to verify and report whether all the specified breakglass users and groups are excluded from all Conditional Access policies.

## 🔍 Overview

**CA Breakglass Exclusions Validator** tool helps validate whether your designated **breakglass accounts** (emergency access users or groups) are **excluded** from all Conditional Access (CA) policies in your Microsoft Entra ID (Azure AD) tenant by generating a user-friendly report. This ensures that emergency accounts retain access even if policies inadvertently restrict other users.

This tool is useful for Azure AD/Microsoft Entra administrators and security teams who need to ensure emergency access accounts remain functional during access policy misconfigurations. It helps enforce best practices by validating breakglass account exclusions across all Conditional Access policies.

The script:
- Connects to Microsoft Graph using the `Microsoft.Graph` PowerShell SDK.
- Identifies specified breakglass users and groups.
- Validates that they are excluded from all active Conditional Access policies.
- Generates a summary report of any missing exclusions.
- Outputs a styled HTML report highlighting which CA policies are missing exclusions.


## 🧰 Prerequisites

- PowerShell 5.1+ (or PowerShell Core)
- Microsoft.Graph module  
  Install it using:

  ```powershell
  Install-Module Microsoft.Graph -AllowClobber -Force
  ```

 ## 🔧 Parameters

| Parameter	| Description | 
|-----------|-------------|
| -TenantId	| The Entra ID tenant GUID |
| -BreakGlassUsers	| Email addresses of emergency access user accounts |
| -BreakGlassGroups	| Display names of emergency access groups |

⚠️ _Either -BreakGlassUsers or -BreakGlassGroups must be provided_

## 🧪 Usage Examples
🔹 **Validate breakglass user accounts** : 
```
.\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassUsers "<group_displayName>"
```

🔹 **Validate breakglass groups** : 

```
.\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassGroups "<group_displayName>"
```

🔹 **Validate both breakglass user and group** :  
```
.\CA-Breakglass-Exclusions-Validator.ps1 -TenantId "<tenant_guid>" -BreakGlassUsers "<user_mail_id>" -BreakGlassGroups "<group_displayName>"
```

 ## 🔐 Scopes Required
The script connects with the following Microsoft Graph scopes:
- Policy.Read.All
- User.Read.All
- Group.Read.All

## 📤 Output
After execution, the script provides the following output:

✅ **Console Summary**: 
<br> A clear summary is printed in the terminal showing the list of policies that are missing the necessary exclusions.

📝 **HTML Report**: 
<br> A HTML report is generated in the same directory as the script. It includes:
- A styled table listing all the CA policies missing the required breakglass exclusions.
- Timestamp of the evaluation for audit or record-keeping purposes.

The report filename follows the pattern:
```
Breakglass_Exclusion_Report_<timestamp>.html
```

## 🔄 Updates
```
21 Apr 2025
        Added the MVP script
```
## 📄 License
This project is licensed under the [MIT License](LICENSE).