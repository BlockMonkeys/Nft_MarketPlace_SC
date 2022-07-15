// SPDX-License-Identifier: AFL-3.0

pragma solidity 0.8.7;

interface ITradeNFT {
    event NftReceived (address _operator, address _from, uint256 _tokenId, bytes _data);
    event NftTransfered (address _seller, address _buyer, uint _price, uint _stDate, uint _edDate);

    // NFT 거래기능 (호출자 : Buyer);
    function buyNFT() external payable returns (IERC721, address owner, address buyer, uint tokenId,uint price, uint stDate, uint edDate, TradeStatus state);
    // NFT 기본 정보 확인 (호출자 : Anyone);
    function getContractInfo() external view returns (IERC721, address owner, address buyer, uint tokenId, uint price, uint stDate, uint edDate, TradeStatus state);
    // 판매철회; (호출자 : NFT 판매등록자);
    function rescind() external payable returns (bool);
    // 비상출금함수 (호출자 : 운영자);
    function emergencyWithdraw() external payable returns (bool, bool);
}