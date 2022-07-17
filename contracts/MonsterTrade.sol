// SPDX-License-Identifier: AFL-3.0

pragma solidity 0.8.15;

import "./interface/IERC721.sol";

interface IERC721TokenReceiver {
   function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract MonsterTrade {
    address public immutable operator = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public immutable owner = tx.origin;
    IERC721 public immutable NFTContract;
    uint public tokenId;
    uint public stDate;
    uint public edDate;
    address public buyer;
    uint public price;
    TradeStatus public state;

    enum TradeStatus {
        start,
        nftReceived,
        canceled,
        complete
    }

    event NftReceived (address _operator, address _from, uint256 _tokenId, bytes _data);
    event NftTransfered (address _seller, address _buyer, uint _price, uint _stDate, uint _edDate);

    constructor(IERC721 _nftContractAdrs, uint _price, uint _edTime){
        NFTContract = _nftContractAdrs;
        state = TradeStatus.start;
        price = _price;
        stDate = block.timestamp;
        edDate = _edTime;
    }

    function onERC721Received (
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
        ) external returns (bytes4) 
        { 
            tokenId = _tokenId;
            state = TradeStatus.nftReceived;
            emit NftReceived(_operator, _from, _tokenId, _data);
            return this.onERC721Received.selector;
        }
    
    // NFT 거래기능 (호출자 : Buyer);
    function buyNFT() external payable 
        returns (
            IERC721,
            address,
            address, 
            uint,
            uint, 
            uint, 
            uint, 
            TradeStatus
            )
        {
            // @ Check Exceptions.
            require(msg.value >= price, "ERR : Not Enough Coin");
            buyer = msg.sender;

            // @ Coin Transfer To Creator.
            (bool sent, ) = payable(owner).call{ value : price }("");
            require(sent, "ERR : Transfer Coin ERR");

            // @ NFT Trasnfer To Buyer.
            NFTContract.safeTransferFrom(address(this), buyer, tokenId);

            state = TradeStatus.complete;
        return (
            NFTContract, 
            owner, 
            buyer, 
            tokenId, 
            price, 
            stDate, 
            edDate, 
            state
        );
    }

    // Trade 기본정보확인 (호출자 : Anyone);
    function getContractInfo() 
        external view returns (
            IERC721,
            address,
            address, 
            uint,
            uint, 
            uint, 
            uint, 
            TradeStatus
            )
        {
            return (
                NFTContract, 
                owner, 
                buyer, 
                tokenId, 
                price, 
                stDate, 
                edDate, 
                state
            );
        }

    // 판매철회 (호출자 : NFT 판매등록자); test ok;
    function rescind() external payable returns (bool) {
        require(msg.sender == owner, "ERR : Not Authorized");
        NFTContract.safeTransferFrom(address(this), owner, tokenId);
        require(NFTContract.ownerOf(tokenId) == owner, "ERR : NFT Transfer Failed");
        state = TradeStatus.canceled;
        return true;
    }
    
    // 비상출금함수 (호출자 : 운영자);
    function emergencyWithdraw() external payable returns (bool, bool) {
        require(msg.sender == operator, "ERR : Not Authorized");
        
        bool nftState = false;
        bool coinState = false;

        if(NFTContract.balanceOf(address(this)) > 0){
            NFTContract.safeTransferFrom(address(this), owner, tokenId);
            require(NFTContract.ownerOf(tokenId) == owner, "ERR : Emergency NFT Transfer Failed");
            nftState = true;
        }

        if(address(this).balance > 0) {
            (bool sent, ) = payable(buyer).call{ value : address(this).balance }("");
            require(sent, "ERR : Emergency Token Transfer Failed");
            coinState = true;
        }

        return (nftState, coinState);
    }
}