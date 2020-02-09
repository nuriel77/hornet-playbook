# Overview
See [kubernetes](https://github.com/nuriel77/hornet-playbook/blob/master/docs/kubernetes.md)

# Configure

1. Create this secret first as suggested here: https://github.com/nuriel77/hornet-playbook/blob/master/docs/kubernetes.md#prepare

2. Check and edit `values.yaml` as required.

# Install

Specify the correct repository and image tag or set those in the `values.yaml`:
```sh
helm install --namespace hornet --name hornet --set="image.repository=localhost:32000/gohornet/hornet" --set image.tag="v0.2.9" ./
```
