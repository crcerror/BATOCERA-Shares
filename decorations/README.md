# How to

Place scripts `resize.sh` and `masslist.sh` directly into decorations folder you want to process.

For example: \
You want to create a default decorations for a RPi 7" DSI touch panel.
1. copy the two script files to `~/decorations/default`
2. make the scripts executable with `chmod +x`
3. start the script `./masslist.sh`
4. info files will be processed and a directory `resize` is created with links to the png files
5. Now move the Resize folder with command `mv resize ../default-7inch-DSI`
6. Activate Decorations folder

You can open `masslist.sh` to setup resize factor and renaming/linking of files`
