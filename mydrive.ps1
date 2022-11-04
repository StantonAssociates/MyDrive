#
# <copyright file="mydrive.ps1" company="StantonAssociates">
#    Copyright (c) Stanton Associates Corporation. All rights reserved.
# </copyright>
#
# <summary>
#    Powershell based tool to display local disk information.
# </summary>
#

Add-Type –assemblyName PresentationFramework

# UI Code
[xml]$Xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:MyDrives"
        Title="MyDrive" Height="665" Width="800" ResizeMode="NoResize">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Name="R1" Height="Auto"></RowDefinition>
            <RowDefinition Name="R2" Height="Auto"></RowDefinition>
            <RowDefinition Name="R3" Height="Auto"></RowDefinition>
            <RowDefinition Name="R4" Height="Auto"></RowDefinition>
            <RowDefinition Name="R5" Height="Auto"></RowDefinition>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Name="C1" Width="30*"></ColumnDefinition>
            <ColumnDefinition Name="C2" Width="10*"></ColumnDefinition>
            <ColumnDefinition Name="C3" Width="60*"></ColumnDefinition>
        </Grid.ColumnDefinitions>

        <Label Name="DiskDrivesLabel" Content="Disk Drives"
               Grid.Row="0" FontSize="14" HorizontalContentAlignment="Center"
               Grid.ColumnSpan="1" Grid.Column="0" Background="LightGray" Height="30" Width="240"/>

        <Label Name="BasicInformationLabel" Content="Basic Information"
               Grid.Row="0" FontSize="14" HorizontalContentAlignment="Center"
               Grid.ColumnSpan="2" Grid.Column="1" Background="LightGray" Height="30" Width="560"/>
        
        <ListBox Name="AllDiskDrivesListBox" Grid.Row="1" Grid.ColumnSpan="2" Grid.Column="0" Height="200">
        </ListBox>

        <Button Name="FetchButton" HorizontalAlignment="Stretch" HorizontalContentAlignment="Center" VerticalAlignment="Top"
                Content="Fetch" Grid.Row="1" Grid.Column="1" FontSize="14" Height="30" Width="80"/>

        <Label Name="EmptyLabel"
               Grid.Row="1" FontSize="14" VerticalAlignment="Center"
               Grid.ColumnSpan="1" Grid.Column="1" Background="LightGray" Height="140" Width="80"/>
        
        <Button Name="ClearButton" HorizontalAlignment="Stretch" HorizontalContentAlignment="Center" VerticalAlignment="Bottom"
                Content="Clear" Grid.Row="1" Grid.Column="1" FontSize="14" Height="30" Width="80"/>
               
        <ListBox Name="AllDiskDrivesInformationListBox" Grid.Row="1" Grid.ColumnSpan="1" Grid.Column="2" Height="200" Width="480">
        </ListBox>

        <Label Name="DetailedInformationLabel" Content="Detailed Information"
               Grid.Row="2" FontSize="14" HorizontalContentAlignment="Center"
               Grid.ColumnSpan="3" Grid.Column="0" Background="LightGray" Height="30" Width="800"/>
        
        <ListBox Name="AllDiskDrivesDetailedInformationListBox" Grid.Row="3" Grid.ColumnSpan="3" Grid.Column="0" Height="377"
                 ScrollViewer.HorizontalScrollBarVisibility="Visible" ScrollViewer.VerticalScrollBarVisibility="Visible">
        </ListBox>
    </Grid>
</Window>
"@

$XmlNodeReader=(New-Object System.Xml.XmlNodeReader $Xaml)
$Window=[Windows.Markup.XamlReader]::Load($XmlNodeReader)

# Hashtable for data
$MyDrives = [hashtable]::Synchronized(@{})
$MyDisks = [hashtable]::Synchronized(@{})

# Get buttons
$FetchButton = $Window.FindName("FetchButton")
$ClearButton = $Window.FindName("ClearButton")

# Get listbox
$AllDiskDrivesListBox = $Window.FindName("AllDiskDrivesListBox")
$AllDiskDrivesInformationListBox = $Window.FindName("AllDiskDrivesInformationListBox")
$AllDiskDrivesDetailedInformationListBox = $Window.FindName("AllDiskDrivesDetailedInformationListBox")

Function ClearInformation
{
  $AllDiskDrivesListBox.Items.Clear()
  $AllDiskDrivesInformationListBox.Items.Clear()
  $AllDiskDrivesDetailedInformationListBox.Items.Clear()
}

Function ClearButtonHandler
{
  $ClearButton.IsEnabled = $false

  ClearInformation

  $FetchButton.IsEnabled = $true
}

Function FetchButtonHandler
{
  $FetchButton.IsEnabled = $false

  $CurrentSelection = $AllDiskDrivesListBox.SelectedItem;

  ClearInformation

  $Disks= Get-Disk
  $MyDisks.Clear()

  foreach ($Disk in $Disks)
  {
    if ($Disk.SerialNumber)
    {
      $MyDisks.Add($Disk.SerialNumber.ToString().Trim(), $Disk)
    }
  }

  $Drives= (Get-PhysicalDisk | Where SerialNumber)
  $MyDrives.Clear()

  foreach ($Drive in $Drives)
  {
    if ($Drive.FriendlyName)
    {
      $MyDrives.Add($Drive.FriendlyName, $Drive)
      $AllDiskDrivesListBox.Items.Add($Drive.FriendlyName)
    }
  }
  if ($CurrentSelection)
  {
    $AllDiskDrivesListBox.SelectedItem = $CurrentSelection
  }
  else
  {
    $AllDiskDrivesListBox.SelectedItem = $AllDiskDrivesListBox.Items[0]
  }

  $ClearButton.IsEnabled = $true
}

Function SelectedDiskDriveChangedHandler
{
  if ($MyDrives.Count -eq 0 -or $AllDiskDrivesListBox.Items.Count -eq 0)
  {
    return
  }

  $FriendlyNameOfSelectedDisk = $AllDiskDrivesListBox.SelectedItem.ToString()
  $SerialNumberOfSelectedDisk = $MyDrives[$FriendlyNameOfSelectedDisk].SerialNumber

  $AllDiskDrivesInformationListBox.Items.Clear()
  $AllDiskDrivesDetailedInformationListBox.Items.Clear()

  #Disk Counters
  $AllDiskDrivesInformationListBox.Items.Add("Size : " + [math]::round($MyDisks[$SerialNumberOfSelectedDisk].Size/1Gb, 2) + " Gb")
  $AllDiskDrivesInformationListBox.Items.Add("BootFromDisk : " + $MyDisks[$SerialNumberOfSelectedDisk].BootFromDisk)

  $AllDiskDrivesDetailedInformationListBox.Items.Add("DiskNumber : " + $MyDisks[$SerialNumberOfSelectedDisk].DiskNumber)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("NumberOfPartition : " + $MyDisks[$SerialNumberOfSelectedDisk].NumberOfPartitions)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("PartitionStyle : " + $MyDisks[$SerialNumberOfSelectedDisk].PartitionStyle)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("ProvisioningType : " + $MyDisks[$SerialNumberOfSelectedDisk].ProvisioningType)

  #Drive Counters
  $AllDiskDrivesInformationListBox.Items.Add("HealthStatus : " + $MyDrives[$FriendlyNameOfSelectedDisk].HealthStatus)
  $AllDiskDrivesInformationListBox.Items.Add("FirmwareVersion : " + $MyDrives[$FriendlyNameOfSelectedDisk].FirmwareVersion)
  $AllDiskDrivesInformationListBox.Items.Add("BusType : " + $MyDrives[$FriendlyNameOfSelectedDisk].BusType)
  $AllDiskDrivesInformationListBox.Items.Add("MediaType : " + $MyDrives[$FriendlyNameOfSelectedDisk].MediaType)

  $AllDiskDrivesInformationListBox.Items.Add("Model : " + $MyDrives[$FriendlyNameOfSelectedDisk].Model)
  $AllDiskDrivesInformationListBox.Items.Add("SerialNumber : " + $MyDrives[$FriendlyNameOfSelectedDisk].SerialNumber)

  $AllDiskDrivesDetailedInformationListBox.Items.Add("ObjectId : " + $MyDrives[$FriendlyNameOfSelectedDisk].ObjectId)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("CanPool : " + $MyDrives[$FriendlyNameOfSelectedDisk].CanPool)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("CannotPoolReason : " + $MyDrives[$FriendlyNameOfSelectedDisk].CannotPoolReason)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("DeviceId : " + $MyDrives[$FriendlyNameOfSelectedDisk].DeviceId)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("PhysicalLocation : " + $MyDrives[$FriendlyNameOfSelectedDisk].PhysicalLocation)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("IsIndicationEnabled : " + $MyDrives[$FriendlyNameOfSelectedDisk].IsIndicationEnabled)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("Usage : " + $MyDrives[$FriendlyNameOfSelectedDisk].Usage)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("UniqueIdFormat : " + $MyDrives[$FriendlyNameOfSelectedDisk].UniqueIdFormat)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("SupportedUsages : " + $MyDrives[$FriendlyNameOfSelectedDisk].SupportedUsages)

  $AllDiskDrivesDetailedInformationListBox.Items.Add("SpindleSpeed : " + $MyDrives[$FriendlyNameOfSelectedDisk].SpindleSpeed)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("IsPartial : " + $MyDrives[$FriendlyNameOfSelectedDisk].IsPartial)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("LogicalSectorSize : " + $MyDrives[$FriendlyNameOfSelectedDisk].LogicalSectorSize)

  $AllDiskDrivesDetailedInformationListBox.Items.Add("PhysicalSectorSize : " + $MyDrives[$FriendlyNameOfSelectedDisk].PhysicalSectorSize)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("UniqueId : " + $MyDrives[$FriendlyNameOfSelectedDisk].UniqueId)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("OperationalStatus : " + $MyDrives[$FriendlyNameOfSelectedDisk].OperationalStatus)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("AllocatedSize : " + $MyDrives[$FriendlyNameOfSelectedDisk].AllocatedSize)
  $AllDiskDrivesDetailedInformationListBox.Items.Add("VirtualDiskFootprint : " + $MyDrives[$FriendlyNameOfSelectedDisk].VirtualDiskFootprint)
}

$FetchButton.Add_Click({FetchButtonHandler})
$ClearButton.Add_Click({ClearButtonHandler})

$AllDiskDrivesListBox.Add_SelectionChanged({SelectedDiskDriveChangedHandler})

$ClearButton.IsEnabled = $false
FetchButtonHandler | Out-Null
$Window.ShowDialog() | Out-Null