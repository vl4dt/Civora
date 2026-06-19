#!/usr/bin/env bash
set -o errexit

export MIX_ENV=prod

mix local.hex --force
mix local.rebar --force
mix deps.get --only prod
mix compile
mix assets.deploy
mix release --overwrite
