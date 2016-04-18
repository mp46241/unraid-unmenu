Unmenu is an improved, extensible web interface to supplement the web-based management console on Lime-Technology's unRAID Network Attached Storage OS.

Unmenu is a web-server and a set of web-pages written in GNU Awk.  It is restricted in that it can only handle one "request" connection at a time. Plug-in pages can be written in "awk" or in any interpreted text language.

To install this on an unRAID server
Create a /boot/unmenu directory

**mkdir /boot/unmenu**<br>

Download the unmenu_install zip file.    <b>The install utility will download the latest version of unMENU.</b>  (It does not have the same version number as unMENU)<br>
<br>
Unzip and move unmenu_install to the <b>/boot/unmenu</b> directory.<br>
<br>
Then<br>
<b>cd /boot/unmenu</b><br>
unmenu_install -i -d /boot/unmenu<br>
<br>
If you already have an older unmenu version installed type<br>
<b>unmenu_install -u</b>

To check an existing installation for available updates, type<br>
<b>unmenu_install -c</b><br>

To start unmenu running, invoke it as<br>
<b>/boot/unmenu/uu</b><br>
or<br>
<b>cd /boot/unmenu</b><br>
./uu<br>

Once running you can view the unMENU pages in your web-browser by browsing to<br>
<b>//tower:8080</b><br>

If you had a prior version of unMENU running, you'll need to restart it to see the new version.<br>
This will typically do it:<br>
<b>killall awk</b><br>
/boot/unmenu/uu<br>
<br>
If you are running an older version of unRAID that does not have the "wget" command  you will need to download and install it. (wget was added in version 4.4-final of unRAID)<br>
Instructions are in this post on the unRAID forum:<br>
<blockquote><a href='http://lime-technology.com/forum/index.php?topic=6018.msg57535#msg57535'>http://lime-technology.com/forum/index.php?topic=6018.msg57535#msg57535</a></blockquote>
