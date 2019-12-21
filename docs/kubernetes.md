# Kubernetes (WIP)

Example:

![k8s_cluster](https://raw.githubusercontent.com/nuriel77/hornet-playbook/master/docs/images/k8s_hornet.png)

# Introduction

Here you will find a template to run a Hornet node on a kubernetes clusters.

Note: There's a helm chart available [here](../contrib/charts/hornet)

A few things to take into account:

- This configuration uses NodePort. Another alternative is hostNetwork but this will not work well on a real cluster.
- There is no configuration yet for persistent storage, therefore a restart of the pod will start with empty DB.
- The peering port in the config.json must match the NodePort, else other nodes will get a conflict in between what is advertised by the k8s hornet node and the port with which it was added.
- At time of writing there is still no official hornet Docker image. You will have to clone the repository and build the docker image yourself and push it to a registry accessible to your kubernetes cluster (e.g. Dockerhub or an internal registry).

## config.json

```json
{
  "useProfile": "2gb",
  "profiles": {
    "custom": {
      "caches": {
        "requestQueue": {
          "size": 100000
        },
        "approvers": {
          "size": 100000,
          "evictionSize": 1000
        },
        "bundles": {
          "size": 20000,
          "evictionSize": 1000
        },
        "milestones": {
          "size": 1000,
          "evictionSize": 100
        },
        "spentAddresses": {
          "size": 5000,
          "evictionSize": 1000
        },
        "transactions": {
          "size": 50000,
          "evictionSize": 1000
        },
        "incomingTransactionFilter": {
          "size": 5000
        },
        "refsInvalidBundle": {
          "size": 10000
        }
      },
      "badger": {
        "levelOneSize": 268435456,
        "levelSizeMultiplier": 10,
        "tableLoadingMode": 2,
        "valueLogLoadingMode": 2,
        "maxLevels": 7,
        "maxTableSize": 67108864,
        "numCompactors": 2,
        "numLevelZeroTables": 5,
        "numLevelZeroTablesStall": 10,
        "numMemtables": 5,
        "bloomFalsePositive": 0.01,
        "blockSize": 4096,
        "syncWrites": false,
        "numVersionsToKeep": 1,
        "compactLevel0OnClose": false,
        "keepL0InMemory": false,
        "verifyValueChecksum": false,
        "maxCacheSize": 50000000,
        "ZSTDCompressionLevel": 10,
        "valueLogFileSize": 1073741823,
        "valueLogMaxEntries": 1000000,
        "valueThreshold": 32,
        "withTruncate": false,
        "logRotatesToFlush": 2,
        "eventLogging": false
      }
    }
  },
  "api": {
    "auth": {
      "password": "",
      "username": ""
    },
    "permitRemoteAccess": [
      "getNodeInfo",
      "getNeighbors",
      "getBalances",
      "checkConsistency",
      "getTransactionsToApprove",
      "getInclusionStates",
      "getNodeAPIConfiguration",
      "wereAddressesSpentFrom",
      "broadcastTransactions",
      "findTransactions",
      "storeTransactions",
      "getTrytes"
    ],
    "host": "0.0.0.0",
    "maxbodylength": 1000000,
    "maxfindtransactions": 100000,
    "maxgettrytes": 1000,
    "maxrequestslist": 1000,
    "port": 14265,
    "remoteauth": ""
  },
  "compass": {
    "loadLSMIAsLMI": false
  },
  "dashboard": {
    "host": "0.0.0.0",
    "port": 8081,
    "dev": false,
    "basic_auth": {
      "enabled": false,
      "username": "hornet",
      "password": "hornet"
    }
  },
  "db": {
    "path": "mainnetdb"
  },
  "localsnapshots": {
    "path": "latest-export.gz.bin"
  },
  "milestones": {
    "coordinator": "EQSAUZXULTTYZCLNJNTXQTQHOMOFZERHTCGTXOLTVAHKSA9OGAZDEKECURBRIXIJWNPFCQIOVFVVXJVD9",
    "coordinatorsecuritylevel": 2,
    "numberofkeysinamilestone": 23
  },
  "monitor": {
    "tanglemonitorpath": "tanglemonitor/frontend",
    "domain": "",
    "host": "0.0.0.0",
    "port": 4434,
    "apiPort": 4433
  },
  "network": {
    "address": "0.0.0.0",
    "autotetheringenabled": false,
    "preferIPv6": false,
    "maxneighbors": 5,
    "neighbors": [
      {
        "identity": "xxxxx.io:15600",
        "preferIPv6": false
      },
      {
        "identity": "zzzzz.io:15600",
        "preferIPv6": false
      }
    ],
    "port": 31200,
    "reconnectattemptintervalseconds": 60
  },
  "node": {
    "disableplugins": [],
    "enableplugins": [],
    "loglevel": 127
  },
  "protocol": {
    "mwm": 14
  },
  "spammer": {
    "address": "HORNET99INTEGRATED99SPAMMER999999999999999999999999999999999999999999999999999999",
    "depth": 3,
    "message": "Spamming with HORNET tipselect",
    "tag": "HORNET99INTEGRATED99SPAMMER",
    "tpsratelimit": 0.1,
    "workers": 1
  },
  "tipsel": {
    "belowmaxdepthtransactionlimit": 20000,
    "maxdepth": 15
  },
  "zmq": {
    "host": "0.0.0.0",
    "port": 5556
  }
}
```

## Kubernetes YAML Spec

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hornet
  namespace: hornet
  labels:
    app: hornet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hornet
  template:
    metadata:
      labels:
        app: hornet
    spec:
      terminationGracePeriodSeconds: 240
      hostNetwork: false
      containers:
      - name: hornet
        image: "localhost:32000/gohornet/hornet:v0.2.9"
        ports:
          - name: dashboard
            protocol: TCP
            containerPort: 8081
          - name: api
            protocol: TCP
            containerPort: 14265
          - name: peering
            protocol: TCP
            containerPort: 31200
        command:
          - "/bin/sh"
          - "-ec"
          - |
            cp -- /app/config/config.json /app/config.json
            wget -O /app/latest-export.gz.bin https://dbfiles.iota.org/mainnet/hornet/latest-export.gz.bin
            exec /tini -s -- /app/hornet -c config
        volumeMounts:
        - name: mainnetdb
          mountPath: "/app/mainnetdb"
        - name: mainconfig
          mountPath: "/app/config"
      volumes:
      - name: mainnetdb
        emptyDir: {}
      - name: mainconfig
        secret:
          secretName: hornet-config
---
kind: Service
apiVersion: v1
metadata:
  name: hornet-service
  namespace: hornet
spec:
  selector:
    app: hornet
  ports:
    - protocol: TCP
      port: 14265
      nodePort: 31115
      name: api
    - protocol: TCP
      port: 8081
      nodePort: 31111
      name: dashboard
    - protocol: TCP
      port: 31200
      nodePort: 31200
      name: peering
  type: NodePort
```

## Prepare

1. First create a namespace `hornet` (not necessarity, you can use `default` but makes sure to edit above yaml examples).
```sh
kubectl create namespace hornet
```

2. Create the configuration secret by creating a file `config.json` with the configuration json from above. As this may contain passwords we put it in a k8s secret:
```sh
kubectl create secret --namespace hornet generic hornet-config --from-file=./config.json --dry-run -o yaml | kubectl apply -f -
```
Note that we use the above command (--dry-run and apply) so that it is easier to configure the secret and reload/replace it when it was already created.

## Install

Paste the above `yaml` spec into a file `hornet.yml` and configure for your needs. Apply the deployment and service:
```sh
kubectl apply -f hornet.yml
```

## Check

Check logs (you need to get the pod's name via `kubectl get pod -n hornet`):
```sh
kubectl logs -n hornet hornet-xxxxxxxx-xxxxx -f
```

## Changes to config

If you make any changes to `config.json` you can use the command you've used to create the secret in order to update it.
You will also have to delete the existing pod in order for it to pick up the new changes.

## Get Neighbors

You might have to allow getNeighbors in the `config.json`, else you need to run the command from within the pod (it doesn't have curl so you'll have to build an image with curl in it).

```sh
curl  http://127.0.0.1:31115 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command":"getNeighbors"}'
```
