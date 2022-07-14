// SPDX-License-Identifier: AFL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MonsterNFT is ERC721URIStorage {
    address public owner;
    uint public TotalSupply = 1;
    bool lock = false;

    constructor() ERC721("Monster", "MON") {
      owner = msg.sender;
    }

    struct NFTVoucher {
      uint tokenId;
      string name;
      string description;
      string uri;
      uint price;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "Only Owner Function");
      _;
    }

    event NftMinting (uint _tokenId, uint _price);

    // @ Lazy Minting
    function getMsgHash (NFTVoucher memory _voucher) public pure returns(bytes32 _msgHash){
      _msgHash = keccak256(abi.encodePacked(_voucher.tokenId, _voucher.name, _voucher.description, _voucher.uri, _voucher.price));
    }

    function redeemNFT (
      address _redeemer, 
      address _signer, 
      bytes memory _sig, 
      NFTVoucher calldata _voucher
      ) external payable returns (uint256) 
      {
        require(!lock, "Currently Locked");
        require(_verify(_signer, _sig, _voucher), "Verify Failed");
        require(msg.value >= _voucher.price, "Sent Price is Not Enough");
        
        lock = true;

        _mint(_signer, _voucher.tokenId);
        _setTokenURI(_voucher.tokenId, _voucher.uri);
        _transfer(_signer, _redeemer, _voucher.tokenId);

        emit NftMinting(_voucher.tokenId, _voucher.price);
        TotalSupply++;

        lock = false;
        return _voucher.tokenId;
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

    // @ ECDSA internal Feature
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
