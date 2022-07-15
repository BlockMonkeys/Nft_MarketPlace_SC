// SPDX-License-Identifier: AFL-3.0

pragma solidity 0.8.7;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721TokenReceiver {
   function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

// ERC165 Interface Checking 적용 필수;
contract NFTTrade is IERC721TokenReceiver {
    address private immutable factoryAdrs;
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
        tokenReceived,
        complete
    }

    event NftReceived (address _operator, address _from, uint256 _tokenId, bytes _data);
    event NftTransfered (address _seller, address _buyer, uint _price, uint _stDate, uint _edDate);

    constructor(IERC721 _nftAdrs, uint _price, address _factoryAdrs){
        NFTContract = _nftAdrs;
        state = TradeStatus.start;
        price = _price;
        stDate = block.timestamp;
        factoryAdrs = _factoryAdrs;
    }

    function onERC721Received (
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
        ) public virtual override returns (bytes4) 
        { 
            tokenId = _tokenId;
            state = TradeStatus.nftReceived;
            emit NftReceived(_operator, _from, _tokenId, _data);
            return this.onERC721Received.selector;
        }
    
    receive() external payable {
        state = TradeStatus.tokenReceived;
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
        // Check Exceptions.
        require(msg.value >= price, "ERR : Not Enough Coin");
        require(state == TradeStatus.tokenReceived, "ERR : Coin Not Received");
        buyer = msg.sender;
        // NFT를 Buyer에게 전달.
        NFTContract.safeTransferFrom(address(this), buyer, tokenId);
        // Coin을 Creator로 전달.
        (bool sent, ) = payable(owner).call{ value : price }("");
        require(sent, "ERR : Transfer Coin ERR");
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

    // NFT 기본 정보 확인 (호출자 : Anyone);
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

    // 판매철회; (호출자 : NFT 판매등록자);
    function rescind() external payable returns (bool) {
        require(msg.sender == owner, "ERR : Not Authorized");
        NFTContract.safeTransferFrom(address(this), owner, tokenId);
        require(NFTContract.ownerOf(tokenId) == owner, "ERR : NFT Transfer Failed");
        return true;
    }
    
    // 비상출금함수 (호출자 : 운영자);
    function emergencyWithdraw() external payable returns (bool, bool) {
        require(msg.sender == factoryAdrs, "ERR : Not Authorized");
        
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