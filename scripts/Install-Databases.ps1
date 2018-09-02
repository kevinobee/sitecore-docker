[CmdletBinding()]
param(
    # Location of the SQL Package executable
    [Parameter(Mandatory=$true)]
    [string]
    $SQL_package_exe,
    # Location for the SQL Sharding tool (provided with Sitecore)
    [Parameter(Mandatory=$true)]
    [string]
    $SQL_sharding_tool,
    # Prefix to add to Databases
    [Parameter(Mandatory=$true)]
    [string]
    $DB_Prefix
)

function Install-Database{
    [CmdletBinding()]
    param(
        $DacPac,
        $Name,
        $Prefix,
        $SQL_package_exe
    )
    $databaseName = "{0}_{1}" -f @($Prefix,$Name);
    Write-Verbose "Installing database $databaseName"
    & $SQL_package_exe /a:Publish /sf:$dacpac /tdn:$databaseName /tsn:$Env:COMPUTERNAME;
}

@(  "MarketingAutomation",
    "Processing.Pools",
    "Processing.Tasks",
    "ReferenceData",
    "Core",
    "Master",
    "Web",
    "Reporting",
    "Messaging",
    "EXM.Master",
    "ExperienceForms"
) | ForEach-Object {
    Install-Database `
        -Name $_ `
        -DacPac "c:/Files/Sitecore.$_.dacpac" `
        -Prefix $DB_Prefix `
        -SQL_package_exe $SQL_package_exe `
}

Write-Verbose "executing the SQL Sharding tool"

$DB_NAME='{0}_Xdb.Collection.ShardMapManager' -f $DB_Prefix
$SHARD_NAME_PREFIX='{0}_Xdb.Collection.' -f $DB_Prefix
$SHARD_NAME_SUFFIX='.Shard'
& $SQL_sharding_tool `
     /operation create `
     /connectionstring 'Server=.;Trusted_Connection=True;' `
     /dbedition Basic `
     /shardMapManagerDatabaseName "$DB_NAME" `
     /shardMapNames 'ContactIdShardMap,DeviceProfileIdShardMap,ContactIdentifiersIndexShardMap' `
     /shardnumber 2 `
     /shardnameprefix "$SHARD_NAME_PREFIX" `
     /shardnamesuffix "$SHARD_NAME_SUFFIX" `
     /dacpac '/Files/Sitecore.Xdb.Collection.Database.Sql.dacpac'

Write-Verbose "running scripts to change db owner to sa"

@(
    "UPDATE [{0}_Xdb.Collection.ShardMapManager].[__ShardManagement].[ShardsGlobal] SET ServerName = '{1}'" -f $DB_Prefix, $Env:HOST_NAME
    "EXEC sp_MSforeachdb 'IF charindex(''Sitecore'', ''?'' ) = 1 BEGIN EXEC [?]..sp_changedbowner ''sa'' END'"
) | ForEach-Object {
    & sqlcmd -Q $_
}
