#!/bin/bash
apt update && apt upgrade -y
sudo apt install -y curl git jq lz4 build-essential

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.22.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf node
git clone https://github.com/zeta-chain/node
cd node
git checkout v24.0.0

make install

zetacored init NODE --chain-id=zetachain_7000-1
zetacored config chain-id zetachain_7000-1

curl -L https://snapshots.nodejumper.io/zetachain/genesis.json > $HOME/.zetacored/config/genesis.json
curl -L https://snapshots.nodejumper.io/zetachain/addrbook.json > $HOME/.zetacored/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22556,1d41d344d3370d2ba54332de4967baa5cbd70a06@rpc.zetachain.nodestake.org:666,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@seeds.polkachu.com:22556,8d93468c6022fb3b263963bdea46b0a131d247cd@34.28.196.79:26656,637077d431f618181597706810a65c826524fd74@zetachain.rpc.nodeshub.online:22556,11b86546b092e0645a91b32ca78e40c8bec54546@zetachain-m.peer.stavr.tech:17656"|' $HOME/.zetacored/config/config.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "20000000000azeta"|' $HOME/.zetacored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zetacored/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zetacored/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.zetacored/config/app.toml
​
CUSTOM_PORT=161

sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CUSTOM_PORT}58\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${CUSTOM_PORT}57\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CUSTOM_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CUSTOM_PORT}56\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CUSTOM_PORT}66\"%" $HOME/.zetacored/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://localhost:${CUSTOM_PORT}17\"%; s%^address = \":8080\"%address = \":${CUSTOM_PORT}80\"%; s%^address = \"localhost:9090\"%address = \"localhost:${CUSTOM_PORT}90\"%; s%^address = \"localhost:9091\"%address = \"localhost:${CUSTOM_PORT}91\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CUSTOM_PORT}45\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CUSTOM_PORT}46\"%" $HOME/.zetacored/config/app.toml

zetacored config node tcp://localhost:${CUSTOM_PORT}57

sudo tee /etc/systemd/system/zetacored.service > /dev/null <<EOF
[Unit]
Description=Zetachain node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.zetacored
ExecStart=$(which zetacored) start --home $HOME/.zetacored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

curl "https://snapshots.nodejumper.io/zetachain/zetachain_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.zetacored"

sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl restart zetacored && sudo journalctl -u zetacored -fo cat
