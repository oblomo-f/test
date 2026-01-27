#!/bin/sh

# === OUTBOUND ===
podkop outbound add \
  --tag http-proxy \
  --type http \
  --server 127.0.0.1 \
  --port 18080


# === COMMUNITY LISTS ===
podkop ruleset add geoblock --type community --name Geoblock
podkop ruleset add block --type community --name Block
podkop ruleset add meta --type community --name Meta
podkop ruleset add twitter --type community --name Twitter
podkop ruleset add hdrezka --type community --name HDRezka
podkop ruleset add tiktok --type community --name Tik-tok
podkop ruleset add googleai --type community --name "Google AI"


# === CUSTOM DOMAIN LIST ===
podkop ruleset add custom-domains \
  --type domain-text \
  --domains \
    myip.com \
    amazonaws.com \
    whatsapp.com \
    whatsapp.net \
    whatsapp.biz \
    wa.me \
    whoer.net \
    2ip.io


# === ROUTING RULES ===
podkop rule add \
  --ruleset geoblock,block,meta,twitter,hdrezka,tiktok,googleai,custom-domains \
  --outbound http-proxy
