// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MonsterNFT is ERC721URIStorage {
    address public owner;
    uint public mintingPrice;
    bool lock = false;

    constructor() ERC721("Monster", "MON") {
      owner = payable(msg.sender);
    }

    struct NFTVoucher {
      string name;
      string description;
      string ipfsUrl;
      uint price;
    }

    modifier onlyOwner {
      require(msg.sender == owner, "ERR : Not Authorized");
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

    event NftMinting (uint _tokenId, uint _price, address _minter);

    mapping(uint => NFTVoucher) public NFTVouchers;

    receive() external payable {}

    // @ Minting NFT
    function mintNFT (
      string memory _name,
      string memory _description,
      string memory _url
    ) external payable 
      lockChecker
      returns (NFTVoucher memory)
    {
      require(msg.value >= mintingPrice, "ERR : Not Enough Money");
      lock = true;

      // @ Transfer NFT To Buyer;
      _mint(msg.sender, TotalSupply);
      _setTokenURI(TotalSupply, _url);
      NFTVouchers[TotalSupply] = NFTVoucher(_name, _description, _url, mintingPrice);

      // @ Transfer Coin To _signer;
      (bool sent, ) = owner.call{ value : payable(address(this)).balance }("");
      require(sent, "ERR : Transfer Money");
    
      emit NftMinting(TotalSupply, mintingPrice, msg.sender);
      TotalSupply++;

      lock = false;
      
      return NFTVouchers[TotalSupply-1];
    }

    function setPrice(uint _newPrice) external onlyOwner returns(uint){
      mintingPrice = _newPrice;
      return mintingPrice;
    }

    // @ Lazy Minting
    function getMsgHash (NFTVoucher memory _voucher) public pure returns(bytes32 _msgHash){
      _msgHash = keccak256(abi.encodePacked(
                            _voucher.name, 
                            _voucher.description, 
                            _voucher.ipfsUrl, 
                            _voucher.price
                          ));
    }

    function redeemNFT (
      address payable _redeemer, 
      address payable _signer, 
      bytes memory _sig, 
      NFTVoucher calldata _voucher
      ) external payable 
      lockChecker
      returns (uint256) 
      {
        require(!lock, "ERR : Currently Locked");
        require(_verify(_signer, _sig, _voucher), "ERR : Verify Failed");
        require(msg.value >= _voucher.price, "ERR : Sent Price Not Enough");

        lock = true;

        // @ Minting & Creator -> Redeemer Transfer NFT;
        _mint(_signer, TotalSupply);
        _setTokenURI(TotalSupply, _voucher.ipfsUrl);
        _transfer(_signer, _redeemer, TotalSupply);

        // @ Transfer Coin To _signer;
        (bool sent, ) = _signer.call{ value : payable(address(this)).balance }("");
        require(sent, "ERR : Transfer Money");

        // @ Emit Event;
        emit NftMinting(TotalSupply, _voucher.price, _redeemer);

        // @ Record;
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

    // @ EC Verification Feature
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


    // @ Emergency Feature;
    function checkBalance() external view onlyOwner returns(uint) {
      return address(this).balance;
    }

    function emergencyWithdrawal() external payable onlyOwner {
      (bool sent, ) = owner.call{ value : payable(address(this)).balance }("");
      require(sent, "ERR : Transfer Money");
    }
    
    function emergencyWithdrawal_transfer(address payable _to, uint _value) external payable onlyOwner {
      (bool sent, ) = _to.call{ value : _value }("");
      require(sent, "ERR : Transfer Money");
    }
}
