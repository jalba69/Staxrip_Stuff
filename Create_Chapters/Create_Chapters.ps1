##############################################################################################################
###########################        Create_Chapters.ps1 By Jalba69                  ###########################
###########################      https://github.com/jalba69/Staxrip_Stuff          ###########################
#                                               version 1.0                                                  #
#            A simple Powershell script to create chapters from the preview window in StaxRip                #
#                                                                                                            #
############################################## Settings ######################################################
# Settings for chapters default name, user can of course manually insert chapters names too,                 #
# this parameter is used only as a pre-filled option.                                                        #
#                                                                                                            #
# There is 4 options possible :                                                                              #
#  1 - Use TimeStamps as chapter name                      ex : 00:14:47.762                                 #
#  2 - Use Numbers for Chapter name                        ex : Chapter #07                                  #
#  3 - Use Roman Numbers for Chapters name   (Default)     ex : Chapter VII                                  #
#  4 - Use Numbers + Part for Chapters names               ex : Part #03                                     #
##############################################################################################################
$Selected_Chapter_Names = "3"    # Change the number here according to your tastes                           #
##############################################################################################################

$s = [ShortcutModule]::s
$p = [ShortcutModule]::p

#Set Chapter File Path
$Chapter_File_Path = ($p.TempDir + "Custom_Chapters.txt")

#Import Time from preview window
$Chapter_Time_Code = [System.TimeSpan]::FromSeconds($s.LastPosition / $p.SourceScript.GetFramerate()).ToString()
if ($Chapter_Time_Code.Length -gt 12)
{
    $Chapter_Time_Code = $Chapter_Time_Code.Substring(0, 12)
} 
if ($Chapter_Time_Code -eq "00:00:00")
{ 
    $Chapter_Time_Code = "00:00:00.000"
}

# Check if Chapter file already exit
if ([System.IO.File]::Exists($Chapter_File_Path)) {
#If file exist Get last Chapter Number from the last line
$Last_Chapter_Number = (Get-Content -Path $Chapter_File_Path -last 1).Substring(7,2)
#and then Increment chapter number with +1 for next chapter 
$Next_Chapter_Number = ([int]$Last_Chapter_Number + 1).ToString("00")
#If file does not Exist set first chapter number as "01"
} else { 
$Next_Chapter_Number = "01"
}

#Convert default decimal Chapter Numbers into Roman numbers.
#This code function part is borrowed from https://mow001.blogspot.com/
function ConvertToRoman ($num ) {  
    $M = [math]::truncate($num / 1000) 
    $num -= $M * 1000 
    $D = [math]::truncate($num / 500) 
    $num -=  $D * 500 
    $C = [math]::truncate($num / 100) 
    $num -=  $C * 100 
    $L = [math]::truncate($num / 50) 
    $num -=  $L * 50 
    $X = [math]::truncate($num / 10) 
    $num -=  $x * 10 
    $V = [math]::truncate($num / 5) 
    $num -=  $V * 5
    $Roman = "M" * $M
    $Roman += "D" * $D
    $Roman += "C" * $C
    $Roman += "L" * $L
    $Roman += "X" * $X
    $Roman += "V" * $V
    $Roman += "I" * $num
    $Roman = $Roman.replace('DCCCC','CM') # 900
    $Roman = $Roman.replace('CCCC','CD') # 400
    $Roman = $Roman.replace('LXXXX','XC') # 90
    $Roman = $Roman.replace('XXXX','XL') # 40
    $Roman = $Roman.replace('VIIII','IX') # 9
    $Roman = $Roman.replace('IIII','IV') # 4
    Return $Roman
}

#Check setting value to see what to use as pre-filled chapter name.
if ($Selected_Chapter_Names -eq "1") {
$Next_Chapter_Name = "$Chapter_Time_Code" }
elseif ($Selected_Chapter_Names -eq "2") {
$Next_Chapter_Name = "Chapter #$Next_Chapter_Number" }
elseIf ($Selected_Chapter_Names -eq "3") {
$Next_Chapter_Name =  "Chapter $(ConvertToRoman $Next_Chapter_Number)" } 
elseIf ($Selected_Chapter_Names -eq "4") {
$Next_Chapter_Name =  "Part #$Next_Chapter_Number" } 
else { $Next_Chapter_Name = "Chapter $(ConvertToRoman $Next_Chapter_Number)" }

#Set Chapter Name Text Input Box
$Set_Chapter_Name = [InputBox]::Show("Time : $Chapter_Time_Code `nEnter the Chapter Name : ", "Select a Chapter Name", "$Next_Chapter_Name")
if ([string]::IsNullOrEmpty($Set_Chapter_Name)) { exit }

#Output to chapter .txt file 
$Chapter_Output = "CHAPTER$($Next_Chapter_Number)=$Chapter_Time_Code
CHAPTER$($Next_Chapter_Number)NAME=$Set_Chapter_Name"| Add-Content -Encoding "UTF8" $Chapter_File_Path

Exit

#TODO Sorting by Timestamps, send chapters numbers to array then sort by number of items and sort by time before print into txt file? But during import it is auto sorted by mp4box and mkv toolnix tools apparently .
