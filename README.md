Codemaster-NES-homebrew
=======================

Codemaster is a homebrew game written for the Nintendo Entertainment System in 6502 assembly.

Building
--------

To build the game, build it with Asm6 (Available from http://www.romhacking.net/utilities/674/).  Navigate to the /Game/ execute the command 

    ASM6 CodeMaster_Main.asm ROM/CodeMaster.nes
    
The resultant .nes file can be found in the Game/ROM/ folder and run with any NES emulator

Playing the Game
----------------

The goal of the game is to guess a secret 4 symbol code consisting of any combination of 8 different symbols.  After selecting a code, the game will then indicate to the user how close the guess is to the actual code.  Four lights to the right of the guess will light up and indicate the status of the guess.  The color of a given light gives a clue as to what part of the guess is incorrect.  The meaning of the lights are as follows:

*A red light means that somewhere in the guess, there exists a symbol that is not part of the correct code.

*A yellow light means that somewhere in the guess, there exists a symbol that is part of the correct code, but is in the wrong position.

*A green light means that somewhere in the guess, there exists a symbol that is part of the correct code and it also in the correct position.

Note that the order of the lights says nothing about the symbols they refer to.  Just because the first light is green does not necessarily mean that the first symbol is correct.

The user has up to 10 chances to guess the correct code.  If the player has not succeeded in this time, the game will be over and the user will be presented with the correct code

Controls
--------

On the main game screen, pressing select will switch between 1 Player and 2 Player mode, and pressing start will choose the selected mode.  

If 1 Player mode is selected from the main screen, the player can choose the difficulty of the computer-generated code using the same controls as from the main screen.  The difference between normal and hard difficulty is that on normal difficulty, no symbol can appear in the correct code more than once.  In hard mode, a symbol may appear in the correct code any number of times.

If 2 Player mode is selected, the game will give player 2 the opportunity to secretly choose the code for player 1.  By pressing various button combinations on the second controller, player 2 can select any of the 8 symbols in any combination they desire.

Once the code has been set (either by a human or the computer), the game can begin.  Player 1's controller is used to control the game.  The player can cycle through the symbols by pressing up or down on the D-Pad, and can move through the various 4 positions in the code using the D-Pad's left and right buttons.  Once all four symbols have been seleced, pressing either A or Start on the 1st controller will submit the guess.  The computer will evaluate the guess and if it is wrong, the player will have the chance to try more guesses until there are no more.
