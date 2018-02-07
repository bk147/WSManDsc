$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
    -ChildPath (Join-Path -Path 'WSManDsc.ResourceHelper' `
        -ChildPath 'WSManDsc.ResourceHelper.psm1'))

# Import Localization Strings
$LocalizedData = Get-LocalizedData `
    -ResourceName 'DSR_WSManClient' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    This is an array of all the parameters used by this resource.
    The default and testval properties are only used by unit/integration tests
    but is stored here so that a duplicate table does not have to be created.
    The IntTests controls whether or not this parameter should be tested using
    integration tests. This prevents integration tests from preventing the WS-Man
    Service from being completely locked out.
#>
$resourceData = Import-LocalizedData `
    -BaseDirectory $PSScriptRoot `
    -FileName 'DSR_WSManClient.data.psd1'

$script:parameterList = $resourceData.ParameterList

<#
    .SYNOPSIS
    Returns the WS-Man Client configuration.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingWSManClientMessage)
        ) -join '' )

    # Generate the return object.
    $returnValue = @{
        IsSingleInstance = 'Yes'
    }
    foreach ($parameter in $script:parameterList)
    {
        $ParameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
            -ChildPath $($parameter.Path)
        $returnValue += @{ $($parameter.Name) = (Get-Item -Path $ParameterPath).Value }
    } # foreach

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
    Sets the current WS-Man Client configuration.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'

    .PARAMETER TrustedHosts
    Specifies the hosts trusted by the client.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $TrustedHosts
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.SettingWSManClientMessage)
        ) -join '' )

    # Step through each parameter and update any that differ
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Set-Item -Path $parameterPath -Value $parameterNew -Force

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManClientUpdateParameterMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )
        } # if
    } # foreach
} # Set-TargetResource

<#
    .SYNOPSIS
    Tests the current WS-Man Service configuration to see if any changes need to be made.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'

    .PARAMETER TrustedHosts
    Specifies the hosts trusted by the Client.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter()]
        [System.String]
        $TrustedHosts
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.TestingWSManClientMessage)
        ) -join '' )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    # Check each parameter
    foreach ($parameter in $script:parameterList)
    {
        $parameterPath = Join-Path `
            -Path 'WSMan:\Localhost\Client\' `
            -ChildPath $parameter.Path

        $parameterCurrent = (Get-Item -Path $parameterPath).Value
        $parameterNew = (Get-Variable -Name $parameter.Name).Value

        if ($PSBoundParameters.ContainsKey($parameter.Name) `
            -and ($parameterCurrent -ne $parameterNew))
        {
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.WSManClientParameterNeedsUpdateMessage) `
                    -f $parameter.Name,$parameterCurrent,$parameterNew
                ) -join '' )

            $desiredConfigurationMatch = $false
        } # if
    } # foreach

    return $desiredConfigurationMatch
} # Test-TargetResource

Export-ModuleMember -Function *-TargetResource
