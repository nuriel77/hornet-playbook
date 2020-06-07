#!/bin/bash

rm /var/lib/grafana/dashboards/iota_exporter_dashboard.json
/bin/systemctl stop iota-prom-exporter || /bin/true
/bin/systemctl disable iota-prom-exporter || /bin/true
