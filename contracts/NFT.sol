// SPDX-License-Identifier: AFL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MonsterNFT is ERC721URIStorage {
    uint public TotalSupply = 1;

    constructor() ERC721("Monster", "MON") {}

    struct NFTVoucher {
      uint tokenId;
      string name;
      string description;
      string uri;
      uint price;
    }

    event NftMinting (uint _tokenId);

    function Mint() public {
        _mint(msg.sender, TotalSupply);
        TotalSupply++;
        emit NftMinting(TotalSupply-1);
    }
}
