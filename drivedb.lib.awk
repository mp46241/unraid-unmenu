#ADD_ON_VERSION 1.41 - contributed by bjp999
#ADD_ON_VERSION 1.42 - changed spinup method
#UNMENU_RELEASE $Revision$ $Date$

#-----------------------------------------------------------------------
# This function begins the creation of the drivedb[] associative array. 
# ... assumes an array called "ColorHtml" exists.
#-----------------------------------------------------------------------
function LoadDriveDb(i, k, nextslot) {
   GetArrayStatus(); #call JoeL.'s function to do the heavy lifting
   nextslot=numdisks

   #-----------------------------------------
   # Loop though all the disks in the array. 
   #-----------------------------------------
   i=0;
   for(k=0; k<numdisks; k++) {

      #-------------------------------------------------------------
      # Do not show "not present" drives, except parity (see below) 
      #-------------------------------------------------------------
      if(disk_status[k] == "DISK_NP")
         continue;

      if(disk_status[k] == "DISK_NEW") {
         drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-weight:bold"
         disk_name[k] = "md" k
      }

      drivedb[i, "num"] = k
      #p("ds=" disk_status[k])
      #drivedb[i, "name"] = disk_name[k];
      if((disk_name[k] == "") && (k == 0)) {
         drivedb[i, "md"] = "parity"
         drivedb[i, "role"] = "parity"
      }
      else {
         drivedb[i, "md"] = disk_name[k];
         drivedb[i, "role"] = "array disk"
      }

      drivedb[i, "disk"] = drivedb[i, "md"]
      gsub("md", "disk", drivedb[i, "disk"])

      #--------------------------------
      # Deal with missing parity drive 
      #-------------------------------- 
      if((disk_status[k] == "DISK_DSBL_NP") && (drivedb[i, "num"] == 0)) { #no parity present
         drivedb[i, "fullid"] = \
         drivedb[i, "serial"] = \
         drivedb[i, "disk_size"] = \
         drivedb[i, "modelnum"] = \
         drivedb[i, "reads"] = \
         drivedb[i, "writes"] = \
         drivedb[i, "errors"] = \
         drivedb[i, "dev"] = "";
         drivedb[i, "manu"] = "NOT PROTECTED";
         drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-weight:bold" 

         drivedb[i, "disk_size_raw"] = \
         drivedb[i, "reads_raw"] = \
         drivedb[i, "writes_raw"] = 0;

         drivedb[i, "status"] = "N/A";
      } else {
         #if(disk_status[k] == "DISK_DSBL")
         #   drivedb[i, "rowextra"] = drivedb[ix, "rowextra"] ColorHtml[color="orange"];

         drivedb[i, "fullid"] = disk_id[k];
         gsub(/ /, "", rdisk_serial[k]);
         drivedb[i, "serial"] = rdisk_serial[k];
         drivedb[i, "disk_size_raw"]   = rdisk_size[k]*1.024;
         #p("disk_size_raw=" drivedb[i, "disk_size_raw"] )
         #p("disk_size_raw=" sprintf("%.1f", drivedb[i, "disk_size_raw"]/1000/1000/1000 )) 

         #drivedb[i, "disk_size_1000c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_size_raw"]/1000)); 
         #drivedb[i, "disk_size_1024c"] = CommaFormat(sprintf("%d", disk_size[i])); 
         drivedb[i, "disk_size"]   = human_readable_number(drivedb[i, "disk_size_raw"], 0, 0, 0, 1);
         #p("disk_size_raw=" drivedb[i, "disk_size"] ) 

         #if(drivedb[i, "disk_size"] ~ "[0-9]+.0")
         #   drivedb[i, "disk_size"]= human_readable_number(drivedb[i, "disk_size_raw"], 0, 0, 0, 0);

         if(drivedb[i, "md"] != "parity") {
            drivedb["total", "disk_size_raw"]  += int(rdisk_size[k]*1.024);
         }

         drivedb[i, "modelnum"]  = rdisk_model[k];
         GetDriveManufacturer(i)

         drivedb[i, "reads_raw"]  = disk_reads[k];
         drivedb[i, "writes_raw"] = disk_writes[k];

         drivedb[i, "reads"]  = CommaFormat(disk_reads[k]);
         drivedb[i, "writes"] = CommaFormat(disk_writes[k]);

         drivedb[i, "errors"] = disk_errors[k];
         drivedb[i, "status_raw"] = disk_status[k];
         drivedb[i, "status"] = disk_status[k];
         gsub("DISK_", "", drivedb[i, "status"]);
         ic[1] = constant["ICON_OK"];
         ic[2] = constant["ICON_OK"];
         ic[3] = constant["ICON_OK"];
         ic[4] = constant["ICON_OK"];
         ic[5] = constant["ICON_OK"];
         ic[6] = constant["ICON_WARN"];
         ic[7] = constant["ICON_ERR"];
         ic[8] = constant["ICON_NEW"];

         drivedb[i, "staticon"] = ic[1 + int( rand() * 8 )];
         #drivedb[i, "staticon"] = constant("ICON_" drivedb[i, "status"]);
         #drivedb[i, "staticon"] = "<img src='/shared/images/bjp/array_disk_base2ok.jpg' border='0' style='height:2em;'>";
         drivedb[i, "dev"]    = disk_device[k];
      }

      if(disk_status[k] == "DISK_DSBL_NEW")
         drivedb[i, "rowextra"] = drivedb[ix, "rowextra"] ColorHtml[color="blue"];
      else if((disk_status[k] != "DISK_OK") && (disk_status[k] != "DISK_NEW"))
         drivedb[i, "rowextra"] = drivedb[ix, "rowextra"] ColorHtml[color="orange"];
      else if(drivedb[i, "dev"] == highlightdev)
         drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";background: " highlightcolor; 

      drivedb[rdisk_serial[k]]   = i;  #allows indexed access to drive by serial number
      drivedb[drivedb[i, "md"]]  = i;  #allows indexed access to a drive by "md"
      drivedb[drivedb[i, "dev"]] = i;  #allows indexed access to a drive by "device"
      i++;
   }
   drivedb["count"] = i;
   nextslot=i

   GetOtherDisks(); #Load the non-array disks into the drivedb[]

   return(nextslot);
 }

#-----------------------------------------------------------------------
# This function tries to figure out the drive manufacturer based on the
# drive model number. 
#-----------------------------------------------------------------------
function GetDriveManufacturer(ix, dm2, dm3)
{
   #--------------------------------------------------------------
   # Try to figure out the drive manufacturer based on the model. 
   #--------------------------------------------------------------
   dm2 = tolower(substr(drivedb[ix, "modelnum"],1,2))
   dm3 = tolower(substr(drivedb[ix, "modelnum"],1,3))
   if((dm2=="st") || (dm3=="sea"))
      drivedb[ix, "manu"]  = "Seagate";
   else if((dm2=="wd") || (dm3=="wes")) {
      drivedb[ix, "manu"] = "WD"
      drivedb[ix, "smart_nospinup"] = "1"
   }
   else if((dm3=="hds") || (dm3=="hit"))
      drivedb[ix, "manu"] = "Hitachi"
   else if((dm2=="hd") || (dm3=="sam"))
      drivedb[ix, "manu"] = "Samsung"
   else if(dm3=="max")
      drivedb[ix, "manu"] = "Maxtor"
   else
      drivedb[ix, "manu"] = "Unknown"
   #--------------------------------------------------------------
   # Remember that you can explicityly define the manufacturer for 
   # your drive in the myMain.conf file
   #--------------------------------------------------------------
}


#----------------------------------------------
# Set a few values not set by other functions. 
#----------------------------------------------
function LoadOtherInfo(i)
{
   drivedb["total", "disk_size"]   = human_readable_number(drivedb["total", "disk_size_raw"], 0, 0, 0, 2);

   drivedb["total", "disk"] = "Total";
   drivedb["total", "rowextra"] = drivedb["total", "rowextra"] ";" TotalColorHtml; 

   for(i=0; i<drivedb["count"]; i++) {
      drivedb[i, "disk_size_1000c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_size_raw"])); 
      drivedb[i, "disk_size_1024c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_size_raw"]/1.024)); 

      drivedb[i, "disk_free_1000c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_free_raw"])); 
      drivedb[i, "disk_free_1024c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_free_raw"]/1.024)); 

      drivedb[i, "disk_used_1000c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_used_raw"])); 
      drivedb[i, "disk_used_1024c"] = CommaFormat(sprintf("%d", drivedb[i, "disk_used_raw"]/1.024)); 
   }
   drivedb["total", "disk_size_1000c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_size_raw"])); 
   drivedb["total", "disk_size_1024c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_size_raw"]/1.024)); 

   drivedb["total", "disk_free_1000c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_free_raw"])); 
   drivedb["total", "disk_free_1024c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_free_raw"]/1.024)); 

   drivedb["total", "disk_used_1000c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_used_raw"])); 
   drivedb["total", "disk_used_1024c"] = CommaFormat(sprintf("%d", drivedb["total", "disk_used_raw"]/1.024)); 
}


#-------------------------------------------------------------------------
# This function calls the "bwm-ng" command twice - once to get disk I/O 
# activity, and once to get network activity.  I found some bugs with the 
# "-oplain" option.  "-ocsv" works much better. 
#-------------------------------------------------------------------------
function GetPerformanceData(RxHtml, TxHtml, cmd, cmd1, cmd2, i, a, li, dev, Tx, Rx, RxTx)
{
    RS="\n"
    #cmd="bwm-ng -t1000 -Tavg -idisk -oplain -c 1 -d|grep -v 'iface\\|-\\|=\\|bwm\\|md'"

    #----------------------------
    # Gets disk performance data 
    #----------------------------

    #------------------------------------------------------------------------
    # I want these runs to occur simultaneously so that the same interval is 
    # measured (it also speeds up response time).  To accomplish this, I kick 
    # off the network monitoring in the background (via nohup).  It pipes 
    # its output to a file.  I then process the disk monitoring normally.  
    # When it is done the other one should be done also, but I add a short 
    # pause just to be sure. 
    #------------------------------------------------------------------------
    cmd1="bwm-ng  -idisk -ocsv -c 1 |grep -v 'md'"
    cmd2="nohup bwm-ng -ocsv -c 1 -d 2>/dev/null |grep 'eth0' >/tmp/perf.txt 2>/dev/null&"
    system(cmd2)

    while ((cmd1 | getline a) > 0 ) {
       li["count"] = split(a, li, ";")
       #print "<p>"a"</p><p>"
       #for(i=1; i <= li["count"]; i++)
       #   print "li[" i "]=" li[i] ", "
       #print "</p>"

       dev = li[2]
       #print "<p>dev=" dev "</p>"
       if(dev=="total")
          #i = "total"
          continue;
       else {
          i = drivedb[dev]
       }

       Tx = li[3]+0;
       Rx = li[4]+0;
       RxTx = li[5]+0;

       if(i != "") {
          if(Rx != 0) {
             drivedb[i, "RxSpeed"] = HumanReadablePerSec(Rx);
             drivedb[i, "RxSpeed_raw"] = Rx;
             drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-weight:bold"  #bold rows that have I/O activity
          } else {
             drivedb[i, "RxSpeed"] = "--";
             drivedb[i, "RxSpeed_raw"] = 0;
          }

          if(Tx != 0) {
             drivedb[i, "TxSpeed"] = HumanReadablePerSec(Tx);
             drivedb[i, "TxSpeed_raw"] = Tx;
             drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-weight:bold"  #bold rows that have I/O activity
          } else {
             drivedb[i, "TxSpeed"] = "--";
             drivedb[i, "TxSpeed_raw"] = 0;
          }

          if(RxTx != 0) {
             drivedb[i, "RxTxSpeed"] = HumanReadablePerSec(RxTx);
             drivedb[i, "RxTxSpeed_raw"] = RxTx;
          } else {
             drivedb[i, "RxTxSpeed"] = "--";
             drivedb[i, "RxTxSpeed_raw"] = 0;
          }
       }
    }
    close(cmd1);

    system("sleep 0.5") #Make sure nohup'ed command is complete

    #-------------------------------
    # Get network performance data. 
    #-------------------------------
    cmd="cat /tmp/perf.txt"
    cmd | getline a           #only one line of output
    delete li
    li["count"] = split(a, li, ";");

    Tx = li[3]+0;
    Rx = li[4]+0;
    #p("Rx="Rx "-" HumanReadablePerSec(Rx) ", Tx="Tx "-" HumanReadablePerSec(Tx));

    if(Rx > 500)
       drivedb["total", "RxSpeed"] = RxHtml HumanReadablePerSec(Rx);
    else
       drivedb["total", "RxSpeed"] = RxHtml "--";

    if(Tx > 500)
       drivedb["total", "TxSpeed"] = TxHtml HumanReadablePerSec(Tx);
    else
       drivedb["total", "TxSpeed"] = TxHtml "--";

    close(cmd);
}


#------------------------------------------------------------
# This function loads the smart data into the drivedb array. 
# ... uses red_temp, orange_temp, yellow_temp, blue_temp, co[], constant[] 
#------------------------------------------------------------
function GetSmartData(cmd, a, ix, ix2, lst, t, d, mode, i, color, v, found, cmd2, b, dl, desc, cmd3, c, dt, tm, mn) 
{
   #-------------------------------------------------------------------------
   # This logic will add add'l rows to the drivedb[] array (and hence to the 
   # output HTML table) based on locally collect smart reports.
   #-------------------------------------------------------------------------
   if((t=constant["smartwsfolder"]) != "") {
      cmd = "find " t " -maxdepth 1 -type d -ls"

      #-------------------------------------------------
      # Process each line, they will look like this ...
      #  /mnt/cache/Smart
      #  /mnt/cache/Smart/host1
      #  /mnt/cache/Smart/host1/sn1
      #  /mnt/cache/Smart/host1/sn2
      #  ...
      #  /mnt/cache/Smart/host2
      #  /mnt/cache/Smart/host2/sn3
      #  ...
      #-------------------------------------------------
      while ((cmd | getline a) > 0 ) {
         gsub(".*" t, "", a);
         delete d;
         d["count"] = split(a,d,"/")
         if(d["count"] == 2) {
            cmd3="ls -l " t a
            perr("cmd3="cmd3)
            cmd3 | getline c #skip first line: "total: "
            while((cmd3 | getline c) > 0) {
               #gsub(".*\:[0-9][0-9] ", "", c)
               gsub(".*:[0-9][0-9] ", "", c)
               #perr("c=" c);

               cmd2 = "fromdos<" t a "/" c "/driveinfo.txt"
               #perr("cmd2="cmd2);

               cmd2 | getline b;
               cmd2 | getline dl;
               cmd2 | getline desc;
               close(cmd2);
               cmd2 = "ls -lt " t a "/" c "/smart_*.txt";
               cmd2 | getline b;
               gsub("^[^/]*", "", b); #b is the filename (/directory/smart_yyyymmdd_hhmn.txt)
               #perr(b);
               close(cmd2);
               perr(b);

               i=drivedb["count"]++;
               drivedb[i, "num"]    = i;
               drivedb[i, "dev"]    = dl;
               drivedb[i, "md"]     = "";
               drivedb[i, "role"]   = "file"; 
               #drivedb[i, "disk"]   = d[2] " " DateTimeStringFromFileName(b);
               drivedb[i, "disk"]   = d[2];
               drivedb[i, "filedate"] = DateTimeStringFromFileName(b); 
               drivedb[i, "fullid"] = d[2];
               drivedb[i, "status"] = "WS"
               drivedb[i, "file"]   = b;
               drivedb[i, "spinind"] = 2;
               drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-style:italic;color: blue"
            }
            close(cmd3)
         }
      }
      close(cmd);
   }

   #-------------------------------------------------------------------------
   # This logic will add add'l rows to the drivedb[] array (and hence to the 
   # output HTML table) based on the *.txt files in a configurable folder. 
   # This loads some known bad smart reports so you can see what they will 
   # look like when loaded in the myMain smart view. 
   #-------------------------------------------------------------------------
   if((t=constant["smartlogfolder"]) == "")
      t="smartlog"
   cmd = "ls " t "/*.txt 2>/dev/null" #cmd to get the list of files

   #-------------------------------
   # For each file, add a new row. 
   #-------------------------------
   while ((cmd | getline a) > 0 ) {
       i=drivedb["count"]++;
       drivedb[i, "num"]    = i;
       drivedb[i, "dev"]    = "file";
       drivedb[i, "md"]     = "";
       drivedb[i, "role"]   = "file"; 
       delete d;
       d["count"] = split(a,d,"/")
       drivedb[i, "disk"]   = d[d["count"]]; 
       drivedb[i, "fullid"] = a;
       drivedb[i, "status"] = "FL"
       drivedb[i, "file"]   = a;    
       drivedb[i, "spinind"] = 2;
       drivedb[i, "rowextra"] = drivedb[i, "rowextra"] ";font-style:italic;color: blue" 
       #perr("FILE:" drivedb[i, "file"])
   }
   close(cmd);

   #------------------------------------------------------------------------
   # Now loop through all the rows in the drivedb array (including those we 
   # just added. 
   #------------------------------------------------------------------------
   for(ix=0; ix<drivedb["count"]; ix++) {
      lst=lst " " "/dev/" drivedb[ix, "dev"];

      #----------------------------------------
      # Don't run smart report on flash drive. 
      #----------------------------------------
      if(drivedb[ix, "disk"] == "flash") {
         drivedb[ix, "smart_family"] = "Flashdrive"
         continue;
      }

      #-------------------------------------------------------------------
      # Don't run a smart report on drives that are spun down / can't run 
      # smart while spun down 
      #-------------------------------------------------------------------
      if((drivedb[ix, "spinind"] == 0) && (drivedb[ix, "smart_nospinup"] == 0)) {
         #Find latest smartctl file for this drive
         perr("DSN=" drivedb[ix, "serial"])
         if((t=constant["smarturfolder"]) == "") {
            drivedb[ix, "smart_family"] = "zzz ..."
            continue;
         }

         cmd = "find " t " -iname " drivedb[ix, "serial"] " -ls"
         cmd | getline a
         close(cmd);

         if(a == "") { #not found
            drivedb[ix, "smart_family"] = "zzz ..."
            continue;
         }

         gsub(".*:[0-9][0-9] ", "", a);

         cmd = "ls -lcr " a "/smart_*"
         perr("cmd="cmd)
         perr("a="a)

         cmd | getline a
         close(cmd)

         if(a == "") { #not found
            drivedb[ix, "smart_family"] = "zzz ..."
            continue;
         }

         gsub(".*:[0-9][0-9] ", "", a);
         perr(a);

         drivedb[ix, "file"] = a;
         #drivedb[ix, "disk"] = drivedb[ix, "disk"] " " DateTimeStringFromFileName(a)
         drivedb[ix, "disk"] = drivedb[ix, "disk"];
         drivedb[ix, "filedate"] = DateTimeStringFromFileName(a)
         drivedb[ix, "rowextra"] = drivedb[i, "rowextra"] ";color: blue"
      }

      #--------------------------------------------------------------------
      # If it is a file, load the smartctl from the file.  Otherwise, load 
      # it from the smartctl command. 
      #--------------------------------------------------------------------
      if(drivedb[ix, "file"] == "")
         cmd = "smartctl -a -d ata /dev/" drivedb[ix, "dev"]
      else
         cmd = "fromdos<\"" drivedb[ix, "file"] "\""

      #p("cmd='" cmd "'")

      #----------------------------
      # Process the smartctl file 
      #--------------------------*/
      while ((cmd | getline a) > 0 ) {
          #perr(a);
         color="";
         if(a ~ "Model Family") {
            delete d
            split(a, d, ":")
            gsub("^ +", "", d[2])
            drivedb[ix, "smart_family"] = d[2]; 
            #p("smart_family=" drivedb[ix, "smart_family"]); 
         }
         else if (a ~ "Not in smartctl database") {
            drivedb[ix, "smart_family"] = drivedb[ix, "manu"] " (unknown family)"; 
         }
         else if(a ~ "Device Model") {
            delete d
            split(a, d, ":")
            gsub("^ +", "", d[2])
            drivedb[ix, "smart_model"] = d[2]; 
            #p("smart_model=" drivedb[ix, "smart_model"]); 
         }
         else if(a ~ "Firmware Version") {
            delete d
            split(a, d, ":")
            gsub("^ +", "", d[2])
            drivedb[ix, "smart_firmware"] = d[2]; 
            #p("smart_firmware=" drivedb[ix, "smart_firmware"]); 
         }
         else if(a ~ "ATA Version is") {
            delete d
            split(a, d, ":")
            gsub("^ +", "", d[2])
            drivedb[ix, "smart_ata_ver"] = d[2]+0; 
            #p("smart_ata_ver=" drivedb[ix, "smart_ata_ver"]); 
         }
         else if(a ~ "SMART overall-health") {
            delete d
            split(a, d, ":")
            gsub("^ +", "", d[2])
            if(d[2] == "PASSED")
               d[2] = constant["PassedHtml"];
            else if (d[2] == "FAILED!") {
               d[2] = constant["FailedHtml"];
               drivedb[ix, "smart_overallextra"] = drivedb[ix, "smart_overallextra"] ColorHtml["red"]; 
            }
            drivedb[ix, "smart_overall"] = d[2]; 
            #p("smart_overall=" drivedb[ix, "smart_overall"]); 
         }
         else if(a ~ "ID#")
            mode="ATTR"
         else if(a ~ "No Errors Logged")
            drivedb[ix, "errors_logged"]        = "0"; 
         else if(a ~ "^ATA Error Count") { 
            delete d
            split(a, d, " ")
            t=d[4]+0;
            ix2="ata_error_count";
            #p(ix2 "=" t);
            drivedb[ix, ix2] = t; 
            if((drivedb[ix, ix2]>0) && (d[4]<=drivedb[ix, ix2 "_ok"]))
               drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="override"]; 
            else if(t>0) 
               drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="red"];
         }                              
         else if ((a ~ "^ *[1-9]+") && (mode == "ATTR")) {
            delete d
            #perr("Attr line: '" a "'")
            split(a, d)

            drivedb[ix, "smart_attr_" d[1] "_name"]        = tolower(d[2]); 
            drivedb[ix, "smart_attr_" d[1] "_flag"]        = d[3]; 
            drivedb[ix, "smart_attr_" d[1] "_value"]       = d[4]; 
            drivedb[ix, "smart_attr_" d[1] "_worst"]       = d[5]; 
            drivedb[ix, "smart_attr_" d[1] "_thresh"]      = d[6]; 
            drivedb[ix, "smart_attr_" d[1] "_type"]        = d[7]; 
            drivedb[ix, "smart_attr_" d[1] "_updated"]     = d[8]; 
            drivedb[ix, "smart_attr_" d[1] "_when_failed"] = d[9]; 
            t = d[10] " " d[11] " " d[12] " " d[13] " " d[14] " " d[15] " " d[16] " " d[17] " " d[18]
            t = t "                         "
            t = gensub("[ \\t]+$", "", 1, t) 

            #------------------------------------------
            # Make the value numeric if it is a number 
            #------------------------------------------
            if(t ~ "^[0-9]+$")
               t=t+0;
               
            drivedb[ix, "smart_attr_" d[1] "_raw"]         = t; 

            ix2 = tolower(d[2])
            if(ix2 == "unknown_attribute")
               ix2="attribute_" d[1];
            if(d[9] != "-") {
               t = d[9]; 
               if(t ~ "FAILING_NOW") {
                  t = "Failing";
                  color="red"
               }
               else if (t ~ "past") {
                  t = "Past Failure"
                  color="orange"
               }
               else {    #don't know of any other values, but just in case
                  gsub("_", " ", t);
                  color="red"
               }
               drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color];
               #p(color " = " drivedb[ix, ix2 "extra"])

               drivedb[ix, ix2] = drivedb[ix, "smart_" d[1]] = drivedb[ix, "smart_attr_" d[1] "_raw"] " (" t ")"
               color="" #@@@ why?
               #perr("drivedb[" ix ", " ix2 "]='" drivedb[ix, ix2])

               if(drivedb[ix, "smart_fail_lst"] != "")
                  t = ""  
               else 
                  t = ""

               #drivedb[ix, "smart_fail_lst"] = drivedb[ix, "smart_fail_lst"] t "<div style=\"background-color:" color ";\">" bullet drivedb[ix, "smart_attr_" d[1] "_name"] "</div>"
            }
            else {
               drivedb[ix, ix2] = drivedb[ix, "smart_" d[1]] = drivedb[ix, "smart_attr_" d[1] "_raw"];
               #perr("drivedb[" ix ", " ix2 "]='" drivedb[ix, ix2] "'")
            }

            #---------------------
            # Special color rules
            #---------------------
            t=drivedb[ix, "smart_attr_" d[1] "_raw"]
            if(ix2 ~ "temperature") {
               split(t, v)
               if(drivedb[ix, ix2 "_delta"] != "") {
                  v[1] = v[1] + drivedb[ix, ix2 "_delta"]
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml["override"]; 
                  drivedb[ix, ix2] = drivedb[ix, "smart_" d[1]] = v[1] " adj [" drivedb[ix, "smart_attr_" d[1] "_raw"] ")";
                  drivedb[ix, ix2] = drivedb[ix, "smart_" d[1]] = v[1] " adj [" drivedb[ix, "smart_attr_" d[1] "_raw"] ")";
               }
               else
                  drivedb[ix, ix2] = drivedb[ix, "smart_" d[1]] = gensub("Lifetime Min/Max ", "", 1, drivedb[ix, ix2]); 
               
               if(v[1] >= red_temp)
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="red"];
               else if(v[1] >= orange_temp)
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="orange"];
               else if(v[1] >= yellow_temp) 
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="yellow"];
               else if(v[1] <= blue_temp) 
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="blue"];

            }
            else if(ix2 == "reallocated_sector_ct") {
               if((drivedb[ix, ix2 "_ok"]>0) && (t<=drivedb[ix, ix2 "_ok"]))
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="override"]; 
               else if(t>10)  
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="red"]; 
               else if(t>0)
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="orange"]; 
            }
            else if(ix2 == "current_pending_sector") {
               if(t>0)
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="red"]; 
            }
            #else if ("reported_uncorrect high_fly_writes offline_uncorrectable udma_crc_error_count calibration_retry_count spin_retry_count" ~ d[1]) {
            else if((",187,189,11,10,5," ~ "," d[1] ",") || (d[1]>195)) {
               #co1lor="yellow";
               if((drivedb[ix, ix2 "_ok"]>0) && (t<=drivedb[ix, ix2 "_ok"]))
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="override"]; 
               else if(t>0)
                  drivedb[ix, ix2 "extra"] = drivedb[ix, ix2 "extra"] ColorHtml[color="yellow"]; 
            }
         }
         else if(a ~ "SMART Error Log Version") {
            mode="LOG"
         } 
         if((color == "yellow") || (color == "red") || (color == "orange")) {
            found=0;
            for(k=1; k<=co["count"]; k++) {
               if(co[k] == ix2) {
                  found=1;
                  break;
               }
            }
            if(found == 0)
               #drivedb[ix, "smart_fail_lst"] = drivedb[ix, "smart_fail_lst"] comma "<div style=\"background-color:" color ";\">" bullet ix2 "=" t "</div>" 
               drivedb[ix, "smart_fail_lst"] = drivedb[ix, "smart_fail_lst"] "<div style=\"" ColorHtml[color] ";\">" bullet ix2 "=" t "</div>" 
               #p(ix "="drivedb[ix, "smart_fail_lst"])
         }
            #p("smart_overall=" drivedb[ix, "smart_overall"]); 
      }

      #if(drivedb[ix, "smart_fail_lst"] != "")
      #   drivedb[ix, "smart_fail_lst"] = drivedb[ix, "smart_fail_lst"] "</span>"

      close(cmd)
   }
}

#----------------------------------------------------------------------------
# This function calls JoeL.'s GetDiskData() function and then reformats the 
# data into the drivedb[] array structure. 
#----------------------------------------------------------------------------
function GetOtherDisks(bootdrive, cachedrive, a, i, modela, k, m, ms, outstr) {

    GetDiskData(); #Another of JoeL.'s functions that do the heavy lifting on non-array disks

    bootdrive = ""
    cachedrive = ""
    unassigned_drive = ""
    for( a = 1; a <= num_partitions; a++ ) {
       if ( mounted[a] == "/mnt/cache" ) {
          i=drivedb["count"]++;
          drivedb[i, "num"]    = i;
          drivedb[i, "dev"]    = substr(device[a], 1, 3);;

          if(drivedb[i, "dev"] == highlightdev)
             drivedb[i, "rowextra"] = drivedb[i, "rowextra"] "background: " highlightcolor; 

          #drivedb[i, "name"]   = "cache";
          drivedb[i, "md"]     = device[a];
          drivedb[i, "role"]   = "cache"; 
          drivedb[i, "disk"]   = "cache"; 
          drivedb[i, "fullid"] = model_serial[a];
          delete ms
          k=split(model_serial[a], ms, "_");
          modela=""

          for(m=1; m<k; m++)
             modela=modela " " ms[m]

          drivedb[i, "serial"] = ms[k];
          drivedb[i, "modelnum"]  = substr(modela,2);
          GetDriveManufacturer(i)
          drivedb[i, "size"]   = -1; # need this?
          drivedb[i, "reads_raw"]  = other_reads[a];
          drivedb[i, "writes_raw"] = other_writes[a];
          drivedb[i, "reads"]  = CommaFormat(other_reads[a]);
          drivedb[i, "writes"] = CommaFormat(other_writes[a]);
          drivedb[i, "status_raw"] = "DISK_MT"
          drivedb[i, "status"] = "MT"
         drivedb[i, "staticon"] = constant["ICON_CACHE"];

          drivedb[drivedb[i, "serial"]] = i;  #allows indexed access to drive by serial number
          drivedb[drivedb[i, "dev"]] = i; #allows indexed access to a drive by disk name
          drivedb[drivedb[i, "dev"]"1"] = i; #allows indexed access to a drive by disk name
       } else if ( mounted[a] == "/boot" ) {
          i=drivedb["count"]++;

          if(view[activeview, "smartdata"] > 0)
             drivedb[i, "suppress"] = 1

          drivedb[i, "num"]    = i;
          drivedb[i, "dev"]    = substr(device[a], 1, 3);

          if(drivedb[i, "dev"] == highlightdev)
             drivedb[i, "rowextra"] = drivedb[i, "rowextra"] "background: " highlightcolor; 

          #drivedb[i, "name"]   = "boot";
          drivedb[i, "md"]     = device[a];
          drivedb[i, "role"]   = "boot"; 
          drivedb[i, "disk"]   = "flash"; 
          if(substr(model_serial[a], 1, 4) == "usb-") 
             model_serial[a] = substr(model_serial[a], 5);
          if(substr(model_serial[a], length(model_serial[a])-3) == "-0:0")
             model_serial[a] = substr(model_serial[a], 1, length(model_serial[a])-4)
          drivedb[i, "fullid"] = model_serial[a];
          #drivedb[i, "serial"] = model_serial[a];
          #drivedb[i, "modelnum"]  = model_serial[a];
          delete ms
          k=split(model_serial[a], ms, "_");
          modela=""

          for(m=1; m<k; m++)
             modela=modela " " ms[m]

          drivedb[i, "serial"] = ms[k];
          drivedb[i, "modelnum"]  = substr(modela,2);
          GetDriveManufacturer(i)

          drivedb[i, "size"]   = -1; # need this?
          drivedb[i, "reads_raw"]  = other_reads[a];
          drivedb[i, "writes_raw"] = other_writes[a];
          drivedb[i, "reads"]  = CommaFormat(other_reads[a]);
          drivedb[i, "writes"] = CommaFormat(other_writes[a]);
          drivedb[i, "status_raw"] = "DISK_BT"
          drivedb[i, "status"] = "BT"
          drivedb[i, "staticon"] = constant["ICON_BT"];
          drivedb[drivedb[i, "serial"]] = i;  #allows indexed access to drive by serial number
          drivedb[drivedb[i, "dev"]] = i; #allows indexed access to a drive by disk name
          drivedb[device[a]] = i; #allows indexed access to a drive by disk name
       } else if ( (substr(device[a],1,2) != "md") && (assigned[a] == "") && (device[a] ~ "[a-z]+1" )) {
          i=drivedb["count"]++;
          drivedb[i, "num"]    = i;
          drivedb[i, "dev"]    = substr(device[a],1,3);

          if(drivedb[i, "dev"] == highlightdev)
             drivedb[i, "rowextra"] = drivedb[i, "rowextra"] "background: " highlightcolor; 

          #drivedb[i, "name"]   = "staging";
          drivedb[i, "md"]     = device[a] "1";
          drivedb[i, "role"]   = "non-array"; 
          drivedb[i, "fullid"] = model_serial[a];
          #drivedb[i, "serial"] = model_serial[a];
          #drivedb[i, "modelnum"]  = model_serial[a];
          delete ms
          k=split(model_serial[a], ms, "_");
          modela=""

          for(m=1; m<k; m++)
             modela=modela " " ms[m]

          drivedb[i, "serial"] = ms[k];
          drivedb[i, "modelnum"]  = substr(modela,2);
          GetDriveManufacturer(i)

          drivedb[i, "size"]   = -1; # need this?
          drivedb[i, "reads_raw"]  = other_reads[a];
          drivedb[i, "writes_raw"] = other_writes[a];
          drivedb[i, "reads"]  = CommaFormat(other_reads[a]);
          drivedb[i, "writes"] = CommaFormat(other_writes[a]);
          if(mounted[a] == "") {
             drivedb[i, "status_raw"] = "DISK_UN"
             drivedb[i, "status"] = "UN"
             drivedb[i, "disk"]   = "--"; 
          }
          else {
             drivedb[i, "status_raw"] = "DISK_MT"
             drivedb[i, "status"] = "MT"
             drivedb[i, "disk"]   = substr(mounted[a], 6)
             drivedb[i, "staticon"] = constant["ICON_MT"];
          }

          drivedb[drivedb[i, "serial"]] = i;  #allows indexed access to drive by serial number
          drivedb[drivedb[i, "dev"]] = i; #allows indexed access to a drive by disk name
          drivedb[drivedb[i, "dev"]"1"] = i; #allows indexed access to a drive by disk name
       }
    }

    outstr = ""
    outstr = outstr "<fieldset style=\"margin-top:5px;\">"
    outstr = outstr "<table width=\"100%\" cellpadding=2 cellspacing=4 border=0>"
    outstr = outstr bootdrive
    if ( cachedrive != "" ) {
        outstr = outstr cachedrive
    }
    if ( unassigned_drive != "" ) {
        outstr = outstr unassigned_drive
    }

    outstr = outstr "</table></fieldset>"
    return outstr
}


#----------------------------------------------------------------------------
# Gets and sets the disk temp value in the drivedb[] array. It also sets 
# the "extra" values to change the color of cells.  That's why it does the 
# setting instead of just returning a value.  THe "div" style coloration 
# used in unmenu.awk doesn't work too well with the gridded presentation (the 
# color does not fill the entire cell).  If a drive hits the orange or red 
# levels, it changes the color of the entire line.  Hopefully that should 
# get someone's attention. 
# .... uses view[], ColorHtml[], yellow_temp, orange_temp, red_temp, blue_temp
#----------------------------------------------------------------------------
function GetDiskTemps(smart_already_run, cmd, a, ix, ix2, lst, t, dev) {

    RS="\n"

    if(smart_already_run == "1") {
       for(ix=0; ix<drivedb["count"]; ix++)
          if(drivedb[ix, "disk"] != "flash") {
             if(drivedb[ix, "temperature_celsius"] == "") # smart not run on this drive
                drivedb[ix, "tempc"]="*";
             else {                          # is spinning
                delete t
                split(drivedb[ix, "temperature_celsius"], t);
                drivedb[ix, "tempc"] = t[1] "C";
             }
          }
    }
    else 
       for(ix=0; ix<drivedb["count"]; ix++)
          if(drivedb[ix, "disk"] != "flash") {
             GetDiskSpinState( "/dev/" drivedb[ix, "dev"] )
             if((drivedb[ix, "spinind"] == 0) && (drivedb[ix, "smart_nospinup"] != "1")) # not spinning
                drivedb[ix, "tempc"]="*";
             else {                          # is spinning
                #-----------------------------------------------------
                # Skip smartdrv to get actual temperature if selected 
                #-----------------------------------------------------
                if( view[activeview, "tempdata"] == "0" ) {
                   drivedb[ix, "tempc"] = "unk"
                }
                else {
                   cmd = "smartctl -d ata -A /dev/" drivedb[ix, "dev"] "| grep -i '^194'" 
                   #perr("cmd")
                   while ((cmd | getline a) > 0 ) {
                       delete t;
                       split(a,t," ")
                       #the_temp = t[10] "&deg;C"
                       if(drivedb[ix, "temperature_celsius_delta"] != 0) {
                          t[10] = t[10] + drivedb[ix, "temperature_celsius_delta"] 
                          #@@@ allow this to be done through config
                          drivedb[ix, "tempcextra"] = \
                             drivedb[ix, ix2 "_tempextra"] = drivedb[ix, "tempcextra"] ColorHtml[color="override"]; 
                       }
                       drivedb[ix, "tempc"] = t[10] "C"

                       if ( t[10] >= yellow_temp && t[10] < orange_temp )
                          drivedb[ix, ix2 "_tempextra"] = \
                             drivedb[ix, "tempcextra"] = drivedb[ix, "tempcextra"] ColorHtml[color="yellow"]; 
                       else if ( t[10] >= orange_temp && t[10] < red_temp )
                          drivedb[ix, "rowextra"] = \
                             drivedb[ix, ix2 "_tempextra"] = \
                                drivedb[ix, "tempcextra"] = drivedb[ix, "tempcextra"] ColorHtml[color="orange"]; 
                       else if ( t[10] >= red_temp )
                          drivedb[ix, "rowextra"] = \
                             drivedb[ix, ix2 "_tempextra"] = \
                                drivedb[ix, "tempcextra"] = drivedb[ix, "tempcextra"] ColorHtml[color="red"]; 
                       else if ( t[10] <= blue_temp )
                          drivedb[ix, ix2 "_tempextra"] = \
                             drivedb[ix, "tempcextra"] = drivedb[ix, "tempcextra"] ColorHtml[color="blue"]; 
                   }
                   close(cmd);
                }
             }
          }
    #perr("stop temp")
}

function GetDiskSpinState(lst, cmd, ix, a) {
   if(lst == "") # allows a list to be passed in to update only specific drives
      for(ix=0; ix<drivedb["count"]; ix++)
         if(drivedb[ix, "role"] != "boot")  # 1.3
            lst=lst " " "/dev/" drivedb[ix, "dev"];

   cmd = "hdparm -C" lst" 2>/dev/null" 
   #perr("cmd='" cmd "'")

   while ((cmd | getline a) > 0 ) {
      #perr("in there - " a);
      if (substr(a, 1, 4) == "/dev") {
         dev=substr(a, 6, 3)
         #perr("dev=" dev);
         ix=drivedb[dev];
         if(ix == "")
            p("ERROR:  DRIVE " dev " NOT FOUND");
      }
      else if ( a ~ "standby" ) {
         drivedb[ix, "spinstat"] = constant["NospinHtml"];
         drivedb[ix, "spinind"] = 0;
      }
      else if(a ~ "active") { 
         drivedb[ix, "spinstat"] = constant["SpinHtml"];
         drivedb[ix, "spinind"] = 1;
      }
   }
   close(cmd);
}


#---------------------------------------------------------------------------
# Use the "df" command to determine disk space for all formatted disks 
# (everything but parity goes through this).  Borrowed heavily from JoeL.'s 
# GetDiskFreeSpace() function. 
#---------------------------------------------------------------------------
function LoadDiskSpaceInfo(thousand, a, cmd, totalmult, devsplit, i, free) {
    if(thousand == "")
       thousand = 1000;
    else
       thousand = thousand+0; #coerce to number

    RS="\n"
    
    cmd="df --block-size=" thousand

    #--------------------------------------------------------------------
    # Disk size for array drives (including the total) is handled above.  
    # This function sets disk_size only for non-array disks. 
    #--------------------------------------------------------------------
    #drivedb["total", "disk_size_raw"] = 0
    drivedb["total", "disk_used_raw"] = 0
    drivedb["total", "disk_free_raw"] = 0
    drivedb["total", "disk_used"]     = 0
    drivedb["total", "disk_free"]     = 0

    while (( cmd | getline a) > 0 ) {
        if ( a ~ "/dev/" ) {
            #Only count array disks in total count
            if(a ~ "/dev/md")
               totalmult=1;
            else
               totalmult=0;

            delete free;
            delete devsplit
            split(a,free," ");
            split(free[1],devsplit,"/");
            #print "<p> devsplit[3] = " devsplit[3] "</p>"
            i = drivedb[devsplit[3]];

            if (i > 0) {
               if(i >= drivedb["uncount"]) { 
                  drivedb[i, "disk_size_raw"]    = free[2];
                  #drivedb[i, "disk_size_raw"]   = sprintf("%.1f", free[2]/10000000) * 10000000;
                  drivedb[i, "disk_size"]    = human_readable_number(drivedb[i, "disk_size_raw"], 0, 0, 0, 1);
                  if(drivedb[i, "disk_size"] == "1.0T")
                     drivedb[i, "disk_size"] = "1T"
               }

               drivedb[i, "disk_used_raw"]    = free[3];
               drivedb[i, "disk_free_raw"]    = free[4];
               drivedb[i, "disk_pctused_raw"] = substr(free[5], 1, length(free[5])-1) + 0 ;
               drivedb[i, "disk_mounted"]     = free[6];

               drivedb[i, "disk_used"]    = human_readable_number(drivedb[i, "disk_used_raw"], 0, 0, 0, 2);
               drivedb[i, "disk_free"]    = human_readable_number(drivedb[i, "disk_free_raw"], 0, 0, 0, 2); 
               #print "<p>"drivedb[i, "disk_size"]"</p>" 

               #drivedb["total", "disk_size_raw"]  += totalmult*drivedb[i, "disk_size_raw"] 
               drivedb["total", "disk_used_raw"]  += totalmult*drivedb[i, "disk_used_raw"]
               drivedb["total", "disk_free_raw"]  += totalmult*drivedb[i, "disk_free_raw"]


               if((free[4] < 1500000) && (free[2] > 20000000))  {
                  drivedb[i, "disk_pctused"] = "Full"; 
                  #drivedb[i, "disk_used"]    = "Full";
                  #drivedb[i, "disk_free"]    = "Full";
                  drivedb[i, "disk_pctusedextra"] = drivedb[i, "disk_pctusedextra"] FullColorHtml;
                  #drivedb[i, "disk_availextra"]   = FullColor; # #d0d0d0"; 
                  #drivedb[i, "disk_freeextra"]    = FullColor; # #d0d0d0"; 

                  drivedb["total", "disk_used"]  += totalmult * drivedb[i, "disk_used_raw"];
                  drivedb["total", "disk_free"]  += totalmult * drivedb[i, "disk_free_raw"]; #0
               }
               else if((free[3] < 50000) && (free[2] > 20000000)) {
                  drivedb[i, "disk_pctused"] = "Empty"; 
                  #drivedb[i, "disk_used"]    = "Empty";
                  #drivedb[i, "disk_free"]    = "Empty";

                  drivedb[i, "disk_pctusedextra"] = drivedb[i, "disk_pctusedextra"] EmptyColorHtml; # #FFFF99"; 
                  #drivedb[i, "disk_availextra"]   = EmptyColor; # #FFFF99";
                  #drivedb[i, "disk_freeextra"]    = EmptyColor; # #FFFF99";

                  drivedb["total", "disk_used"]  += totalmult * drivedb[i, "disk_used_raw"];
                  drivedb["total", "disk_free"]  += totalmult * drivedb[i, "disk_free_raw"];
               }
               else {
                  drivedb[i, "disk_pctused"] = drivedb[i, "disk_pctused_raw"] "%"; 

                  drivedb["total", "disk_used"]  += totalmult*drivedb[i, "disk_used_raw"];
                  drivedb["total", "disk_free"]  += totalmult*drivedb[i, "disk_free_raw"];
               }
            }
            else print "<p>Couldn't find drivedb[" devsplit[3] "]</p>"
        }
    }

    if(drivedb["total", "disk_used"] > 0) {
       drivedb["total", "disk_pctused"] = sprintf("%.1f", drivedb["total", "disk_used"] / drivedb["total", "disk_size_raw"] * 100) "%"
       drivedb["total", "disk_used"]   = human_readable_number(drivedb["total", "disk_used"], 0, 0, 0, 2);
       drivedb["total", "disk_free"]   = human_readable_number(drivedb["total", "disk_free"], 0, 0, 0, 2); 
       #drivedb["total", "disk_size"]   = human_readable_number(drivedb["total", "disk_size_raw"], 0, 0, 0, 2); 
    }
    else {
       drivedb["total", "disk_pctused"] = "";
       drivedb["total", "disk_used"]   = "";
       drivedb["total", "disk_free"]   = "";
       #drivedb["total", "disk_size"]   = human_readable_number(drivedb["total", "disk_size_raw"], 0, 0, 0, 2); 
    }

    close(cmd)
}

#--------------------------------------------
# Function to spin up all the disks quickly. 
#--------------------------------------------
function SpinUpAll(cmd, ix, disk_blocks, skip_blocks, spunupdrives)
{
   spunupdrives=0;

   for(ix=0; ix<drivedb["count"]; ix++)
      if(drivedb[ix, "spinind"] == 0) {
         if(spunupdrives >= 8) {
            spunupdrives = 0;
            system("sleep 5");
         }
         disk_blocks = GetRawDiskBlocks( "/dev/" drivedb[ix, "dev"] )
         disk_blocks = disk_blocks - 128 # skip the first cylinder
         #perr(dev " disk blocks = " disk_blocks);
         skip_blocks = 1 + int( rand() * disk_blocks );
         cmd="/root/mdcmd spinup " ix " > /dev/null 2>&1"
         system(cmd);
         cmd="nohup dd if=/dev/" drivedb[ix, "dev"] " of=/dev/null count=1 bs=1k skip=" skip_blocks " >/dev/null 2>&1 &"
         system(cmd);
         close(cmd);
         spunupdrives++;
         drivedb[ix, "spinind"] = 1
      }
}


#--------------------------------------------------------------------------------
# Function to quickly spin up drives that need to be spun up for smart purposes. 
#--------------------------------------------------------------------------------
function SpinUpSmart(cmd, ix, disk_blocks, skip_blocks, spunupdrives)
{
   spunupdrives=0;

   for(ix=0; ix<drivedb["count"]; ix++)
      if((drivedb[ix, "spinind"] == 0) && (drivedb[ix, "smart_nospinup"] == 0)) {
         if(spunupdrives >= 8) {
            spunupdrives = 0;
            system("sleep 5");
         }
         disk_blocks = GetRawDiskBlocks( "/dev/" drivedb[ix, "dev"] )
         disk_blocks = disk_blocks - 128 # skip the first cylinder
         #perr(dev " disk blocks = " disk_blocks);
         skip_blocks = 1 + int( rand() * disk_blocks );
         cmd="/root/mdcmd spinup " ix " > /dev/null 2>&1"
         system(cmd);
         cmd="nohup dd if=/dev/" drivedb[ix, "dev"] " of=/dev/null count=1 bs=1k skip=" skip_blocks " >/dev/null 2>&1 &"
         system(cmd);
         close(cmd);
         spunupdrives++;
         drivedb[ix, "spinind"] = 1
      }

   close(cmd)
}

function CollectSmartHistory()
{
   system(constant["smartctlhistorycmd"] " " constant["smarturfolder"]">/dev/null 2>&1");
}

function DateTimeStringFromFileName(fname, dt, tm, mn)
{
   dt=fname;  $ can really be most any string ending with "smart_yyyymmdd_hhmn.txt"

   gsub(".*smart_", "", dt);
   tm=substr(dt,10,2)+0;
   mn=substr(dt,12,2);
   #perr("mn=" mn)
   if(tm == 0)
      tm="12:" mn "am"
   else if(tm<12)
      tm=tm":"mn "am"
   else if(tm==12)
      tm="12:" mn "pm"
   else
      tm=tm-12 ":" mn "pm"

   dt=substr(dt,5,2) "/" substr(dt,7,2) "/" substr(dt,3,2) " " tm
   if(substr(dt,4,1) == "0")
      dt=substr(dt,1,3) substr(dt,5)
   if(substr(dt,1,1) == "0")
      dt=substr(dt,2)

   return("<small>"dt"</small>")
}


function GetDeviceArray(lst, cmd, a, d) {
  # read from /proc/partitions
    RS="\n"
    cmd="cat /proc/partitions | grep -v '^major' | grep -v '^$' "
    devicearray["count"] = 0
    lst=""
    while ((cmd | getline a) > 0 ) {
        delete d;
        split(a,d," ");    
        #p(d[4])
        if((length(d[4]) == 3) && (d[4] !~ "md")) {
           devicearray[ devicearray["count"]++ ] = d[4];
           lst=lst " /dev/" d[4]
        }
    }
    #p(devicearray["count"])
    #for(i=0; i<devicearray["count"]; i++)
    #   p(devicearray[i])
    close(cmd)
    return(substr(lst,1));
}


function GetUnraidDeviceArray(cmd, a, d) {
  # read from /proc/partitions
    RS="\n"
    cmd="/root/mdcmd status | strings | grep 'rdevName'"
    deviceunraid["count"] = 0
    while ((cmd | getline a) > 0 ) {
        delete d;
        split(a,d,"=");    
        deviceunraid[ deviceunraid["count"]++ ] = d[2];
    }
    #p(deviceunraid["count"])
    #for(i=0; i<deviceunraid["count"]; i++)
    #   p(i "=" deviceunraid[i])
    close(cmd)
}

