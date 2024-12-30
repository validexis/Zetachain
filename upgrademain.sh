#!/bin/bash
cd $HOME
rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v24.0.0
make install

sudo systemctl restart zetacored && sudo journalctl -u zetacored -f
