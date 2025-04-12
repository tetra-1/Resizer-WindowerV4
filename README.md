# Resizer
Resizer is an addon for the FFXI Windower v4 client which allows you to change your character's size, or height.

## Why Resizer?
When you created your character you were given the choice between three sizes: small, medium, and large. Up until now this choice has been permanent. Square has not implemented a 'fantasia' feature (yet), and no addon that I've found has supported modifying your appearance in this way. If you were like me and weren't satisfied with the height you chose all those months, years, or even decades ago, you just had to live with it. Resizer is my solution to this problem.

## Example
(I'll take some pictures later or something)

## Installation and Use
1) Make sure you're using the [Windower v4 client](https://www.windower.net/) and that it's installed and configured correctly.

2) Download the addon files from the releases page, or download the code directly.
3) Extract the files into your `Windower/addons` folder.
4) In game, open the console (Insert key by default) and type `lua load resizer`
5) Type 'resizer' and then the size you wish to be. Example: `resizer small`
6) Your new size won't be seen until your model is updated. Try changing zones, your equipment, or your job. (It might take a couple equipment swaps for the change to stick.)
7) After the first time you change your size, your character's model will be updated automatically on every zone transition and player update (equipment changes and job changes as far as I know). Settings are saved too, so you should only need to run the command once.
8) To make Windower load Resizer automatically on startup, add the `lua load resizer` command to the `Windower/scripts/init.txt` file.

## Commands
* __resizer__\
Displays the player's current size setting.

* __resizer help__\
Displays the addon's help information.
* __resizer (small | medium | large | s | m | l | 0 | 1 | 2)__\
Changes the player's character size to the chosen value.
* __resizer default__\
Returns the player's size to the server default.
* __resizer toggle_chat__ 
Toggles output to the game's chat window.
* __resizer use_chat (on | off)__
Turns output to the game's chat window on or off.

## Notes
* I'm a relatively new player with only a few months subscription time under my belt (only just reached rank 10 for my city state) so my knowledge of addons, game mechanics, etc. is limited. I have no idea if this addon will work in every scenario, only that it works while I run around Jeuno or kill lizards on the beach. Good luck :)

* The addon works by intercepting and modifying the 0x000A (zone update) and 0x0037 (player update) packets. No packet injection is involved.
* This should be compatible with other appearance addons, as long as they don't change the above packets for whatever reason. I only use DressUp though, so no guarantees.
* I couldn't make autoupdating the player's size work without packet injection, so you have to do it manually after every size change.
* As far as I know I'm the first person to find and modify the flags responsible for a player's size, so I have no idea if this will break anything long term. All I know is I've been using it for weeks without issues so that's good enough in my book.
* Currently this addon only changes your size and no one else's. If you notice anyone else's size changing, that's a bug.

## Credits/Thanks
* Tetra - I made this :)

* Windower development team - Without them the Windower client wouldn't exist and none of this would be possible

* Whoever made the [fields file](https://github.com/Windower/Lua/blob/dev/addons/libs/packets/fields.lua) in Windower's packets library - Wherever I saw an '_unknown', I knew that's where I should look for the size value

* atom0s - The Ashita example addons formed the framework of the original Ashita version (which this is a port of) and the [0x000A](https://github.com/atom0s/XiPackets/tree/024300c4ba710ad4417e442593d3626de42168b1/world/server/0x000A) and [0x0037](https://github.com/atom0s/XiPackets/tree/024300c4ba710ad4417e442593d3626de42168b1/world/server/0x0037) documentation was essential in narrowing down which packets were responsible for player appearance updates

* Square Enix - For making this funny game

## Links
[Resizer for Ashita v4](https://github.com/tetra-1/Resizer-AshitaV4)