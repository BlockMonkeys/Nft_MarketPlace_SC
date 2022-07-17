// SPDX-License-Identifier: AFL-3.0
import "./MonsterTrade.sol";
import "./interface/IERC721.sol";

pragma solidity 0.8.15;

contract MonsterFactory {
    address public immutable operator = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    uint public TotalSupply = 1;
    bool lock = false;

    struct TradeVoucher {
        uint id;
        address nftContract;
        uint tokenId;
        address nftOwner;
        uint price;
        uint stDate;
        uint edDate;
        address tradeContract;
    }

    event TradeCreated (MonsterTrade _tradeContractAdrs, uint tokenId, uint _price);
    
    mapping(bytes32 => TradeVoucher) public Trades_byKeccak_mapping;
    mapping(uint => TradeVoucher) public Trades_byId_mapping;

    modifier lockChecker {
        if(msg.sender == operator) {
            _;
        }
        require(!lock, "ERR : Currently Locked");
        _;
    }

    // NFT 판매 등록 함수 (호출자 : NFT Owner);
    function createTrade (
        IERC721 _nftContractAdrs, 
        uint _tokenId, 
        uint _price, 
        uint _timeSet
        ) external payable lockChecker returns(address)
        {
            // @ NFT Owner Check
            require(_nftContractAdrs.ownerOf(_tokenId) == msg.sender, "ERR : Not Owner of NFT");
            
            // @ Duplicate Register Prevention
            bytes32 voucherId = keccak256(abi.encodePacked(_nftContractAdrs, _tokenId, msg.sender));

            // If, Already Exist;
            if(Trades_byKeccak_mapping[voucherId].id > 0) {
                // If, Expired;
                if(Trades_byKeccak_mapping[voucherId].edDate <= block.timestamp) {
                    delete Trades_byKeccak_mapping[voucherId];
                    } else {
                        revert("ERR : Already Registered");
                    }
            }

            // @ Create Trade Contract
            MonsterTrade MonsterTradeContractAdrs = new MonsterTrade(_nftContractAdrs, _price, block.timestamp + _timeSet);

            // @ Transfer NFT into Trade Contract;
            _nftContractAdrs.safeTransferFrom(msg.sender, address(MonsterTradeContractAdrs), _tokenId);

            // @ Add Mapping Data
            Trades_byKeccak_mapping[voucherId] = TradeVoucher(
                                                    TotalSupply, 
                                                    address(_nftContractAdrs),
                                                    _tokenId, msg.sender, 
                                                    _price, 
                                                    block.timestamp, 
                                                    block.timestamp + _timeSet, 
                                                    address(MonsterTradeContractAdrs)
                                                );

            Trades_byId_mapping[TotalSupply] = TradeVoucher(
                                                    TotalSupply, 
                                                    address(_nftContractAdrs), 
                                                    _tokenId, 
                                                    msg.sender, 
                                                    _price, 
                                                    block.timestamp, 
                                                    block.timestamp + _timeSet, 
                                                    address(MonsterTradeContractAdrs)
                                                );
            
            // @ Emit Event
            emit TradeCreated(MonsterTradeContractAdrs, _tokenId, _price);
            TotalSupply++;

            return address(MonsterTradeContractAdrs);
        }

    function getVoucher_by_info(IERC721 _nftContractAdrs, uint _tokenId, address _seller) external view returns(TradeVoucher memory) {
        return Trades_byKeccak_mapping[keccak256(abi.encodePacked(_nftContractAdrs, _tokenId, _seller))];
    }

    function setLocking() external returns(bool) {
        require(msg.sender == operator, "ERR : Not Authorized");
        lock = !lock;
        return lock;
    }
    
}

