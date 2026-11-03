// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AjoChain - Decentralized Esusu
/// @author Bright Alobo
/// @notice Wallet-only, no phone, auto-rotate payout
contract AjoChain {
    struct Pool {
        uint256 id;
        uint256 amount;
        uint8 membersCount;
        uint8 paidCount;
        uint8 nextIndex;
        uint256 createdAt;
        bool active;
    }

    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => bool)) public hasContributed;
    mapping(uint256 => address[]) public members;
    uint256 public nextPoolId = 12;
    uint256 public TVL;

    event PoolCreated(uint256 poolId, uint256 amount, address creator);
    event Contributed(uint256 poolId, address member, uint256 amount);
    event Payout(uint256 poolId, address recipient, uint256 amount);

    function createPool(uint256 _amount, uint8 _m) external returns(uint256){
        uint256 pid = nextPoolId++;
        pools[pid] = Pool(pid,_amount,_m,0,0,block.timestamp,true);
        members[pid].push(msg.sender);
        emit PoolCreated(pid,_amount,msg.sender);
        return pid;
    }

    function contribute(uint256 _poolId) external payable {
        Pool storage p = pools[_poolId];
        require(p.active, "closed");
        require(msg.value == p.amount, "wrong amount");
        require(!hasContributed[_poolId][msg.sender], "already paid");
        hasContributed[_poolId][msg.sender]=true;
        p.paidCount+=1;
        TVL+=msg.value;
        emit Contributed(_poolId,msg.sender,msg.value);
        if(p.paidCount==p.membersCount){
            address recipient = members[_poolId][p.nextIndex % p.membersCount];
            uint256 payoutAmt = p.amount * p.membersCount;
            p.nextIndex+=1;
            p.paidCount=0;
            for(uint i=0;i<members[_poolId].length;i++){
                hasContributed[_poolId][members[_poolId][i]]=false;
            }
            payable(recipient).transfer(payoutAmt);
            emit Payout(_poolId,recipient,payoutAmt);
        }
    }

    function getPool(uint256 _id) external view returns(Pool memory){
        return pools[_id];
    }
}
