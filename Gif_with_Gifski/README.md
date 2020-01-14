# Gif_with_Gifski.ps1
A Powershell script to use inside [StaxRip](https://github.com/staxrip/staxrip) for creating high quality gif's with [Gifski](https://github.com/ImageOptim/gifski)

* _Only tested while using avisynth inside Staxrip, really not sure if it will work with VapourSynth, not installed on my system, if it works let me know ;)_

## **Installation :**

- Go to Tools > Edit Menu 
- Scroll down to "Animation" Section ( or where you want it to be, it's just an example here since there is already this section and tools existing for this in StaxRip 2.x.x.x )
- Click the little icon at the top left of the edit menu window to create a new menu entry there.
- Set a name like " _Gif for Gifski_ " or whatever you want.
- Set an icon ( if you want, it's just a fancy visual help in menus )
- In the command parameter select : **ExecutePowershellScript**
- Below this click on the right side of the "Script Code" box, a little button will appear, click on it and in the edit window paste the content from the **Gif_with_Gifski.ps1** file.


### Video shows it better :   
[<img src="https://i.imgur.com/WcZuVef.gif" width="60%">](https://streamable.com/2pspp)
>(click the animated preview image to watch the video)

There is another way to do this, mostly the same but instead of selecting the command parameter **ExecutePowershellScript** select **ExecuteScriptFile** and then on the next step you set the path to the **Gif_with_Gifski.ps1** file stored on your computer.

## Settings :
At the top of the **Gif_with_Gifski.ps1** there is a few things to set ( instructions are also in the script ) : 
- Set the Path to where **Gifski.exe** is located on your computer, for example : 

   ```$Gifski_path = "Z:\My_Tools\gifski.exe"```  
- Set the Path where you want to have the gif created, this is if you always want it created in a same specific location.

   ```$Gif_Output_Folder = "Z:\My_Gif_Folder"```
  > Not set by default, replace _$Gif_Output_Folder = " "_ by something like _$Gif_Output_Folder = "Z:\My_Gif_Folder"_
  
  > You can leave it empty, if this Output path for the gif is not set or incorrect the Gif will be created inside the Temp folder used by StaRip.
- Option to open the Gif destination folder once it is created, Options are True or False, default set to "True".

   ```$Open_Folder_After_Creation = "True"```

- Option to display Infos and the Estimated Size of the output Gif, the estimation is highly inaccurate to say the least :p. 
  Options are "True or "False" default set to "True"
   
   ```$Show_Estimated_Size = "True"```
   > Needs to be worked on but it's not easy, started to work on Input analyze using avisynth scripts to detect how much movement there is
   > and the changes of colors/luma across the Input and get a sort of complexity index used as multiplicator for the size estimation,
   but after countless hours spent on this I gave up, might get back on this when I'll have many hours to kill... For now I let it go like this...
   For reference : https://github.com/ImageOptim/gifski/issues/28
   
And... That' all, you're good to go now.   




## How it works :
- Input a video or a .avs file into Staxrip, then while in preview mode trim the part you want to keep for the gif output using the " _Cut_ " menu, ( think about this or you will end up with all frames from the input extracted, and it can take quite some space, plus an insane sized gif as output after a long processing...), crop the video if you want, resize it inside Staxrip if you want to, add whatever you want as usual with Staxrip filter etc...

- Then you launch the _Gif_with_Gifski_ script via the menu we created, it will bring a few settings popups asking to :
  - Select the Framerate for the output gif, default is Staxrip Target Framerate rounded. ( If you change the FPS in Staxrip using a filter then it will be this framerate that will be selected by default, else it will be the input file framerate by default) 
  - Select the quality of the gif, default is 100 (Best quality), possible _1_ to _100_ or _Fast_ ( -10% quality and bigger output with the option _Fast_)
  - Then you will be asked if you want to resize the gif, of course you can resize it before launching the Gif_with_Gifski script by using one of the resizers filters included in Staxrip or a custom one you have included in Staxrip filters, probably will be faster done this way too.
    > Note that only downsizing is possible when this is managed by Gifski itself, no upscale possible, if you need to upscale resize directly inside staxrip before launching the script..
	
    > To keep aspect ratio set a width size then on the next step set 0 for the height size.
  
    > In cases where you set a width or height greater than what have been set in Staxrip for target size, then no resizing will be done by Gifski itself, options will be overwritten and set to Staxrip target size.
  
    > Best imo is to resize directly in Staxrip, it will be a bit faster, take less space for extracted frames too, but option is there just in case...
  
  - Then after this and If the option "$Show_Estimated_Size" is set to "True", a popup will come once those parameters are set to show a size estimation for the output gif and display infos about the settings selected, an option to canel and set again the parameters like said earlier this is highly inaccurate... You can turn this option off anyways.

- FFmpeg will extract the frames from the video part you trimmed / selected into png's inside a subfolder located in the Temp folder used by Staxrip and named "Gif_Frames_hh-mm_ss", hh_mm_ss = Hour,minutes,seconds it will look like this _Gif_Frames_11_32_25_

  > Each time a gif creation is launched a new unique _Gif_Frames_hh-mm_ss_ folder will be created for the extracted frames, just in case trim was set differently between the two tries, could have added an option to delete png's in the folder if they already exist but i don't want to mess with deleting stuff automatically in the end user computer, scared about weird videos input names that can lead to unexpected results, so this script just creates a new folder each time instead.
- Gifski will use those extracted png's to do his thing and create a nice quality gif.

Seems complicated when we read it but no worries it's not, see in video  :

## Usage Demo :
[<img src="https://i.imgur.com/ASAPzUA.gif" width="60%">](https://streamable.com/d47u3)
>(click the animated preview image to watch the video)

- And this is the result from this quick video example : 

[<img src="https://i.imgur.com/UNDsjgz.gif" width="40%">](https://i.imgur.com/UNDsjgz.gif)

Enjoy :)
