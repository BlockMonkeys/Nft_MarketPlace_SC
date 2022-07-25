# LazyMinting NFT Marketplace Splint 1

## Dapp Demo 기본 정보

Web Demo URL : https://nft.monstercoders.io (메타마스크 설치 필요)

Goerli Test Network : https://goerli.etherscan.io/address/0x5a5eb29B037fA4b56D121e2E73D642d544B5Dce6#code

Contract (Verified) : https://goerli.etherscan.io/address/0x5a5eb29B037fA4b56D121e2E73D642d544B5Dce6#code


## Summary
```
블록체인 Dapp을 활용하기 위해서 소비자는 가스 비용을 지불해야 한다는 점이 가장 큰 장애물이 아닐까 생각한다. 본 프로젝트에서는 블록체인에서 핵심적인 기술 중 하나인 NFT(ERC-721)에 대하여 Lazy Minting 기술을 직접 구현해봄으로써 Lazy Minting Flow에 대한 이해를 목적으로 한다. NFT를 발행하는 Creator는 NFT를 발행하는데 비용이 소모되지 않는다. 서명만이 필요하다 (실제로 NFT Minting이 이루어지지 않으나 IPFS 상의 데이터는 올린다). 이후 Buyer가 나타나면 DB에 저장된 서명값을 통해 NFT를 Creator의 이름으로 민팅하고 Redeemer가 NFT를 전달받는 구조로 이루어진다. 또한 한번 사용된 서명을 재사용하는 것을 방지하기위해 Smart Contract영역에서 mapping Data를 통해 관리한다. 사이트 운영자가 악의적 사용자로 동일한 NFT를 DB에 저장된 Signature를 활용해 수차례 민팅이 불가능하다. 또한 Title, Description, IPFS URL, Price를 모두 묶어 msg Hash를 만들었으므로 어떠한 정보도 변조될 경우 민팅 자체가 불가능하므로 Off-chain영역에서 발생할 수 있는 오라클 문제에 대하여 문제가 발생할 수 있는 부분을 최소화 했다.
```


## Construction Skills
- Ethereum Goerli Test Network
- IPFS(nft.storage) - 분산형 파일저장 시스템으로 nft.storage를 사용했다.
- Solidity (8.15) - Smart Contract 개발언어로 8.15 최신버전을 사용했다.
- Hardhat & Ethers - Contract 개발 및 테스트 툴로 사용했다. (최근 Truffle, web3.js에 비해 점유율이 다소 높아져 본 프로젝트에서 채택)
- Openzeppelin - Smart Contract Library
- Javascript & React - Client Side
- Nodejs(Express) - Server Side
- MongoDB - NoSQL DB



## Application Architecture
![NFT](https://user-images.githubusercontent.com/66409384/180760130-0d272d18-8284-4d84-b6e5-08c269618646.png)


## Contract 구성
```
컨트렉트 내에는 기본적으로 Lazyminting, Minting, Set Locking, Minting Price Adjust, Emergency Withdrawal 등 의 기능을 포함하고 테스트코드에서 확인이 가능하다.

```

![contract_Graph](https://user-images.githubusercontent.com/66409384/180267157-85d0bf2e-2cb6-48ef-bbd7-0e88bf1238fe.svg)
