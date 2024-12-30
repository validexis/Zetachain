#!/bin/bash
apt update && apt upgrade -y
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
wget -O $HOME/zetacored https://github.com/zeta-chain/node/releases/download/v24.0.0/zetacored-linux-amd64
chmod +x $HOME/zetacored 
mv $HOME/zetacored $HOME/go/bin
​make install

zetacored init test --chain-id=zetachain_7000-1
zetacored config chain-id zetachain_7000-1

wget -O $HOME/.zetacored/config/genesis.json https://server-2.itrocket.net/mainnet/zetachain/genesis.json
wget -O $HOME/.zetacored/config/addrbook.json  https://server-2.itrocket.net/mainnet/zetachain/addrbook.json

SEEDS="4e668be2d80d3475d2350e313bc75b8f0646884f@zetachain-mainnet-seed.itrocket.net:39656"
PEERS="372e9c80f723491daf2b05b3aa368865f6bc3492@zetachain-mainnet-peer.itrocket.net:39656,d56a65e856443cf97fab922580de21cb234de51f@34.66.19.0:26656,eb1441901c7008d180edd0853af9bd8148c95a94@162.55.96.250:26656,e0b89511a7a31d7867c00cfba748b474f853ac49@148.251.140.252:26656,35e621bf11455cee613833243f268a1ba83aabb5@64.176.47.152:26656,77a26a60e44730311d05b2b653031badb52d493d@64.176.57.149:26656,d98525ae59a00f7a099ddaec2a7e416e818bb210@15.235.115.91:26656,c0ce318fcc98e89ce906bfba0f68df5a3774652d@65.108.197.253:21850,506f82713cc3a95b8f28e89930c047daa47db74e@64.176.57.214:26656,927860d6e888a5dee988cceed734e9dad0b569bc@176.9.137.150:26656,55947af1b1db1192b649563a01fa69f0b5d6ee03@142.132.198.157:26656,5e8e37464dcc2d9dd21b04a2c45b9ae1361eaa59@5.9.108.22:26656,cd48a06521de9f97e6413fec1188ffabb7069b19@5.9.106.71:21850,6d8296e6222eb992ff4814d950ed30630f924253@45.76.180.32:26656,d8730c76daaf371900159ab8c6e00bc3950eff79@64.176.39.37:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.zetacored/config/config.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0azeta"|g' $HOME/.zetacored/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.zetacored/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.zetacored/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.zetacored/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.zetacored/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.zetacored/config/app.toml
​
CUSTOM_PORT=161
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CUSTOM_PORT}58\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${CUSTOM_PORT}57\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CUSTOM_PORT}60\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CUSTOM_PORT}56\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CUSTOM_PORT}66\"%" $HOME/.zetacored/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://localhost:${CUSTOM_PORT}17\"%; s%^address = \":8080\"%address = \":${CUSTOM_PORT}80\"%; s%^address = \"localhost:9090\"%address = \"localhost:${CUSTOM_PORT}90\"%; s%^address = \"localhost:9091\"%address = \"localhost:${CUSTOM_PORT}91\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${CUSTOM_PORT}45\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${CUSTOM_PORT}46\"%" $HOME/.zetacored/config/app.toml​

zetacored config node tcp://localhost:${CUSTOM_PORT}57


sudo tee /etc/systemd/system/zetacored.service > /dev/null <<EOF
​[Unit]
Description=Zetachain node
After=network-online.target
​
[Service]
User=$USER
WorkingDirectory=$HOME/.zetacored
ExecStart=$(which zetacored) start --home $HOME/.zetacored
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
​
WantedBy=multi-user.target
EOF

zetacored tendermint unsafe-reset-all --home $HOME/.zetacored
if curl -s --head curl https://server-2.itrocket.net/mainnet/zetachain/zetachain_2024-12-30_6376912_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-2.itrocket.net/mainnet/zetachain/zetachain_2024-12-30_6376912_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.zetacored
    else
  echo "no snapshot found"
fi

sudo systemctl daemon-reload
sudo systemctl enable zetacored
sudo systemctl restart zetacored && sudo journalctl -u zetacored -fo cat
