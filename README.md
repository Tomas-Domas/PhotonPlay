# PhotonPlay
Galvonometer scanner display for retro games

## Vivado Instructions:
We'll be programming the the Pynq-Z2 board using Vivado, follow Dr Stitt's setup guide for Lab0:
http://www.gstitt.ece.ufl.edu/courses/fall24/eel4720_5721/labs/

I use Vivado 2021.1 and have had no issues but newer versions are probably also fine.

## Adding the Pnyq-Z2 board to Vivado:
Once Vivado is installed, you'll need to add the Pynq-Z2 board to your setup. You can follow the instructions here:
https://community.element14.com/technologies/fpga-group/b/blog/posts/add-pynq-z2-board-to-vivado

Create a board_files folder inside the boards directory if you don't already have one. To check if the process worked create a Vivado project and keep all the defults selected until you reach the Defualt Part screen. Select the boards tab and search Pynq-Z2. The board should appear like so:
<img width="1128" alt="image" src="https://github.com/user-attachments/assets/d882d82c-febf-4943-8087-2871b6dd0d15" />

## Port Mapping the board:
Port mapping boards are generally done using an .xdc file. Download the Master XDC file using the Tul website:
https://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html#:~:text=Z2%20Board%20File
<img width="1128" alt="image" src="https://github.com/user-attachments/assets/faa04d11-3dcd-4269-ad87-9c2fa9acbc70" />

Inside the extracted download you'll see a tcl and xdc file. The video below walks you through making an example project with the Pynq-Z2 board and how to use the tcl and xdc file to interface with it. 
