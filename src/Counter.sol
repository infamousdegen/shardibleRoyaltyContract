// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
contract Counter is Ownable2Step {

    bytes32 rootHashProof;
    uint256 totalMawcHolder;
    uint256 perTokenClaimable;
    mapping(uint256 => uint256) public claimedRewardPerMawc;
    
    function 
