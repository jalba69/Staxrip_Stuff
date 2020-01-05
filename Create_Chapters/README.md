# Create_Chapters.ps1
A simple Powershell script to create chapters from the preview window in [StaxRip](https://github.com/staxrip/staxrip).

## **Installation :**

- Open any content in Staxrip so you can trigger the preview mode (or click "preview" it will ask you to open a video anyways).
- Once the preview mode window is opened then : right click > Edit Menu.
- Click on the first icon at the top left to create a new entry in the menu list.
- Set the name for this new menu entry, like "Create Chapters" or whatever you want.
- Set an icon ( if you want ).
- In the command parameter select : **ExecutePowershellScript**
- Below this click on the right side of the "Script Code" box, a little button will appear, click on it and in the edit window paste the content from the **Create_Chapters.ps1** file.

### Video shows it better :   
[<img src="https://i.imgur.com/HbW04Fm.gif" width="60%">](https://streamable.com/0qt3o)
>(click the animated preview image to watch the video)
 
There is another way to do this, mostly the same but instead of selecting the command parameter **ExecutePowershellScript** select **ExecuteScriptFile** and then on the next step you set the path to the **Create_Chapters.ps1** file.

## Settings :
Well, there is only one setting... The pre-filled chapter name format that you can change at the top of the file.

>1 - Use TimeStamps as chapter name           
ex : 00:14:47.762  

>2 - Use Numbers for Chapter name             
ex : Chapter #07  

>3 - Use Roman Numbers for Chapters name      
ex : Chapter VII

>4 - Use Numbers + Part for Chapters names   
ex : Part #03  

Defult option is "3", Using Roman numbers.
To change this replace the number "3" by one of the 3 other options here in the code:
> $Selected_Chapter_Names = "3"

Of course you can enter your own chapter name by typing it in the input box, this is just fancy pre-filled options for the lazy ones like me :p 

## Usage Demo :
[<img src="https://i.imgur.com/Pe7VCOJ.gif" width="60%">](https://streamable.com/934oj)
>(click the animated preview image to watch the video)

That's it, the chapter file is created inside the Temp folder used by Staxrip, it is named **Custom_Chapters.txt**
(Using this filename to not mess with a potential already existing chapter file being demuxed when adding a video into Staxrip)

Now you will just need to click on Container Options >  Options tab > browse to the chapters file path to add the chapters to your Mkv's or Mp4's :
![pic](https://i.imgur.com/xyxih12.png)


>Sadly custom muxer profiles do not allow the use of macros for paths so it ain't possible to create a template using a custom container set with a macro like "%working_dir%Custom_Chapters.txt" for the chapter path skipping the manual selection of our custom chapters file fully automated, for now it needs to be picked up manually each but that will do ;)

Enjoy :)
