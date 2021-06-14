#!/usr/bin/env bash
set -e

read -p "Installing new Hornet dashboard for Grafana. Please press ENTER to continue ..."
run-playbook --tags=install_hornet_dashboard
