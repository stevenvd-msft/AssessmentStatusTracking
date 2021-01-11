<#PSScriptInfo

.VERSION 1.3
Added wait of 15 seconds if script is started before the assessment process is running. Need to copy files first.
Added logging of current and previous collector/analyzer.


.VERSION 1.2
Added script version logging
Added Event ID for stop/start/Assessment
        Event ID 001 - Starting Logging Scirpt
        Event ID 002 - OMS Process not found
		Event ID 003 - Waiting for Files to be generated
        Event ID 1000 - Phase 1 Starting
        Event ID 2000 - Phase 2 Starting
        Event ID 3000 - Phase 3 Starting
        Event ID 4000 - Phase 4 Starting
        Event ID 5000 - Phase 5 Starting
        Event ID 6000 - Phase 6 Starting
        Event ID 7000 - Phase 7 Starting
        Event ID 8000 - Phase 8 Starting
		Event ID 8001 - Phase 8 Recommendations Processing
		Event ID 8002 - Phase 8 Recommendations Processing Threshold Exceed or Process No Longer Exist
		Event ID 8003 - Copy recommendation files and finishing the assessment
        Event ID 8004 - Recommendations Files Upload Started
        Event ID 8005 - Recommendations Files Upload Completed
        Event ID 9000 - Ending Logging Script

.VERSION 1.1

.COMPANYNAME Microsoft

#>

<#
.SYNOPSIS 
    Gathers information on script execution and logs an event in the event viewer with the progress of data collection

.DESCRIPTION
    This script collects information, collected data and assessment logs and logs an event in the event viewer with the progress of data collection

Instructions to use : 
    Start after data colection is started.
    It needs to run as admin (needed for creating new event log)
    Interval parameter to be added in seconds, logs one event log each time and on screen.

#>

param([int]$interval)

##clear-host



If(!$interval)
{
    [int]$interval = Read-Host "Please enter the time interval to wait between the records (Seconds)"
}
#------------------------------------- Variable Declaration Section--------------------------------------------------------------------

$ErrorActionPreference = "continue"
$AssessmentName = $null
[string]$logname = "On-Demand Assessment status"
#$PatternArray = "Method=Main Message=Invoking the ConfigurationManager","Method=Main Message=Finished Invoking the ConfigurationManager","Method=LoadInternal Message=Unpacking package.","InterrogatorInitialized: Phase=Discovery Interrogator","InterrogationCompleted: Phase=Discovery Successful","Prerequisite success rate","type=collector Duration=","Type=Analyzer Duration","Type=Reporter","Message=GetIgnoreRecommendationsIds"
$PatternArray = "Method=Main Message=Invoking the ConfigurationManager","Method=Main Message=Finished Invoking the ConfigurationManager","Method=LoadInternal Message=Unpacking package.","InterrogatorInitialized: Phase=Discovery Interrogator","InterrogationCompleted: Phase=Discovery Successful","Prerequisite success rate","type=collector Duration=","Type=Analyzer Duration","Type=Reporter","Message=GetIgnoreRecommendationsIds","Name","WorkflowStarted","WorkflowCompleted"
$Progresscounter = 0
$script:OutputDirectory = $null
$Script:OriginalPath = $null
$script:path = $null
$PathPattern = "ADAssessment","ADSecurityAssessment","ExchangeAssessment","SPAssessment","SfBAssessment","SCCMAssessment","SCOMAssessment","SQLAssessment","ExchangeOnlineAssessment","SharePointOnlineAssessment","SfBOnlineAssessment","WindowsServerAssessment","WindowsClientAssessment"
Add-Type -AssemblyName System.Windows.Forms


$Version = "1.3_20201108"

#------------------------------------- FUNCTION SECTION BEGINS------------------------------------------------------------------------
#FUNCTIONS TO PERFORM DIFFERENT ACTIONS

function Get-OutputDirectory ($Npath)
{ 
   
        $Script:OutputDirectory = $Npath
        #Write-Host $OutputDirectory
        return $Script:OutputDirectory
}
function get-Originalpath($opath)
{
       $Script:OriginalPath = $opath
       #Write-Host $OriginalPath
       return $Script:OriginalPath
}

#---------------------------------- FUNCTION SECTION ENDS -----------------------------------------------------------------------------

#Write-host "DEBUG"  -ForegroundColor Red


$OMSProcesses = Get-Process OMSAssessment -ErrorAction SilentlyContinue|Select-Object ProcessName,path 
If($OMSProcesses.count -eq 0)
{
    Write-Host "No Data collection Process is currently running, waiting 15 seconds......"
    Start-Sleep 15
	$OMSProcesses = Get-Process OMSAssessment -ErrorAction SilentlyContinue|Select-Object ProcessName,path 
	If($OMSProcesses.count -eq 0)
	{
    Write-Host "No Data collection Process is running exiting......"
    Start-Sleep 5
    Exit;
    }
}

# GENERATING GUI FORM WITH BUTTONS.
if($OMSProcesses.count -gt 1)
{
        $Form = New-Object system.Windows.Forms.Form
        $Form.Size = New-Object System.Drawing.Size(600,350)
        $form.MaximizeBox = $false
        $Form.MinimizeBox = $false
        #$Form.ControlBox = $false
        $form.BackColor = "AliceBlue"
        $Form.StartPosition = "CenterScreen"
        $Form.FormBorderStyle = 'Fixed3D'
        $Form.Text = "Health Assessment status check"
        $Form.Topmost = $True

        $Label = New-Object System.Windows.Forms.Label
        $Label.Text = "Found Multiple assessment running. Please choose which one to track the status for :"
        $Label.AutoSize = $true
        $Label.Location = New-Object System.Drawing.Size(15,10)
        $Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold)
        $form.Font = $Font
        $Form.Controls.Add($Label)

        $ButtonPosition = 50
        foreach($OMSProcess in $OMSProcesses)
        {
                $OMSProcessesPath = $OMSProcess.path

                $PathPattern | ForEach-Object { IF ($OMSProcessesPath -match "(.+?)((?i)($_)(?-i))")
                                                    {
                                                        $script:path = $matches[0]
                                                    }
                                                }

                $button = New-Object System.Windows.Forms.Button
                $button.Location = New-Object System.Drawing.Size(150,$ButtonPosition)
                $button.Size = New-Object System.Drawing.Size(300,40)
                $button.BackColor ="Lightgray"
                $button.Text = $Path
                $Button.Tag = $OMSProcessesPath
                $Button.Add_Click({$var = (($($this.text)));$var1 = (($($this.tag)));Get-OutputDirectory ($var);get-Originalpath($var1);$Form.Close() |Out-Null})
                $Form.Controls.Add($button)
                $ButtonPosition = $ButtonPosition + 60
        }

 $Form.ShowDialog() |Out-Null
}
else
{
                $OMSProcessesPath = $OMSProcesses.path
                $Script:OriginalPath = $OMSProcessesPath

                $PathPattern | ForEach-Object { IF ($OMSProcessesPath -match "(.+?)((?i)($_)(?-i))")
                                                    {
                                                        $Script:OutputDirectory = $matches[0]
                                                    }
                                                }
                
}

# Getting the exact assessment name

$Assessmentresult = $Script:OutputDirectory |Split-Path -Leaf
switch -wildcard ($Assessmentresult)
                            {
                               {(($Assessmentresult).Trim() -like "ADAssessment")} {$AssessmentName = "ADAssessmentPlus"}
                               {(($Assessmentresult).Trim() -like "ADSecurityAssessment")} {$AssessmentName = "ADSecurityAssessment"}
                               {(($Assessmentresult).Trim() -like "ExchangeAssessment")} {$AssessmentName = "ExchangeAssessment"}
                               {(($Assessmentresult).Trim() -like "SPAssessment")} {$AssessmentName = "SPAssessment"}
                               {(($Assessmentresult).Trim() -like "SfBAssessment")} {$AssessmentName = "SfBAssessment"}
                               {(($Assessmentresult).Trim() -like "SCCMAssessment")} {$AssessmentName = "SCCMAssessmentPlus"}
                               {(($Assessmentresult).Trim() -like "SCOMAssessment")} {$AssessmentName = "SCOMAssessmentPlus"}
                               {(($Assessmentresult).Trim() -like "SQLAssessment")} {$AssessmentName = "SQLAssessmentPlus"}
                               {(($Assessmentresult).Trim() -like "ExchangeOnlineAssessment")} {$AssessmentName = "ExchangeOnlineAssessment"}
                               {(($Assessmentresult).Trim() -like "SharePointOnlineAssessment")} {$AssessmentName = "SharePointOnlineAssessment"}
                               {(($Assessmentresult).Trim() -like "SfBOnlineAssessment")} {$AssessmentName = "SfBOnlineAssessment"}
                               {(($Assessmentresult).Trim() -like "WindowsServerAssessment")} {$AssessmentName = "WindowsServerAssessment"}
                               {(($Assessmentresult).Trim() -like "WindowsClientAssessment")} {$AssessmentName = "WindowsClientAssessmentPlus"}
                               {(($Assessmentresult).Trim() -like "AzureAssessment")} {$AssessmentName = "AzureAssessment"}
                            }


# EVENT SOURCE NAME
[string]$eventsource = "$AssessmentName - Script"

## Initiating Event writing
Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- Assessment status check script started. Version: $Version" -ForegroundColor cyan
Write-EventLog -LogName $logname -Source $eventsource -Message “Assessment status check script started. Version: $Version" -EventId 001 -EntryType information -ErrorAction SilentlyContinue

# CHECKING IF EVENT SOURCE ALREADY PRESENT
if(!([System.Diagnostics.EventLog]::SourceExists($LogName)))
{
    Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- Checking if Event log already exist"
    New-EventLog -LogName $logname -Source $eventsource
    Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName status check script started" -EventId 001 -EntryType information -ErrorAction SilentlyContinue
}
else
{
    If(!([System.Diagnostics.EventLog]::SourceExists($eventsource)))
    {
        [System.Diagnostics.EventLog]::CreateEventSource("$eventsource", "$logname")
    }
}


Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection started!” -EventId 001 -EntryType information
Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection started!" -ForegroundColor cyan

## Finding the output directory created by assessment collection, to get the log file

 $outputDirectoryResults = ($originalpath -split "OmsAssessment")[0]
 #$Logdirectoryname = (get-childitem $outputDirectoryResults | Where-Object { $_.Name -match '^\d+$' }).name
 $Logdirectoryname = (get-childitem $outputDirectoryResults | Where-Object { $_.Name -match '^\d+$' -and $_.name -notlike $outputDirectoryResults.Split("_")[1] }|Sort-Object lastwritetime -Descending|select -First 1).name
 $logfilename = $outputDirectoryResults +"\" + $Logdirectoryname + "\" + "SironaLog_Advisor*.log"
 ## Write-Host "Log Directory: $Logdirectoryname"
 ## Finding the number of collectors and analyzers from the Execution config file

 $Executionconfigfilepath =  $outputDirectoryResults + "\" + $Logdirectoryname + "\Temp\Execution\" + $AssessmentName + "\" + "Executionconfig.xml"

 $retrycount = 0
 While(!(Test-Path $Executionconfigfilepath) -and $retrycount -lt 5)
     {
            ## Waiting for data execution to proceed
            Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- Waiting for Files to be generated" -ForegroundColor cyan
            
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName  Waiting for Files to be generated!” -EventId 003 -EntryType information

            start-sleep -Seconds $interval
            $retrycount = $retrycount +1
     }


 [xml]$Executionconfigdata = Get-Content $Executionconfigfilepath
 $collectorscount = ($Executionconfigdata.ExecutionConfiguration.Collectors.CollectorRef).Count
 $analyzercount = ($Executionconfigdata.ExecutionConfiguration.Analyzers.AnalyzerRef).count

While((get-process OMSAssessment -ErrorAction SilentlyContinue) -and $Progresscounter -ne 8)
{       
        $phase = 1
        [int]$EventCode = "1000"
        # start from Message=Invoking the ConfigurationManager
        If($Progresscounter -eq 0 -and ((Select-String -pattern $PatternArray[0] $logfilename).Matches.Count -ne 0))
        {
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status: Phase : $Phase out of 8 : Configuration Manager Invoked” -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Configuration Manager Invoked" -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Configuration Manager Invoked" -PercentComplete $currentphase -Id 1
            while((Select-String -pattern $PatternArray[1] $logfilename).Matches.Count -eq 0)
            {
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status: Phase : $Phase out of 8 : Waiting for Configuration Manager” -EventId $EventCode -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : waiting for Configuration Manager " -ForegroundColor cyan
                $currentphase= [math]::floor(($phase / 8)*100)
                Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Waiting for Configuration Manager" -PercentComplete $currentphase -Id 1
                start-sleep -Seconds $interval
            }

            $Progresscounter = 1
            $phase = 2
        }

        # start from "Unpacking package." till discovery start 
        If(($Progresscounter -eq 1) -and ((Select-String -pattern $PatternArray[2] $logfilename).Matches.Count -ne 0))
        {
            $phase = 2
            [int]$EventCode = "2000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Unpacking of packages started" -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Unpacking of packages started" -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Unpacking of packages started" -PercentComplete $currentphase -Id 1
            while((Select-String -pattern $PatternArray[3] $logfilename).Matches.Count -eq 0)
            {
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Waiting for  Unpacking of packages " -EventId $EventCode -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Waiting for Unpacking of packages" -ForegroundColor cyan
                $currentphase= [math]::floor(($phase / 8)*100)
                Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Waiting for Unpacking of packages" -PercentComplete $currentphase -Id 1
                start-sleep -Seconds $interval
            }

            $Progresscounter = 2
            $phase = 3
        }

        # Discovery phase check = start from discovery start to end  
        If($Progresscounter -eq 2 -and ((Select-String -pattern $PatternArray[3] $logfilename).Matches.Count -ne 0))
        {
            $phase = 3
            [int]$EventCode = "3000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Discovery phase started" -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Discovery phase started" -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Discovery phase started" -PercentComplete $currentphase -Id 1

            while((Select-String -pattern $PatternArray[4] $logfilename).Matches.Count -eq 0)
            {
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Waiting for Discovery phase to complete" -EventId $EventCode -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Waiting for Discovery phase to complete" -ForegroundColor cyan
                $currentphase= [math]::floor(($phase / 8)*100)
                Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Waiting for Discovery phase" -PercentComplete $currentphase -Id 1
                start-sleep -Seconds $interval
            } 
                
            $Progresscounter = 3
            $phase = 4
        }

        # discovery phase end to "Prerequisite success rate"
        If($Progresscounter -eq 3 -and ((Select-String -pattern $PatternArray[4] $logfilename).Matches.Count -gt 0))
        {   
            $phase = 4
            [int]$EventCode = "4000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Running Prerequisite checks. " -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Running Prerequisite Checks. " -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Running Prerequisite Checks" -PercentComplete $currentphase -Id 1
            
            while((Select-String -pattern $PatternArray[5] $logfilename).Matches.Count -eq 0)
            {
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Waiting for Prerequisite checks. " -EventId $EventCode -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Waiting for Prerequisite Checks. " -ForegroundColor cyan
                $currentphase= [math]::floor(($phase / 8)*100)
                Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Running Prerequisite Checks" -PercentComplete $currentphase -Id 1
                Start-Sleep -Seconds $interval
            }

            $Progresscounter = 4
            $phase = 5
        }

        # collectors Phase check = start from "Prerequisite success rate" to "type=collector Duration=" 
        If($Progresscounter -eq 4 -and ((Select-String -pattern $PatternArray[5] $logfilename).Matches.Count -ne 0))
        {   
            $phase = 5
            [int]$EventCode = "5000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing collectors. " -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing collectors. " -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Processing collectors" -PercentComplete $currentphase -Id 1

            $templogfile = "$outputDirectoryResults\$Logdirectoryname\temp.log"

            $lencounter = 0
            Do
                {
                    Copy-Item $logfilename $templogfile
                    $str = Get-Content $templogfile | out-string
                    $start = $str.indexOf("Prerequisite success rate") + 1
                    $end = (Get-Content $templogfile | Measure-Object -Character).Characters
                    $length = $end - $start

                    If($lencounter -ne 0)
                    {
                        Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Initiating collectors " -EventId $EventCode -EntryType information
                        #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Initiating collectors. " -ForegroundColor cyan
                        $currentphase= [math]::floor(($phase / 8)*100)
                        Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Initiating collectors" -PercentComplete $currentphase -Id 1
                        Start-Sleep -Seconds $interval
                    }
                    #$length
                    Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing collectors. This may take a while..." -EventId $EventCode -EntryType information
                    #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing collectors....still." -ForegroundColor cyan
                    $currentphase= [math]::floor(($phase / 8)*100)
                    Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Processing collectors.This may take a while..." -PercentComplete $currentphase -Id 1
					Start-Sleep -Seconds $interval
                }While($length -lt 0)

            $result = $str.substring($start, $length)
            $result | out-file  $templogfile
           
            while(((Select-String -pattern $PatternArray[6] $templogfile).Matches.Count -lt $collectorscount) -and (Select-String -pattern $PatternArray[7] $logfilename).Matches.Count -eq 0)  
                {
                    
                                        
                    $currentworkcount = (Select-String -pattern $PatternArray[6] $templogfile).Matches.Count
                    $templogfile = "$outputDirectoryResults\$Logdirectoryname\temp.log"
                    # Get Current and last completed steps from temp log file
                    $lastcompleted= Select-String -Pattern "Message=COMPLETED COLLECTOR: " $templogfile
                    if ($lastcompleted) {$lastcompleted= ($lastcompleted[-1] -split "Message=COMPLETED COLLECTOR: ")[-1]}
                    $currentwork= Select-String -Pattern "Message=STARTING COLLECTOR:  " $templogfile 
                    if ($currentwork) { $currentwork= ($currentwork[-1] -split "Message=STARTING COLLECTOR:  ")[-1]}
                    # Update eventcode based on $collectorscount - $currentworkcount
                    Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing collectors.`nCompleted substep: $lastcompleted. Working on substep: $currentwork ($currentworkcount out of $collectorscount)" -EventId ($EventCode + [int]$collectorscount - [int]$currentworkcount) -EntryType information
                    #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing collectors. Completed $lastcompleted ($currentworkcount out of $collectorscount)" -ForegroundColor cyan
                    $currentprogress=  [math]::floor(($currentworkcount / $collectorscount)*100)
                    Write-Progress  -Activity "Completed substep: $lastcompleted" -Status "Working on substep: $currentwork ($currentworkcount out of $collectorscount)" -PercentComplete $currentprogress -Id 2 
                    start-sleep -Seconds $interval
                    Copy-Item $logfilename $templogfile 
                    $str = Get-Content $templogfile | out-string
                    $start = $str.indexOf("Prerequisite success rate") + 1
                    $end = (Get-Content $templogfile | Measure-Object -Character).Characters
                    $length = $end - $start
                    $result = $str.substring($start, $length)
                    $result | out-file  $templogfile
                }  
                   
            $Progresscounter = 5
            $phase = 6
            Remove-Item $templogfile
            Write-Progress  -Activity "Completed collector processing..." -PercentComplete 100 -Id 2 -Completed
        }

        # Analysers phase check = start from analyzer to Reporter 
        If($Progresscounter -eq 5 -and ((Select-String -pattern $PatternArray[7] $logfilename).Matches.Count -ne 0))
        {   
            $phase = 6
            [int]$EventCode = "6000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing analyzers. This may take a while..." -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing analyzers." -ForegroundColor cyan
            $currentphase= [math]::floor(($phase / 8)*100)
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Processing analyzers. This may take a while..." -PercentComplete $currentphase -Id 1
            while(((Select-String -pattern $PatternArray[7] $logfilename).Matches.Count -lt $analyzercount) -and (Select-String -pattern $PatternArray[8] $logfilename).Matches.Count -eq 0)
            {   
               # Update eventcode based on $analyzercount - $currentanalyzercount 
                $currentanalyzercount = (Select-String -pattern $PatternArray[7] $logfilename).Matches.Count
                $lastcompleted= Select-String -Pattern "Message=COMPLETED ANALYZER: " $logfilename
                if ($lastcompleted) {$lastcompleted= ($lastcompleted[-1] -split "Message=COMPLETED ANALYZER: ")[-1]}
                $currentwork= Select-String -Pattern "Message=STARTING ANALYZER:  " $logfilename
                if ($currentwork) { $currentwork= ($currentwork[-1] -split "Message=STARTING ANALYZER: ")[-1]}
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing analyzers.`nCompleted substep: $lastcompleted.Working on substep: $currentwork ($currentanalyzercount out of $analyzercount)." -EventId ($EventCode + [int]$analyzercount -[int]$currentanalyzercount) -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing analyzers. Completed $lastcompleted ($currentanalyzercount out of $analyzercount)" -ForegroundColor cyan
                $currentprogress=  [math]::floor(($currentanalyzercount / $analyzercount)*100)
                Write-Progress  -Activity "Completed substep: $lastcompleted" -Status "Working on substep: $currentwork ($currentanalyzercount out of $analyzercount)" -PercentComplete $currentprogress -Id 3
                start-sleep -Seconds $interval
            }     

            Write-Progress  -Activity "Completed analyzer processing..." -PercentComplete 100 -Id 3 -Completed
            $Progresscounter = 6
            $phase = 7
        }

        # start Reporter to GetIgnoreRecommendationsIds =  Reporter check
        If($Progresscounter -eq 6 -and ((Select-String -pattern $PatternArray[8] $logfilename).Matches.Count -ne 0))
        {
            $phase = 7
             [int]$EventCode = "7000"
            Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Processing Reports" -EventId $EventCode -EntryType information
            #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Processing Reports" -ForegroundColor cyan
            Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Processing reports" -PercentComplete $currentphase -Id 1
            
            while((Select-String -pattern $PatternArray[9] $logfilename).Matches.Count -eq 0)
            {
                start-sleep -Seconds $interval
                Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Waiting to Process Reports" -EventId $EventCode -EntryType information
                #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Waiting to Process Reports" -ForegroundColor cyan
                Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Waiting to Process Reports" -PercentComplete $currentphase -Id 1
            }     
            $Progresscounter = 7
            $phase = 8
        }

        # End of DATA collection
        If($Progresscounter -eq 7 -and ((Select-String -pattern $PatternArray[9] $logfilename).Matches.Count -ne 0))
        {
             $phase = 8
              [int]$EventCode = "8000"

             [int]$NewRecommdFilesCount = 0



             Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Phase : $Phase out of 8 : Creating recommendation files and finishing the assessment" -EventId $EventCode -EntryType information
             #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Create recommendation files and finishing the assessment" -ForegroundColor cyan
             Write-Progress  -Activity "$AssessmentName" -Status "[Phase $($phase) out of 8]: Creating recommendation files and finishing the assessment" -PercentComplete $currentphase -Id 1

             #Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Phase : $Phase out of 8 : Data collection OMSAssessment Process is still running, sleep for $WaitTIme seconds." -ForegroundColor cyan
 
 
             
             #Write final events
             $AssessmentStartDateTime  = (Get-Item -Path  $logfilename).CreationTime |  Get-Date -Format "MM/dd/yyyy hh:mm:ss tt"
             $AssessmentEndDateTime = (Get-Date -Format "MM/dd/yyyy hh:mm:ss tt")
             Write-EventLog -LogName $logname -Source $eventsource -Message “$AssessmentName Data collection status : Completed. `n Start Time: $AssessmentStartDateTime `n End Time: $AssessmentEndDateTime " -EventId 9000 -EntryType information
             Write-host (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") " -- ##  $AssessmentName Data collection status: Completed. Start Time: $AssessmentStartDateTime  End Time: $AssessmentEndDateTime" -ForegroundColor cyan
             start-sleep -Seconds $interval
             $Progresscounter = 8
        }


}
