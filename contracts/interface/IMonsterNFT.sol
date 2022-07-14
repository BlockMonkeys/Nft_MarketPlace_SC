// SPDX-License-Identifier: AFL-3.0

pragma solidity 0.8.7;

interface IMonsterNFT {
    struct NFTVoucher {
        uint tokenId;
        string name;
        string description;
        string uri;
        uint price;
    }

    event NftMinting (uint _tokenId, uint _price);

    function getMsgHash (NFTVoucher memory _voucher) external pure returns(bytes32 _msgHash);
    function redeemNFT (address _redeemer, address _signer, bytes memory _sig, NFTVoucher calldata _voucher) external payable returns (uint256);
    function setLocking () external returns (bool);
    function changeOwner (address _newOwner) external returns (address);
}