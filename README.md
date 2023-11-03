## UNISWAP-SILLY-POC

This is a silly POC that allows anyone to

- Swap ETHER for any ERC20 token
- Get Tokens Qoutes

The exchange is faciliated by Curve Finance, Uniswap and SushiSwap

I would encourage one to run the base file inorder to fork the mainnet off course please ensure you have a valid mainnet rpc url

## Installation

`yarn` or `npm i`

### Build

`yarn build` or `npm run build`

## Unit testing

`yarn test` or `npm run test`

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy
To deply locally 
```shell
yarn deploy:local::qouter   or npm run  deploy:local::qouter
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Note

**Unit tests that revert are not included**


## UI 
The is not optimised as this is a POC i also couldnt test the swap since not all the dexes are deployed on testnets 

## Starting

``yarn dev`` or ``npm run dev``