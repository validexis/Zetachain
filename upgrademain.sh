#!/bin/bash
cd $HOME
wget -O $HOME/zetacored https://github.com/zeta-chain/node/releases/download/v29.1.2/zetacored-linux-amd64
chmod +x $HOME/zetacored 
sudo mv $HOME/zetacored $(which zetacored)
sudo systemctl restart zetacored && sudo journalctl -u zetacored -f
