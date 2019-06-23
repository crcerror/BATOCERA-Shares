# BATOCERA config parser

## Usage

### Usage of BASE COMMAND:

           ./batoceraSettings.sh <file> -command <cmd> -key <key> -value <value>

           -command    load write enable disable status
           -key        any key in batocera.conf (kodi.enabled...)
           -value      any alphanumerical string
                       use quotation marks to avoid globbing

           For write command -value <value> must be provided

           If you don't set a filename then default is 'userdata/system/batocera.conf'
           The file must be set to writeable so that write commands work
 
 
 ### Usage of ADVANCED COMMANDS

**file**

```
            Write here the file you want to process, the script will check file presence
            and will check write protection (to save values)
            
```

**stat, status**

Sample output 1
```
# ./batoceraSettings.sh -command status -key wifi.key
ok: found '/userdata/system/batocera.conf'
ok: r/w file '/userdata/system/batocera.conf'
ok: 'wifi.key' new key
```

Sample output2
```
# ./batoceraSettings.sh -command status -key wifi.ssid
ok: found '/userdata/system/batocera.conf'
ok: r/w file '/userdata/system/batocera.conf'
error: 'wifi.ssid' is commented #!
error: 'wifi.ssid' not available
```

**load, get, read**

           -command
              load, get, read: will read out given keyvalue
           
           -key
              set key you want to read from your config file the values are setted like
              key.name=value
              
              This will result in an output 'value'
              
**save, set, write**

           -command
              save, set, write: will write keyvalue to setted key
           
           -key
              set key you want to write to your config file the values are setted like
              key.name=value
              
           -value
               Type here your value you want to set to key.name
               
            Attention: for save command, the file must be writeable and the key you want to set must be available
                       If the key is commented out then the save command will automatically activate for you.
                       The key itself MUST be available.

**uncomment**

**comment**



**exit codes**
 
           exit codes: exit 0  = value is available, proper exit
                       exit 1  = general error
                       exit 2  = file error
                       exit 11 = value found, but not activated
                       exit 12 = value not found 
