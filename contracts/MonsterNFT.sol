// SPDX-License-Identifier: AFL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MonsterNFT is ERC721URIStorage {
    address public owner;
    bool lock = false;
    uint mintingPrice;

    constructor() ERC721("Monster", "MON") {
      owner = msg.sender;
    }

    struct NFTVoucher {
      string name;
      string description;
      string uri;
      uint price;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Only Owner Function");
      _;
    }

    modifier lockChecker {
      if(msg.sender == owner) {
        _;
      }
      require(!lock, "ERR : Currently Locked");
      _;
    }

    uint public TotalSupply = 1;
    event NftMinting (uint _tokenId, uint _price);

    mapping(uint => NFTVoucher) public NFTVouchers;

    // @ Minting NFT
    function mintNFT (
      string memory _name,
      string memory _description,
      string memory _uri
    ) external payable 
      lockChecker
      returns (NFTVoucher memory)
    {
      require(msg.value >= mintingPrice, "ERR : Not Enough Money");
      _mint(msg.sender, TotalSupply);
      _setTokenURI(TotalSupply, _uri);
      NFTVouchers[TotalSupply] = NFTVoucher(_name, _description, _uri,mintingPrice);

      emit NftMinting(TotalSupply, mintingPrice);
      TotalSupply++;
      
      return NFTVouchers[TotalSupply-1];
    }

    function setPrice(uint _newPrice) onlyOwner external returns(uint){
      mintingPrice = _newPrice;
      return mintingPrice;
    }

    // @ Lazy Minting
    function getMsgHash (NFTVoucher memory _voucher) public pure returns(bytes32 _msgHash){
      _msgHash = keccak256(abi.encodePacked(_voucher.name, _voucher.description, _voucher.uri, _voucher.price));
    }

    function redeemNFT (
      address _redeemer, 
      address _signer, 
      bytes memory _sig, 
      NFTVoucher calldata _voucher
      ) external payable 
      lockChecker
      returns (uint256) 
      {
        require(!lock, "Currently Locked");
        require(_verify(_signer, _sig, _voucher), "Verify Failed");
        require(msg.value >= _voucher.price, "Sent Price is Not Enough");
        
        lock = true;

        _mint(_signer, TotalSupply);
        _setTokenURI(TotalSupply, _voucher.uri);
        _transfer(_signer, _redeemer, TotalSupply);

        emit NftMinting(TotalSupply, _voucher.price);
        NFTVouchers[TotalSupply] = _voucher;

        TotalSupply++;

        lock = false;
        return TotalSupply-1;
      }


    // @ Only Owner Feature
    function setLocking () external onlyOwner returns (bool) {
      lock = !lock;
      return lock;
    }

    function changeOwner (address _newOwner) external onlyOwner returns (address) {
      owner = _newOwner;
      return owner;
    }

    // @ ECDSA Feature
    function _verify (
      address _signer, 
      bytes memory _sig, 
      NFTVoucher memory _voucher
      ) internal pure returns (bool) 
      {
        bytes32 msgHash = getMsgHash(_voucher);
        bytes32 ethSignedMsgHash = _getEthSignedMsg(msgHash);
        return _recover(ethSignedMsgHash, _sig) == _signer;
      }

    function _getEthSignedMsg (bytes32 _msgHash) internal pure returns (bytes32) 
      {
        return keccak256(abi.encodePacked(
              "\x19Ethereum Signed Message:\n32",
              _msgHash
            ));
      }

    function _recover (
      bytes32 _ethSignedMessageHash, 
      bytes memory _sig
      ) internal pure returns (address)
      {
          (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
          return ecrecover(_ethSignedMessageHash, v, r, s);
      }

    function _split(
      bytes memory _sig
      ) internal pure returns(
        bytes32 r, 
        bytes32 s, 
        uint8 v) 
      {

      require(_sig.length == 65, "Invalid Signature length");
      
      assembly {
          r := mload(add(_sig, 32))
          s := mload(add(_sig, 64))
          v := byte(0, mload(add(_sig, 96)))
      }

      return (r, s, v);
      }

}
