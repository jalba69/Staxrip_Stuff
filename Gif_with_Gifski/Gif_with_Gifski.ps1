##############################################################################################################
###########################        Gif_with_Gifski.ps1 By Jalba69                  ###########################
###########################      https://github.com/jalba69/Staxrip_Stuff          ###########################   
#                                               version 1.0                                                  #
# A Powershell script to use inside StaxRip to create high quality gif's with Gifski. Only tested while using# 
# avisynth inside Staxrip, really not sure if it will work with VapourSynth, not installed on my system...   #
#                                                                                                            #
############################################## Settings ######################################################
# Set the Path to where Gifski.exe is located on your computer :
$Gifski_path = "Z:\My_Tools\gifski.exe"
#
# Set the Path where you want to have the gif created, this is if you always want it created in a same specific location.
$Gif_Output_Folder = " " 
# Replace $Gif_Output_Folder = " " by something like $Gif_Output_Folder = "Z:\My_Gif_Folder" 
# If this Output path for the gif is not set or incorrect the Gif will be created inside the Temp folder used by StaRip.
#
# Option to open the Gif destination folder once it is created, Options are True or False.
$Open_Folder_After_Creation = "True"
#
# Option to display Infos and the Estimated Size of the output Gif, the estimation is highly inaccurate to say the least :p
# Needs to be worked on but it's not easy, started to work on Input analyze using avisynth scripts to detect how much movement there is
# + the changes of colors/luma across the Input and get a sort of complexity index used as multiplicator for the size estimation,
# but after countless hours spent on this I gave up, might get back on this when I'll have many hours to kill... For now I let it go like this...
# For reference : https://github.com/ImageOptim/gifski/issues/28
#
# Options are "True or "False" default set to "True"
$Show_Estimated_Size_and_Infos = "True"
#
##############################################################################################################
######################################### From here all is automated #########################################
##############################################################################################################

$activeProject = [ShortcutModule]::p  #Project
$gmodules = [ShortcutModule]::g       #GlobalClass
$smodules = [ShortcutModule]::s       #ApplicationSettings

#OutputFileName
$Timestamp = $((get-date).ToString("yyyy_MM_dd-hh-mm-ss"))
$Original_filename = ([MediaInfo]::Getgeneral($activeProject.FirstOriginalSourceFile, "FileName")) 
$Shorter_name = ($Original_filename.substring(0, [System.Math]::Min(15, $Original_filename.Length)))
$File_output_name = "Anim_$($Shorter_name)_$($Timestamp).gif"
#TODO one of those days : Add a Check for weird names with []() or other symbols in input file name and create alias name without the weird symbols.

#Auto Set Paths 
$Project_Temp_Folder = $activeProject.TempDir
$StaxRip_script_path = $activeProject.Script.Path
$FFmpeg_path = [Package]::FFmpeg.GetDir() + "ffmpeg.exe" 

#Get Video Output Width & Height
$Target_Width = $activeProject.TargetWidth
$Target_Height = $activeProject.TargetHeight

#Errors Checks
  #Function to display incorrect settings popup
function Check_settings {
$Checkpopup = new-object -comobject wscript.shell
$Checkpopup = $Checkpopup.popup("$Check_Error_Message",0,"Problem in the Settings",4096)
exit
}
  #Function to Check if the Input is valid, create popup if not OK
Function Check_Input {
$error_popup = new-object -comobject wscript.shell
$error_Input = $error_popup.popup("Not a valid value, set it again please",0,"User Input is Incorrect",4096)
}
  #Check if path set for Gifski exist
if (-not ([System.IO.File]::Exists($Gifski_path)) ) {
$Check_Error_Message = " Path Indicated for Gifski.exe does not exist or is incorrect
`nPlease set the path correctly in the Settings"
Check_settings
}
  #Check if option to open folder after gif created is correctly set or not
if (-not ($Open_Folder_After_Creation -eq "True" -Or $Open_Folder_After_Creation -eq "False") ) {
$Check_Error_Message = "Setting incorrect for opening or not the output folder after the gif creation
`nOptions are True or False
`nPlease check the setting and add a correct option"
Check_settings
}
 #Check if option to to display estimated size is correctly set or not
if (-not ($Show_Estimated_Size_and_Infos -eq "True" -Or $Show_Estimated_Size_and_Infos -eq "False") ) {
$Check_Error_Message = "Setting incorrect for displaying or not the Estimated Size of the gif
`nOptions are True or False
`nPlease check the setting and add a correct option"
Check_settings
}
  #Check if the output path selected by the user for gif output exists, if not use Temp folder instead for output.
If ( -Not (Test-Path -Path $Gif_Output_Folder) ) {
$Gif_Output_Folder = $Project_Temp_Folder
}

Function Select_FPS {
$FPS_Input = [InputBox]::Show("Select FPS for the Gif, 
Default is Staxrip Target Framerate", "Select FPS",[math]::Round($activeProject.TargetFrameRate))  #[math]::Floor
if ([string]::IsNullOrEmpty($FPS_Input)) {exit}
   #Check if valid Input.
if ([int]$FPS_Input -lt 1)
{
Check_Input
Select_FPS
}
   #Set FPS Full Parameter
else {$FPS="--fps $FPS_Input"}
return $FPS
}

#Quality Selector Function
Function Select_Quality {
$Quality_Input = [InputBox]::Show("Select Quality of the Gif default 100(best), Settings: 
1-100 (or Fast but -10% quality and bigger gif)","Select Quality","100")
if ([string]::IsNullOrEmpty($Quality_Input)) {exit}
   #Check if valid Input, needs to be in 1-100 range or be Fast
if ($Quality_Input -notmatch "^[1-9][0-9]?$|^100$|fast")
{
Check_Input
Select_Quality
}
   #Set Quality Full Parameter
else {$Quality= "--quality $Quality_Input"}
if ($Quality_Input -eq "fast") {$Quality="--fast"}
return $Quality,$Quality_Input
}

#Resize Y/N Function
Function Resize_Y_N {
$Resize =[System.Windows.Forms.MessageBox]::Show("Set custom sizes for the output Gif ? 
`n`nReducing dimensions only, no upscale `n`nDownsizing made by Gifski","Reduce Gif dimensions ?",4,32,"button2")
switch ($Resize){ "YES" {
    #Width User Input sub function 
    Function User_Width_Input {
$Width_Input = [InputBox]::Show("Select Width of the gif, NO upscale done, if value 
set is higher than video input res. there is no resize", "Select Width", $Target_Width)
if ([string]::IsNullOrEmpty($Width_Input)) {exit}	
#Check if valid Input, needs to be in 4 to input width range, no upscale allowed.
if ($Width_Input -notin 1..[int]$Target_Width)
{
$error_popup = new-object -comobject wscript.shell
$error_Input = $error_popup.popup("$Width_Input is not a valid value, 
`nSet it again please 
`nValid settings are from 4 to $Target_Width",0,"User Input is Incorrect",4096)
User_Width_Input
   }
return $Width_Input   
}										 
    #Set Width Full Parameter
$Call_Width_Input = User_Width_Input
$Gif_Width="--width $Call_Width_Input"
    #Height User Input sub function
    Function User_Height_Input {
$Height_Input = [InputBox]::Show("Select Height for the Gif.  Set 0 to let 
the Width parameter define it ( 0 = keeping A/R )", "Select Height", $Target_Height)
if ([string]::IsNullOrEmpty($Height_Input)) {exit}
#Check if valid Input, needs to be in 0 to input height range, no upscale allowed.
if ($Height_Input -notin 0..[int]$Target_Height)
{
$error_popup = new-object -comobject wscript.shell
$error_Input = $error_popup.popup("$Height_Input is not a valid value, 
`nSet it again please 
`nValid settings are from 0 to $Target_Height
`n      ( 0 = keep Aspect/Ratio )",0,"User Input is Incorrect",4096)
User_Height_Input
   }
Return $Height_Input
}
$Call_Height_Input = User_Height_Input  								  
     #Set Height Full Parameter
$Gif_Height="--height $Call_Height_Input"
} 
"No" {} 
}
   #Set Width & Height Full Parameter
	# Rounding done by Gifski for Height when not set with only the width provided for resize is not accurate as i like it to be so it's a little workaround for now
    # ex: 1280x720 input, args --width 600 returns a gif with height 337 when it should be 338, --width 300 will do height 168 instead of 169.
if ([int]$Call_Height_Input -eq "0") {
$Aspect_Ratio = ([math]::Round(([int]$Call_Width_Input / ([int]$Target_Width / [int]$Target_Height) ))) 
$Gif_Height="--height $Aspect_Ratio"}
#if ([int]$Call_Height_Input -eq "0") {$Gif_Height=""}	# Do not send calculated Height parameter and let Gifski decide itself based on his A/R calculations
$Resize_values = "$Gif_Width $Gif_Height"
   #If set resize values for W&H are the same as input don't pass resize args to Gifski.
if ([int]$Call_Width_Input -eq [int]$Target_Width -And [int]$Call_Height_Input -eq [int]$Target_Height) {$Resize_values=""}
return $Resize_values,$Call_Width_Input,$Call_Height_Input
}

#Estimated Size change Function
Function Estimated_Size_Change_Y_N {
   #Get the total number of Frames   
if ([string]::IsNullOrEmpty($activeProject.Ranges[0].Start)) {$framecount= $activeProject.CutFrameCount}
else {$framecount  = $activeProject.Ranges[0].End - $activeProject.Ranges[0].Start}
  #Check if resize options passing to Gifski are set else use video native size.
    #Define Width
if ([string]::IsNullOrWhiteSpace($Resize_Width_Input)) 
{$Width = $Target_Width} 
else {$Width="$Resize_Width_Input"}
   #Define Height
    #Auto set height size based on width if Input width set by user is valid but height input is set to 0 to keep A/R.	
if ([int]$Resize_Height_Input -eq "0") {
$Height = ([math]::Round(([int]$Width / ([int]$Target_Width / [int]$Target_Height) ))) 
}
elseif ([string]::IsNullOrWhiteSpace($Resize_Height_Input)) {
$Height = $Target_Height
}
else {$Height="$Resize_Height_Input"}
   #Estimate Size in bytes. bytes= width * height * frames / 3 * (quality + 1.5) / 2.5
if ( $Quality_setting_Input -eq "fast" )
{$Estimated_Size = ((([int]$Width * [int]$Height * [int]$framecount) / 3) * 1.10)} # +10%
else 
   #{$Estimated_Size = (((($Width * $Height * $framecount) / 3) * (($Quality_setting_Input / 100 ) + 1.5)) / 2.5)}
{$Estimated_Size = (((([int]$Width * [int]$Height * [int]$framecount) / 3) * (([int]$Quality_setting_Input / 100 ) + 1.5)) / 2.5)}
   # Check if size is < or > to 1MB and scale Unit displayed
if ($Estimated_Size -ge 1000000 ) {
$Estimated_Size = [math]::Round([int]$Estimated_Size /1MB, 2 )
$Display_Unit = "MB"
}
else {$Estimated_Size = [math]::Round([int]$Estimated_Size /1KB ) 
$Display_Unit = "KB"
}
   #Display popup infos and allow settings changes
$Estimated_Y_N =[System.Windows.Forms.MessageBox]::Show("Estimated size of the gif is : $Estimated_Size $Display_Unit `n`n        $Framecount Frames`n        $Width x $Height px `n        $Fps_setting`n        $Quality_setting_Main
`nClick YES to Continue `n`nClick NO to Change Settings","Gif Estimated Size and Infos : ",4,0,"button1")
switch ($Estimated_Y_N){ "YES" {} 
"No" {
   # Use $Script: so the variables returned by functions are updated, else it keeps old variables set previously.
$script:Fps_setting = Select_FPS
$script:quality_setting = Select_Quality
$script:Quality_setting_Main = $quality_setting[0]
$script:Quality_setting_Input = $quality_setting[1]
$script:Resize_setting = Resize_Y_N
$script:Resize_setting_Main = $Resize_setting[0]
$script:Resize_Width_Input = $Resize_setting[1]
$script:Resize_Height_Input = $Resize_setting[2]
$script:display_estimated_size_popup = Estimated_Size_Change_Y_N }
}
}

#Call the parameters
$Fps_setting = Select_FPS
$Quality_setting = Select_Quality
$Quality_setting_Main = $Quality_setting[0]
$Quality_setting_Input = $Quality_setting[1]
$Resize_setting = Resize_Y_N
$Resize_setting_Main = $Resize_setting[0]
$Resize_Width_Input = $Resize_setting[1]
$Resize_Height_Input = $Resize_setting[2]

#Call Estimated_Size function
if ($Show_Estimated_Size_and_Infos -eq "True") {
$Estimated_Size_popup = Estimated_Size_Change_Y_N
}

# Gifski and FFMpeg icons hardcoded in base64, the icons are used in the taskbar balloon notifications during gif creation.
# Code part for the icons in base64 borrowed from here https://blog.netnerds.net/2015/10/use-base64-for-notifyicon-in-powershell/
#FFmpeg Icon taken from here: https://ffmpeg.org/
Add-Type -AssemblyName PresentationFramework
$FFmpeg_icon_base64 = "AAABAAEAICAgAAAAAACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAAAA
AAAAAAAAAAAAAAAAAAD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AAEi
ABoBHwBEASAAbwIgAJkBLADEBWUA+QNDAP////8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AAicAGgINAg7///8A////AAIk
AFECJgD0BlkA/wVcAP8GXAD/Bl0A/wVcAP8GcwD/CIEA/wh+AP8IfwD/CH8A/wd9
AP8IhAD/CkgD/////wD///8AAiUAQwIjAG4CIwCZAiMAxAIkAO4DUgD/BmAA/wVd
AP8FXgD/Bl4A/wZsAP8GhQD/EmUI/xYcCc7///8A////AAqEAJwHfQD/CHwA/wh+
AP8IfQD/CH4A/wh5AP8HdgD/B3YA/wd2AP8IdgD/B3QA/wh8AP8OQQP/////AP//
/wAKdAFjB4QA/wd9AP8IfwD/CH8A/wh9AP8IfQD/CH0A/wh9AP8IfQD/CHkA/wd0
AP8FeQD/LnIO/y4xDf7///8A////AAl7AJsGdgD/B3UA/wd2AP8HdgD/B3cA/wh4
AP8HeAD/B3gA/wh4AP8FdgD/BX4A/w1DA/////8A////AP///wAKbgGSB3kA/wd0
AP8HdgD/B3YA/wd2AP8HdgD/CHYA/wh2AP8IdwD/CHcA/wd2AP8EdwD/LnEM/y0z
Df7///8A////AAl8AIQGdwD/CHYA/wd3AP8IdwD/B3gA/wh3AP8HdwD/BngA/wt0
AP8TegH/EEEE/////wD///8A////AP///wAJcQC9B3kA/wd2AP8IeAD/B3gA/wh3
AP8GeAD/BncA/wd4AP8GeAD/CHYA/wd3AP8DdwD/LHEM/y4zDf////8A////AAp8
AHIGdwD/CHYA/wh3AP8GdwD/CncA/09nCP9xXA22cWANmX5lDn1MQwpi////AP//
/wD///8A////AP///wAJewDhB3cA/wd3AP8GdwD/DnUB/yxhDf8pWQ3/J1gIrg51
AdAGeQD/CHYA/wd3AP8DdwD/LXMN/y0zDf////8A////AAp7AGIGdwD/CHYA/wh3
AP8EdgD/FnoB/ys9BP////8A////AP///wD///8A////AP///wD///8A////AP//
/wAHeQD0B3cA/wh2AP8EeAD/F3AF/z9gGP8+QRH8////AAd3ALUHegD/CHYA/wd3
AP8DdwD/LnEN/y4zDf////8A////AAp7AF8HeAD/B3cA/wh2AP8BegD/HGgE/wcN
Afj///8A////AP///wD///8A////AP///wARTQb8EyAJzRdZBzUFdwD7BncA/wd2
AP8DeQD/E3AE/zxjGf80Mw/6////AAh3AbsIegD/B3YA/wd2AP8DdwD/K3IM/ywz
Df////8A////AAl4AFEHdwD/B3cA/wV4AP8eZgX/DBMD+P///wD///8A////AP//
/wD///8A////ABJ2Bf8uYRf/P1cZ/yhlCSgEeQL/CncB/wl3AP8EeQD/FW4E/0Fl
Gf83NBD1////AAh0AdAIeAD/CHYA/wd2AP8DdwD/LHIM/ywwDf////8ACm8CJgd5
AP8HdwD/BXkA/x5mBP8LEQL4////AP///wD///8A////AP///wD///8AEX8K/xt0
EP8wXBj7R1oY/zFpDwwThRH/Fn8N/xJ7Cf8JewL/GGwH/0FlGv83Mg/v////AAh/
ANwIdgD/CHYA/wd2AP8EdwD/K28N/y8+D/8KbQEmBnkA/wh2AP8FeQD/HmcF/wsS
A/j///8A////AP///wD///8A////AP///wAlhhz/JYog/zF7Hv8xXBn/TlUT/0BZ
EgIhiCH/I4Ua/x2CFv8UgAz/H24M/0FiGv84QQ7o////AAZ8AOUHdgD/CHYA/wd3
AP8DeAD/K2wM/xtsB/8DeQD/CHYA/wV5AP8eZwX/CxID+P///wD///8A////AP//
/wD///8A////ADOPLP84kDH/O5Y1/z9/Kv81XBn/OEIQ/yR2GwQzky3/LIol/yaG
Hv8chRT/JG8R/0VjGf9IKQXY////AAh/AOwHdQD/CHYA/wd3AP8HdgD/CnYA/wd4
AP8IdgD/BXkA/x5nBf8LEgP4////AP///wD///8A////AP///wD///8AQ5g7/0ma
Q/9Km0X/TqFJ/0l+Mf8yWhb/QGMU/zyELRY8lzj/NI8t/yuKJf8iiBr/JnEU/0pV
Gf8uEwTI////AAp/AfIGdQD/CHcA/wd4AP8HeAD/CHcA/wd3AP8FeQD/HmcF/wsS
A/j///8A////AP///wD///8A////AP///wBSoEv/WaNU/1ylVv9dplj/YKpb/0x8
Nf8yUxT/Ql8b/kOJOTdDmz//OpIy/y+NKf8kiBv/LHMW/zpYGP8SFQW6////AAt+
APYGdQD/CHcA/wh3AP8HdwD/CHYA/wV5AP8eZwX/CxID+P///wD///8A////AP//
/wD///8A////AGCoWv9prWX/bK5o/26vaf9ur2n/b7Bo/0x5NP8yVBL/SGEd+EmQ
QFpHnkX/PZI1/zCNKv8jhxv/MHAV/z1YGP8UFAWd////AAp/APkGdQD/CHcA/wd4
AP8IdwD/BXkA/x5nBf8LEgP4////AP///wD///8A////AP///wD///8Ab7Bp/3q2
dv99t3n/grx//363ef98uHn/e7Vy/0p0Mf8wUxH/T2Ue61OVQ4xLokf/PJI0/y+N
Kf8ghRj/LW4U/0BZGf8UEwSI////AAqBAPsHdQD/CHcA/wd2AP8FeQD/HmcF/wsS
A/j///8A////AP///wD///8A////AP///wB+uHn/i7+I/42/if+Arnj/k8WQ/4y/
iP+Iv4b/grZ4/0ZvLf85VhH/Q0wVzkOIQ7VMnkT/OZAx/yqLJP8bghL/LGoS/0FZ
Gf8VFQR0////AAmAAP0HdQD/CHcA/wV4AP8eZwX/CxID+P///wD///8A////AP//
/wD///8A////AIy/h/+Zxpf/pc6h/01xOv9qmGb/p9Ol/5TCj/+Pw47/grN2/0Fq
Jv8vSxH/LVsWpEWfRN5Elz3/M44s/yOHHP8UfQv/KmcQ/0NZGf8UEwRX////AAqB
Af4HdQD/BXkA/x1mBP8KEQP4////AP///wD///8A////AP///wD///8AmcaV/6nO
pv+32bP/Sm05/w88CP+UuIz7rdWr/5nElP+TxpL/faxw/z5lIv81WhH/QXMmcUaY
QvI7lDT/K4kj/xmCEv8MeAL/K2YQ/0RZGf8WFARG////AAqAAP8EdwD/HmcF/woS
Avj///8A////AP///wD///8A////AP///wCkzKD/t9a1/8bhxP91kGD/H0UD/0pp
K/+lx5/3rdOr/5jElP+RxY7/daZm/zZdHP88VxT/RHEoQzuUOfoxjin/IIQY/w57
Bv8KdQD/LGYS/0VZGf8WEwQ1////AAiCAP8cZAT/CxEC+P///wD///8A////AP//
/wD///8A////ALXbtf/H4Mb/zuTO/9Tkzf9gfUT/I00H/1Z1Ov+u0Kv+ptCl/5LC
j/+KwYf/apxY/zJbGP8/Vhb/RXAlHTCSLf4lhxz/E3sK/wV3AP8LdgD/LWUT/0dZ
Gf8WEgQm////ABVwBf8IEQLy////AP///wD///8A////AP///wD///8Ab4xYYs/h
y//b69v/6fXr/9fi0P9NbjL/JE4I/2GBS/6r0qv/nMiY/4m8hP99u3r/XpBJ/zFZ
F/9EWBf/PWYdCx6IH/8Ufw3/CHYA/wV4AP8NdQH/LmQU/0lXGP8ZGQQa////AP//
/wD///8A////AP///wD///8AeKNx/3qjdv+KnnH5zdrB/+j06v/y9vH/+f37/8jV
vf8+YyL/KFAM/2iJUvOizqH/jL+J/3u1dv9usmr/UYU7/zZaFv9sRg3/U2UTpBV/
Dv8IeAD/CHYA/wV4AP8OdQH/MGMU/0xYHP8cDwMP////AP///wD///8A////AP//
/wCbxZj/xOTD/87p0P/W6db/5e/l//T59P/t9O3/6fbr/6y+nP81Wxj/L1MQ/22Q
VtKSxpD/e7V2/2qtZv9bplb/UYs3/1CEJv9Kdhr/HHoN/wZ5AP8HdgD/CHYA/wV4
AP8QdAH/MGEW/1VaEv8iDQAG////AP///wD///8A////AI+4iv+u0az/u9a4/8vg
yv/Z6Nj/4ezg/+Ds3//T5NL/0OfR/4iidP8sUhD/NFgW/2yYW7F+u33/aKti/1ii
Uv9GnUP/MpQy/yCLIP8Tfwz/B3cA/wd3AP8HeAD/CHYA/wV4AP8ScQL/MmMY/1Y+
EP8TAAAC////AP///wD///8AlMeR/7fgtP/C5L//z+zN/9jw1v/b8Nr/2/DZ/9Ps
0f/G5MT/weS//3acY/YpUhD/OWAc/2igWr9nrWP/U55N/0OVPf80jCz/JIMb/xJ7
Cf8GdQD/B3YA/wd3AP8HeAD/CHYA/wR4AP8ScQL/N2UY/zA+EP////8A////AP//
/wD///8A////AP///wD///8A////AKm7pxqXq5Q8layUb42ni5mEooLEgaWA7l+K
S8ErPQZm////AFqlVONUqE7/Qp48/zGUKv8gihj/DoEG/wd8AP8IfgD/CHkA/wd2
AP8HdgD/CHUA/wR3AP8UbgT/OmMZ/y88EP////8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8AInAdIhVjDk0IXgGABVwAogZdANUHcgD3CIEA/wh+AP8IfgD/CX4A/wWA
AP8PdgT/Om0b2A0TBG////8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wAOTgUd////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP//
/wD///8A////AP///wD///8A////AP///wD///8AAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAA="
$FFmpeg_bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$FFmpeg_bitmap.BeginInit()
$FFmpeg_bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($FFmpeg_icon_base64)
$FFmpeg_bitmap.EndInit()
$FFmpeg_bitmap.Freeze()
$FFmpeg_Picture = [System.Drawing.bitmap][System.Drawing.Image]::FromStream($FFmpeg_bitmap.StreamSource)
$FFmpeg_Icon = [System.Drawing.Icon]::FromHandle($FFmpeg_Picture.GetHicon())

#Gifski Icon taken from here : https://gif.ski/
$Gifski_icon_base64 = "AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAABMcEcATHBHAExwRwCaLrhMkzSTqpo5mduZOJbzkTpu/ps/
cP+bP3D/nEJP/6tFTf+rREz/kjpC/xEHCP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD8AAAA8wAAANsAAACqAAAATExwRwBMcEcATHBHAExw
RwCuLucLlSu2ppwtuv+cLbr/kzWV/5s5mf+bOZn/kTpu/ps/cP+dQHD/nEJP/6tF
Tf+rRU3/kjpC/xEHCP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAApgAAAAtMcEcATHBHAJsV3aacGtj/miy5/5wt
uv+cLbr/kzWV/5s5mf+bOZn/kTpu/p1AcP+dQHD/nEJP/6tETP+rREz/kjpC/xEH
CP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAApkxwRwBdK+dMmRXb/5wV3v+cGtj/miy5/58uvv+fL7r/kzWV/5s5
mf+jRJ7/wIOl/8qbtv/Ag6L/okZW/6tFTf+8d33/wZGV/1tXWP8AAAD/AAAA/19f
X/9wcHD/X19f/yoqKv9fX1//X19f/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAATDQq
56pVJeP/mRXb/5wV3v+cGtj/miy5/58uvv+fL7r/qFuo//bu9P//////////////
///06fH/rlFd/+C5vP//////6NDS/xEHCP9OTk7///////////9fX1//cHBw////
////////AAAA/wAAAP8AAAD/AAAA/wAAAP8AAACqPDHr2zUr6P9VJeP/mRXb/5wV
3v+cGtj/miy5/58uvv/bseb////////////06fH//v7+///////Yr8T/27e9////
///o0NL/nEJP/+Pm5///////srKy/wAAAP9wcHD///////////8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAANsxUuTzNSvo/zUr6P9VJeP/mRXb/5wV3v+cGtj/nC26/58u
vv/Fg9X/u3+8/6dFo//v4O///////+LH1v/buMv//////+jQ0v/gur3//////+zr
6/8aGhr/AAAA/3BwcP///////////wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA8zJ0
7vsyU+T/NSvo/zUr6P9VJeP/mRXb/58W4P+cGtj/nC26/7BRyv/lxe3//Pr9////
////////ypu2/9u4y///////+fP0////////////uYCF/xEHCP8AAAD/cHBw////
////////AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD7M3bu/zN27v8yU+T/NSvo/zUr
6P9VJeP/mRXb/58W4P+vQd7//Pr9/////////////Pr9/8+cz/+jRJ7/2bXJ////
///27vT//v7+///////RlZr/kjpC/xEHCP9wcHD///////////8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8wjOb/M3bu/zN27v8yU+T/NSvo/zgt6f9VJeP/nBXe/8h8
7P///////Pr9/8R82P+5Zs7/nT6e/6FAov/ct9v//////+fQ3f/Ztcn///////r5
+f+5X2b/kjpC/3pzdP///////////wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/y6z
8/8wjOb/M3bu/zN27v82V+b/OC3p/zgt6f9VJeP/v2no////////////5cXt//n4
/v/05Pn/smqz/9y32///////59Dd/6hPgP/27vT//////+zV1/+tRU7/wpGV////
////////AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/LrPz/y6z8/8wjOb/M3bu/zN2
7v82V+b/OC3p/zgt6f9fMOX/8Nz3//////////////////Dc9/+tRsf/2rfb////
///oz+j/nEN5/8CDpf///////////9GVmv/RlZr///////////8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8edJ//LrPz/y6z8/8wjOb/Nnnv/zZ57/82V+b/OC3p/zgt
6f9fMOX/yHzs/9eY8P/Ecej/qDjF/6Y0wv/ds+f//////+jP6P+lQaL/nEN5/7tz
mv+7c5r/uWhy/7ldZf/Hf4X/vHd9/xIHCP8AAAD/AAAA/wAAAP8AAAD/AAAA/wEC
Av8edJ//LrPz/y6z8/8wjOb/Nnnv/zZ57/82V+b/Oi/q/zgt6f9bKeb/oBfe/58W
4P+lHdz/ny6+/92z6f//////6M/o/6VBov+lQaL/nEN5/6ZHe/+mR3v/sF5t/+zV
1//ftrn/lTxE/xIHCP8AAAD/AAAA/wAAAP8AAAD/AAAA/wECAv8gd5//MLb0/zC2
9P8wjOb/Nnnv/zZ57/82V+b/Oi/q/zov6v9bKeb/oBfe/6YZ4v+lHdz/27Hm////
///pzfD/nT6e/6RCpf+lQaL/nEN5/6ZHe//Yr8T///////////+5aHL/ljpC/xIH
CP8AAAD/AAAA/wAAAP8AAAD/AAAA/wECAv8gd5//MLb0/zC29P8wjOb/Nnnv/zZ5
7/82V+b/Oi/q/zov6v9bKeb/oBfe/6YZ4v/dqfP//////+nN8P+mNML/nT6e/6ZD
p/+lQaL/nEN5/8CDpf/+/v7/8+fq/65RXf+vRE3/ljpC/xIHCP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wECAv8gd5//MLb0/2PK9v+62fb/5e79/+Xu/f/CzPf/ioTy/zov
6v9bKeb/oBfe/92p8///////6c3w/6g4xf/Lidr/2rfb/8+cz/+nRaP/nEN5/7Bc
i/+tToL/pEJT/69ETf+vRE3/ljpC/xIHCP8AAAD/AAAA/wAAAP8AAAD/AAAA/wME
BP+SvND//P3+////////////////////////////0836/0pA6/9bKeb/3anz////
///pyPf/pjTC/+G67P//////5Mnk/6ZDp/+nRaP/n0Z9/6lKfv+pSn7/pEJT/69E
Tf+vRE3/ljpC/xIHCP8AAAD/AAAA/wAAAP8AAAD/cHBw/////////////v7+/+P1
/f/O5fn/8vb+////////////trL3/zov6v/Cr/b//////+nI9/+lHdz/4Lrq////
///lxe3/oUCi/6ZDp/+nRaP/n0Z9/6lKfv+pSn7/pEJT/69ETf+vRE3/ljpC/wAA
AP8AAAD/AAAA/xoaGv/09PT//////97e3v9QlbP/MLb0/zC29P84lOf/ydz6////
////////Yljv/7ay9///////6cj3/6YZ4v/hsvT//////+XF7f+sOMf/oUCi/6tF
qf+rRaf/n0Z9/6tMgP+rTID/pEJT/69ETf+vRE3/AAAA/wAAAP8AAAD/Z2dn////
////////Pj4+/wECAv8gd5//hdT4/4XU+P+cyfP///////////+JnfD/trL3////
///Tzfr/phni/+Gy9P//////5cXt/6w4x/+sOMf/oUCi/6tFqf+rRaf/n0Z9/6tM
gP+rTID/pEJT/69ETf8AAAD/AAAA/wAAAP+Wlpb//////+zr6/8AAAD/AAAA/wEC
Av/l7/P//////////////////////6vJ+f+yv/b//////9PN+v9fK+f/4bL0////
///nwPX/pjTC/6w4x/+sOMf/pEKl/6tFqf+rRaf/o0iB/61Ogv+rTID/pUJU/wAA
AP8AAAD/AAAA/6qqqv//////1tbW/wAAAP8AAAD/AAAA/97e3v/8/f7//P3+//z9
/v/8/f7/tNL4/7TS+P//////4uj8/6Kc9f/k3vz///////Tk+f/XmPD/rUbH/645
y/+vPMj/pEKl/61Hq/+tR6v/o0iB/61Ogv+tToL/AAAA/wAAAP8AAAD/g4OD////
///6+fn/CQkJ/wAAAP8AAAD/AAAA/wECAv8kfKD/Nbz1/zW89f84lOf/tNL4////
//////////////////////////////////+6R+f/pjTC/645y/+vPMj/pEKl/61H
q/+tR6v/o0iB/61Ogv8AAAD8AAAA/wAAAP9OTk7///////////+Dg4P/AAAA/wAA
AP8AAAD/AAAA/4mNj/+PtcT/Nbz1/zW89f+00vj/+fj+//n4/v/5+P7//P3+////
///8/f7/+fj+/7pH5/+uIeD/qDjF/645y/+vPMj/pkOn/61Hq/+tR6v/o0iB/wAA
APMAAAD/AAAA/wECAv/LzMz///////////+ampr/UFBQ/3t7e//LzMz/4+bn/8fQ
1f+Ls8P/Nbz1/0LA9P97ue//Sozx/z6G8v+yv/b//////+Te/P9jL+r/phni/6sb
4/+uIeD/qDjF/645y/+vPMj/pkOn/61Hq/+vSqvzAAAA2wAAAP8AAAD/AAAA/zEx
Mf/09PT////////////////////////////6+fn/4+bn/2lqa/8kfKD/x+z8////
///O5fn/Poby/4u29/////////////n4/v96Tev/qxvj/64b5/+uIeD/qDjF/7E7
zv+vPMj/pkOn/69Jr9sAAACqAAAA/wAAAP8AAAD/AAAA/yYmJv/LzMz/////////
//////////////r5+f9pamv/AAAA/wECAv/a6e///////+P1/f85mOn/QYnz/+Lo
/P///////////2JY7/9jL+r/qxvj/64b5/+wI+L/rDjH/7E7zv+vPMj/qEWoqgAA
AEwAAAD/AAAA/wAAAP8AAAD/AAAA/wMEBP9bV1j/qqqq/6qqqv9wcHD/AwQE/wAA
AP8AAAD/AAAA/zs9Pf+y0d3/Y8r2/zi/9f85mOn/QYnz/4u29/+nt/T/Vkzu/0M3
7v9jL+r/qxvj/64b5/+wI+L/rDjH/7E7zv+1P8xMTHBHAAAAAKYAAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wEC
Av8kfKD/OL/1/zi/9f85mOn/Poby/z6G8v8/Y+n/Qzfu/0M37v9jL+r/qxvj/64b
5/+wI+L/rTrHpkxwRwBMcEcAAAAACwAAAKYAAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wECAv8kfKD/OcD2/znA
9v85mOn/Poby/0GJ8/8/Y+n/Qzfu/0M37v9jL+r/qxvj/7Id56auLucLTHBHAExw
RwBMcEcATHBHAAAAAEwAAACqAAAA2wAAAPMAAAD7AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wECAv8kfKD/OcD2/znA9v87m+n/QYnz/0GJ
8/9AZerzPDHr20U57qpdK+dMTHBHAExwRwBMcEcA4AAAB4AAAAGAAAABAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AACAAAABgAAAAeAAAAc="
$Gifski_bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$Gifski_bitmap.BeginInit()
$Gifski_bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($Gifski_icon_base64)
$Gifski_bitmap.EndInit()
$Gifski_bitmap.Freeze()
$Gifski_Picture = [System.Drawing.bitmap][System.Drawing.Image]::FromStream($Gifski_bitmap.StreamSource)
$Gifski_Icon = [System.Drawing.Icon]::FromHandle($Gifski_Picture.GetHicon())

#Extract Frames to png's with FFmpeg
   #Create "Gif_Frames" Folder in project temp directory.
    #Creating new folder for extracted frames each time in case of trim options changed in Staxrip after 1st gif creation/try. 
    #Could easily add a delete option but won't mess with deleting files on someone else computer, who knows what can happen with weird input names of videos...	
$Gif_Frames_Folder = ("Gif_Frames_" + $((get-date).ToString("hh_mm_ss")))
New-Item -Path $Project_Temp_Folder -name $Gif_Frames_Folder -ItemType "directory"
   #Notifier Params
$balloon = New-Object System.Windows.Forms.NotifyIcon 
$balloon.Icon = $FFmpeg_Icon
$balloon.BalloonTipText = "Extracting Frames..."
$balloon.BalloonTipTitle = "FFmpeg" 
$balloon.Visible = $true
$balloon.ShowBalloonTip(9000)    
   #FFmpeg process
& "$FFmpeg_path" -i "$StaxRip_script_path" ("$Project_Temp_Folder" + "$Gif_Frames_Folder" + "\frame%04d.png")
   #Notifier out
$balloon.dispose()

#Create gif with Gifski
   #Notifier Params
$balloon = New-Object System.Windows.Forms.NotifyIcon 
$balloon.Icon = $Gifski_Icon
$balloon.BalloonTipText = "Creating the gif..."
$balloon.BalloonTipTitle = "Gifski" 
$balloon.Visible = $true
$balloon.ShowBalloonTip(9000) 
   #Gifski process
$Output_Gif_Full = "`"$Gif_Output_Folder$File_output_name`""
$Stored_Frames_Path = "`"$($Project_Temp_Folder + $Gif_Frames_Folder)\frame""*"".png`""
Start-Process "$Gifski_path" "-o $Output_Gif_Full $Fps_setting $Quality_setting_Main $Resize_setting_Main $Stored_Frames_Path" -WindowStyle Minimized
   #Wait for Gifski to end
Wait-Process "Gifski"
   #Notifier out for gifski 
$balloon.dispose()
   #Notification for the End of Gif creation
$balloon = New-Object System.Windows.Forms.NotifyIcon 
$Staxrip = (Get-Process -id $pid).Path
$balloon.Icon  = [System.Drawing.Icon]::ExtractAssociatedIcon($Staxrip) 
$balloon.BalloonTipText = "All Done :)"
$balloon.BalloonTipTitle = "StaxRip" 
$balloon.Visible = $true
$balloon.ShowBalloonTip(3000)
Sleep -m 500
    #If Option is Set to True then Open destination folder with the created file once gif is created.
If ($Open_Folder_After_Creation -eq "True") {
Invoke-Expression "explorer /select,$Output_Gif_Full" }
   #Notifier out
Sleep -m 3000     
$balloon.dispose()

exit
