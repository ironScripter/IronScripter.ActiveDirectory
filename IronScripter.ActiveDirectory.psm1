<#
.NOTES
    Name: Get-ADUserTrusted
    Author: James Arnett
    Requires: ActiveDirectory Module

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
.SYNOPSIS
    Gathers AD User Related information on all trusted domains.
.DESCRIPTION
    This module is used to gather AD User information from all or selected trusted AD Domains. 

    It uses .Net forms to allow for selection of specific domains. It works very similarly to Get-ADUser in that the input variables used and properties that are returnable are the same.

    The Get-ADUserTrusted cmdlet gets a user object or performs a search to retrieve multiple user objects.

    The Identity parameter specifies the Active Directory user to get. You can identify a user by its distinguished name (DN), GUID, security identifier (SID), Security Accounts Manager (SAM) account name or
    name. You can also set the parameter to a user object variable, such as $<localUserObject> or pass a user object through the pipeline to the Identity parameter.

    To search for and retrieve more than one user, use the Filter parameters. The Filter parameter uses the PowerShell Expression Language to write query strings for Active Directory.
    PowerShell Expression Language syntax provides rich type conversion support for value types received by the Filter parameter. For more information about the Filter parameter syntax, see
    about_ActiveDirectory_Filter. 

    This cmdlet retrieves a default set of user object properties. To retrieve additional properties use the Properties parameter. For more information about the how to determine the properties for user
    objects, see the Properties parameter description.
.EXAMPLE
    Get-ADUserTrusted -Identity User1@contoso.com
    
    Get User1@contoso.com data from all trusted domains
.EXAMPLE
    Get-ADUserTrusted -Identity User1@contoso.com -AllDomains -Properties *

    Get User1@contoso.com all properties from all trusted domains
.PARAMETER Identity
    Specifies an Active Directory user object by providing one of the following property values. The identifier in parentheses is the LDAP display name for the attribute.

    Distinguished Name

    Example:  CN=SaraDavis,CN=Europe,CN=Users,DC=corp,DC=contoso,DC=com

    GUID (objectGUID)

    Example: 599c3d2e-f72d-4d20-8a88-030d99495f20

    Security Identifier (objectSid)

    Example: S-1-5-21-3165297888-301567370-576410423-1103

    SAM account name  (sAMAccountName)

    Example: saradavis

    The cmdlet searches the default naming context or partition to find the object. If two or more objects are found, the cmdlet returns a non-terminating error.

    This parameter can also get this object through the pipeline or you can set this parameter to an object instance.

    This example shows how to set the parameter to a distinguished name.

    -Identity  "CN=SaraDavis,CN=Europe,CN=Users,DC=corp,DC=contoso,DC=com"

    This example shows how to set this parameter to a user object instance named "userInstance".

    -Identity   $userInstance
.PARAMETER Filter
    Specifies a query string that retrieves Active Directory objects. This string uses the PowerShell Expression Language syntax. The PowerShell Expression Language syntax provides rich type-conversion
    support for value types received by the Filter parameter. The syntax uses an in-order representation, which means that the operator is placed between the operand and the value. For more information
    about the Filter parameter, see about_ActiveDirectory_Filter.

    Syntax:

    The following syntax uses Backus-Naur form to show how to use the PowerShell Expression Language for this parameter.

    <filter>  ::= "{" <FilterComponentList> "}"

    <FilterComponentList> ::= <FilterComponent> | <FilterComponent> <JoinOperator> <FilterComponent> | <NotOperator>  <FilterComponent>

    <FilterComponent> ::= <attr> <FilterOperator> <value> | "(" <FilterComponent> ")"

    <FilterOperator> ::= "-eq" | "-le" | "-ge" | "-ne" | "-lt" | "-gt"| "-approx" | "-bor" | "-band" | "-recursivematch" | "-like" | "-notlike"

    <JoinOperator> ::= "-and" | "-or"

    <NotOperator> ::= "-not"

    <attr> ::= <PropertyName> | <LDAPDisplayName of the attribute>

    <value>::= <compare this value with an <attr> by using the specified <FilterOperator>>

    For a list of supported types for <value>, see about_ActiveDirectory_ObjectModel.

    Examples:

    The following examples show how to use this syntax with Active Directory cmdlets.

    To get all objects of the type specified by the cmdlet, use the asterisk wildcard:

    All user objects on All Trusted Domains:

    Get-ADUserTrusted -Filter * -AllDomains
.PARAMETER Properties
    Specifies the properties of the output object to retrieve from the server. Use this parameter to retrieve properties that are not included in the default set.

    Specify properties for this parameter as a comma-separated list of names. To display all of the attributes that are set on the object, specify * (asterisk).

    To specify an individual extended property, use the name of the property. For properties that are not default or extended properties, you must specify the LDAP display name of the attribute.

    The following examples show how to use the Properties parameter to retrieve individual properties as well as the default, extended or complete set of properties.

    To retrieve the extended properties "OfficePhone" and "Organization" and the default properties of an ADUser object named "SaraDavis", use the following command:

    GetADUserTrusted -Identity SaraDavis  -Properties OfficePhone,Organization

    To retrieve the properties with LDAP display names of "otherTelephone" and "otherMobile", in addition to the default properties for the same user, use the following command:

    GetADUserTrusted -Identity SaraDavis  -Properties otherTelephone, otherMobile |Get-Member
.PARAMETER AllDomains
    Specifies that you would like to skip the selection prompt and check of all domains.

.INPUTS
    None or Microsoft.ActiveDirectory.Management.ADUser

    A user object is received by the Identity parameter.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADUser

    Returns one or more user objects.

    This cmdlet returns a default set of ADUser property values. To retrieve additional ADUser properties, use the Properties parameter.

    To get a list of the default set of properties of an ADUser object, use the following command:

    Get-ADUserTrusted -Identity <user> | Get-Member

    To get a list of the most commonly used properties of an ADUser object, use the following command:

    Get-ADUserTrusted -Identity <user> -Properties Extended | Get-Member

    To get a list of all the properties of an ADUser object, use the following command:

    Get-ADUserTrusted -Identity <user> -Properties * | Get-Member
#>
function Get-ADUserTrusted {
    [CmdletBinding(HelpUri = 'https://github.com/ironScripter/')]
    param (
        [Parameter(
            Mandatory=$true,
            ParameterSetName='Identity'
            )]
        [string]
        $Identity,

        [Parameter(
            Mandatory=$true,
            ParameterSetName='Filter'
            )]
        [string]
        $Filter,
        # Array of properties to return from AD User Object.
        [Parameter(ParameterSetName='Filter')]
        [Parameter(ParameterSetName='Identity')]
        [string[]]
        $Properties,
        # Switch param used for querying all domains without need for selection
        [Parameter(ParameterSetName='Filter')]
        [Parameter(ParameterSetName='Identity')]
        [switch]
        $AllDomains
    )

    # Build array containing all trusted domain names including current domain
    $Selections = @()
    $Selections += Get-ADTrust -Filter * | Select-Object Target -ExpandProperty Target
    $Selections += Get-ADDomain | Select-Object DNSRoot -ExpandProperty DNSRoot

    # Check to see if all domains switch is specified.
    switch ( $AllDomains ) 
    {
        $true 
        {
            $Domains = $Selections 
        }

        Default 
        {
             # Create a menu for user to select which domains to query
            $Domains = MultiEntryTypeMenu -Title "Which Domains would you like to query?" -Selections $Selections
        }
    }
    # Open empty array for results
    $RetObj = @()

    foreach ( $Domain in $Domains ) 
    {
        $Server = Get-ADForest -Server $Domain | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -ExpandProperty PDCEmulator
        
        $ArgSplat = @{
            'Server' = $Server
            'ErrorAction' = 'Stop'
        }

        if ( $Filter ) 
        {
            $null = $ArgSplat.Add('Filter', $Filter)
        }

        if ( $Identity ) 
        {
            $null = $ArgSplat.Add('Identity', $Identity)
        }

        if ( $Properties ) 
        {
            $null = $ArgSplat.Add('Properties', $Properties)
        }

        try 
        {
            $RetObj += Get-ADUser @ArgSplat
        }
        catch 
        {

            if ( $Filter ) 
            {
                Write-Warning -Message "Unable to find information for specified filter '$Filter' in '$Domain' `n Exception:`n$($_.Exception)"
            }

            if ( $Identity ) 
            {
                Write-Warning -Message "Unable to find information for '$Identity' in '$Domain' `n Exception:`n$($_.Exception)"
            }
        }
    }

    Return $RetObj

}
<#
.NOTES
    Name: Get-ADComputerTrusted
    Author: James Arnett
    Requires: ActiveDirectory Module

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
.SYNOPSIS
    Gathers AD Computer Related information on all trusted domains.
.DESCRIPTION
    This module is used to gather AD Computer information from all or selected trusted AD Domains. 

    It uses .Net forms to allow for selection of specific domains. It works very similarly to Get-ADUser in that the input variables used and properties that are returnable are the same.

    The Get-ADComputer cmdlet gets a computer or performs a search to retrieve multiple computers.

    The Identity parameter specifies the Active Directory computer to retrieve. You can identify a computer by its distinguished name (DN), GUID, security identifier (SID) or Security Accounts Manager (SAM)
    account name. You can also set the parameter to a computer object variable, such as $<localComputerObject> or pass a computer object through the pipeline to the Identity parameter.

    To search for and retrieve more than one computer, use the Filter or LDAPFilter parameters. The Filter parameter uses the PowerShell Expression Language to write query strings for Active Directory.
    PowerShell Expression Language syntax provides rich type conversion support for value types received by the Filter parameter. For more information about the Filter parameter syntax, see
    about_ActiveDirectory_Filter. If you have existing LDAP query strings, you can use the LDAPFilter parameter.

    This cmdlet retrieves a default set of computer object properties. To retrieve additional properties use the Properties parameter. For more information about the how to determine the properties for
    computer objects, see the Properties parameter description.
.EXAMPLE
    Get-ADComputerTrusted -Identity computer1

    Get computer1 data from all trusted domains
.EXAMPLE
    Get-ADComputerTrusted -Identity computer1 -AllDomains -Properties *
    
    Get computer1 all properties from all trusted domains
.PARAMETER Identity
    Specifies an Active Directory computer object by providing one of the following property values. The identifier in parentheses is the LDAP display name for the attribute.

    Distinguished Name

    Example: CN=SaraDavisDesktop,CN=Europe,CN=Users,DC=corp,DC=contoso,DC=com

    GUID  (objectGUID)

    Example: 599c3d2e-f72d-4d20-8a88-030d99495f20

    Security Identifier (objectSid)

    Example: S-1-5-21-3165297888-301567370-576410423-1103

    Security Accounts Manager Account Name (sAMAccountName)

    Example: SaraDavisDesktop

    The cmdlet searches the default naming context or partition to find the object. If the identifier given is a DN, the partition to search will be computed from that DN. If two or more objects are
    found, the cmdlet returns a non-terminating error.

    This parameter can also get this object through the pipeline or you can set this parameter to a computer object instance.

    This example shows how to set the parameter to a distinguished name.

    -Identity  "CN=saraDavisDesktop,CN=Europe,CN=Users,DC=corp,DC=contoso,DC=com"

    This example shows how to set this parameter to a computer object instance named "computerInstance".

    -Identity   $computerInstance
.PARAMETER Filter
    Specifies a query string that retrieves Active Directory objects. This string uses the PowerShell Expression Language syntax. The PowerShell Expression Language syntax provides rich type-conversion
    support for value types received by the Filter parameter. The syntax uses an in-order representation, which means that the operator is placed between the operand and the value. For more information
    about the Filter parameter, see about_ActiveDirectory_Filter.

    Syntax:

    The following syntax uses Backus-Naur form to show how to use the PowerShell Expression Language for this parameter.

    <filter>  ::= "{" <FilterComponentList> "}"

    <FilterComponentList> ::= <FilterComponent> | <FilterComponent> <JoinOperator> <FilterComponent> | <NotOperator>  <FilterComponent>

    <FilterComponent> ::= <attr> <FilterOperator> <value> | "(" <FilterComponent> ")"

    <FilterOperator> ::= "-eq" | "-le" | "-ge" | "-ne" | "-lt" | "-gt"| "-approx" | "-bor" | "-band" | "-recursivematch" | "-like" | "-notlike"

    <JoinOperator> ::= "-and" | "-or"

    <NotOperator> ::= "-not"

    <attr> ::= <PropertyName> | <LDAPDisplayName of the attribute>

    <value>::= <compare this value with an <attr> by using the specified <FilterOperator>>

    For a list of supported types for <value>, see about_ActiveDirectory_ObjectModel.

    Examples:

    The following examples show how to use this syntax with Active Directory cmdlets.

    To get all objects of the type specified by the cmdlet, use the asterisk wildcard:

    All computer objects on all trusted domains:

    Get-ADComputerTrusted -Filter * -AllDomains

.PARAMETER Properties
    Specifies the properties of the output object to retrieve from the server. Use this parameter to retrieve properties that are not included in the default set.

    Specify properties for this parameter as a comma-separated list of names. To display all of the attributes that are set on the object, specify * (asterisk).

    To specify an individual extended property, use the name of the property. For properties that are not default or extended properties, you must specify the LDAP display name of the attribute.

    The following examples show how to use the Properties parameter to retrieve individual properties as well as the default, extended or complete set of properties.

    To retrieve the extended properties "OfficePhone" and "Organization" and the default properties of an ADUser object named "SaraDavis", use the following command:

    GetADUserTrusted -Identity SaraDavis  -Properties OfficePhone,Organization

    To retrieve the properties with LDAP display names of "otherTelephone" and "otherMobile", in addition to the default properties for the same user, use the following command:

    GetADUserTrusted -Identity SaraDavis  -Properties otherTelephone, otherMobile |Get-Member
.PARAMETER AllDomains
    Specifies that you would like to skip the selection prompt and check all trusted domains.

.INPUTS
    None or Microsoft.ActiveDirectory.Management.ADComputer

    A computer object is received by the Identity parameter.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADComputer

    Returns one or more computer objects.

    This Get-ADComputer cmdlet returns a default set of ADComputer property values. To retrieve additional ADComputer properties, use the Properties parameter of this cmdlet.

    To view the properties for an ADComputer object, see the following examples. To run these examples, replace <computer> with a computer identifier such as the SAM account name of your local computer.

    To get a list of the default set of properties of an ADComputer object, use the following command:

    Get-ADComputerTrusted -Identity <computer>| Get-Member

    To get a list of all the properties of an ADComputer object, use the following command:

    Get-ADComputerTrusted -Identity <computer> -Properties ALL | Get-Member
#>
function Get-ADComputerTrusted {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,ParameterSetName='Identity')]
        [string]
        $Identity,

        [Parameter(Mandatory=$true,ParameterSetName='Filter')]
        [string]
        $Filter,

        [Parameter(ParameterSetName='Filter')]
        [Parameter(ParameterSetName='Identity')]
        [string[]]
        $Properties,
        
        # Switch param used for querying all domains without need for selection
        [Parameter(ParameterSetName='Filter')]
        [Parameter(ParameterSetName='Identity')]
        [switch]
        $AllDomains
    )

    # Build array containing all trusted domain names including current domain
    $Selections = @()
    $Selections += Get-ADTrust -Filter * | Select-Object Target -ExpandProperty Target
    $Selections += Get-ADDomain | Select-Object DNSRoot -ExpandProperty DNSRoot

    # Check to see if all domains switch is specified.
    switch ( $AllDomains ) 
    {
        $true 
        { 
            $Domains = $Selections 
        }
        
        Default 
        {
             # Create a menu for user to select which domains to query
            $Domains = MultiEntryTypeMenu -Title "Which Domains would you like to query?" -Selections $Selections
        }
    }
    
    # Open empty array for results.
    $RetObj = @()

    foreach ( $Domain in $Domains ) 
    {
        $Server = Get-ADForest -Server $Domain | Select-Object -ExpandProperty RootDomain | Get-ADDomain | Select-Object -ExpandProperty PDCEmulator

        $ArgSplat = @{
            'Server' = $Server
            'ErrorAction' = 'Stop'
        }

        If ( $Filter ) 
        {
            $null = $ArgSplat.Add('Filter', $Filter)
        }

        if ( $Identity ) 
        {
            $null = $ArgSplat.Add('Identity', $Identity)
        }

        if ( $Properties ) 
        {
            $null = $ArgSplat.Add('Properties', $Properties)
        }

        try 
        {
            $RetObj += Get-ADComputer @ArgSplat
        }
        catch 
        {
            if ( $Filter ) 
            {
                Write-Warning -Message "Unable to find information for specified filter '$Filter' in '$Domain' `n Exception:`n$($_.Exception)"
            }

            if ( $Identity ) 
            {
                Write-Warning -Message "Unable to find information for '$Identity' in '$Domain' `n Exception:`n$($_.Exception)" 
            }
        }
    }

    Return $RetObj

}
Function MultiEntryTypeMenu {
    param (
        # Title of the menu window
        [Parameter(
            Mandatory=$true
            )]
        [string]
        $Title,
        # an array of strings to use for selections
        [Parameter(
            Mandatory=$true
            )]
        [String[]]
        $Selections
    )

    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(400,300)
    $form.StartPosition = 'CenterScreen'

    

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(180,200)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(265,200)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Use CTRL or SHIFT to select multiple items'
    $form.Controls.Add($label)

    

    $EventTypeBox = New-Object System.Windows.Forms.Listbox
    $EventTypeBox.Location = New-Object System.Drawing.Point(20,40)
    $EventTypeBox.Size = New-Object System.Drawing.Size(340,125)
    $EventTypeBox.SelectionMode = 'MultiExtended'

    ForEach ( $Selection in $Selections ) {

        [void] $EventTypeBox.Items.Add($Selection)

    }
    
    $form.Controls.Add($EventTypeBox)
    $form.Topmost = $true
    $EventTyperesult = $form.ShowDialog()

    if ( $EventTyperesult -eq [System.Windows.Forms.DialogResult]::OK ) {

        $EventTypeBox.SelectedItems

    } else {

        break

    }
    
}
Export-ModuleMember -Function Get-ADUserTrusted, Get-ADComputerTrusted