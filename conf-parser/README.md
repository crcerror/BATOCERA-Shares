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

- **file**

```
            Write here the file you want to process, the script will check file presence
            and will check write protection (to save values)
            
```

- **stat, status**

*Sample output 1*
```
# ./batoceraSettings.sh -command status -key wifi.key
ok: found '/userdata/system/batocera.conf'
ok: r/w file '/userdata/system/batocera.conf'
ok: 'wifi.key' new key
```

*Sample output2*
```
# ./batoceraSettings.sh -command status -key wifi.ssid
ok: found '/userdata/system/batocera.conf'
ok: r/w file '/userdata/system/batocera.conf'
error: 'wifi.ssid' is commented #!
error: 'wifi.ssid' not available
```

- **load, get, read**

           -command
              load, get, read: will read out given keyvalue
           
           -key
              set key you want to read from your config file the values are setted like
              key.name=value
              
              This will result in an output 'value'
              
- **save, set, write**

           -command
              save, set, write: will write keyvalue to setted key
           
           -key
              set key you want to write to your config file the values are setted like
              key.name=value
              
           -value
               Type here your value you want to set to key.name
               
            Attention: for save command, the file must be writeable and the key you want to set has
                       to be available. If the key is commented out then the save command will automatically 
                       activate for you. The key itself HAS TO BE be available.

- **uncomment**

- **comment**



- **exit codes**
 
           exit codes: exit 0  = value is available, proper exit
                       exit 1  = general error
                       exit 2  = file error
                       exit 11 = value found, but not activated
                       exit 12 = value not found 

## The need for speed?

```
Model Raspberry 3A+

1. Original script
# time python batoceraSettings.py.bak -command load -key wifi.key
2019-06-24 19:34:17 DEBUG (unixSettings.py:21):__init__(): Creating parser for /userdata/system/batocera.conf
2019-06-24 19:34:17 DEBUG (unixSettings.py:43):load(): Looking for wifi.key in /userdata/system/batocera.conf
new key
real    0m0.136s
user    0m0.107s
sys     0m0.029s

2. crcerrors fob python script (python interpreter is called, then arguments are parsed to bash script)
# time python batoceraSettings.py -command load -key wifi.key
new key

real    0m0.069s
user    0m0.057s
sys     0m0.013s
#


3. crcerrors bash script, arguments are directly parsed to script
# time bash batoceraSettings.sh -command load -key wifi.key
new key

real    0m0.018s
user    0m0.013s
sys     0m0.005s
#
```
