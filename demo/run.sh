#!/bin/sh

mix compile && iex --erl "-proto_dist dnssd -start_epmd false -epmd_module dnssd_epmd_stub -pa _build/host/dev/lib/nerves_dnssd_demo/ebin" --sname demo$RANDOM --cookie demo -S mix
