// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";

import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
contract Counter is Ownable2Step,ReentrancyGuard {
    using Math for uint256;

    using Address for address;

    uint256 public totalMawcHolder;

    uint256 public perTokenClaimable;

    uint256 public currentAccountedBalance;

    uint256 public ownerRoyalty;

    bytes32 public currentRootHash;


    uint256 public ownerRoyaltyPercentage = 80;


    uint256 constant denominator = 100; 



    mapping(uint256 => uint256) public claimedRewardPerMawc;

    event updateEvent(uint256 ownerRoyalty,uint256 communityRoyalty);

    event withdraw(address _address,uint256 _amount);


    //@note: Main interface to update everything
    //@note: Recommended to call this direfctly instead of calling each function directly 
    function callMe(uint256 _totalMawcHolder,bytes32 _rootHash) external onlyOwner{
        totalMawcHolder = _totalMawcHolder;
        currentRootHash = _rootHash;
        _update();
    }


    function updateRootHash(bytes32 _newRootHash) public  onlyOwner returns(bytes32){
        currentRootHash = _newRootHash;
        return(currentRootHash);
    }

    function updateTotalMawcHolder(uint256 _newMawcHolder) public  onlyOwner{
        totalMawcHolder = _newMawcHolder;

    }

    //@note: external function for the _update but careful when calling directly as it can mess up with the accounting 
    function update() external onlyOwner nonReentrant{
        _update();
    }


    //@note: Enter the value in percentage
    function updateOwnerRoyalty(uint256 _newValue) external onlyOwner{
        ownerRoyaltyPercentage = _newValue;
    }

    function _update() internal {
        uint256 newBalance = address(this).balance - currentAccountedBalance;

        require(newBalance > 0, "no new funds ");
        
        uint256 newOwnerRoyalty = newBalance.mulDiv(ownerRoyaltyPercentage,denominator);
        //80% of newBalance should be added to ownerRoyalty
        ownerRoyalty = ownerRoyalty + newOwnerRoyalty;



        uint256 totalCommunityRoyalty = newBalance-newOwnerRoyalty;


        //@note: important :- The division is rounded towards positive infinity 
        //eg: if the disivion returns 0.8 (since float is not there in evm we will get "1" as value )
        perTokenClaimable = perTokenClaimable + (totalCommunityRoyalty.ceilDiv(totalMawcHolder));

        currentAccountedBalance = currentAccountedBalance + newBalance;

        emit updateEvent(ownerRoyalty,perTokenClaimable);



    }

    //@note: Check for reentrancy

    //@param: tokenArray :- This should be all the tokens that the user owns 
    function userWithdraw(bytes32[] calldata _proof,uint256[] calldata tokenArray) external nonReentrant{


        bytes32 leafNode = keccak256(bytes.concat(keccak256(abi.encode(msg.sender,tokenArray))));

        require(MerkleProof.verifyCalldata(_proof,currentRootHash,leafNode),"You cannot claim");

        

        unchecked{

        uint256 _amountToTransfer;

        for(uint256 i; i< tokenArray.length;){
            uint256 _actualAmount = perTokenClaimable - claimedRewardPerMawc[tokenArray[i]];

            _amountToTransfer = _amountToTransfer + _actualAmount;

            claimedRewardPerMawc[tokenArray[i]] = claimedRewardPerMawc[tokenArray[i]] + _actualAmount;
            

            ++i;
        }

        require(_amountToTransfer > 0, "Amount to be sent is 0");
        currentAccountedBalance = currentAccountedBalance -_amountToTransfer;
        //@using openzepplin send transfer to transfer the amount securely 
        Address.sendValue(payable(msg.sender),_amountToTransfer);

        emit withdraw(msg.sender,_amountToTransfer);

        }
    }


    //@note: Following checks and effect pattern 
    function ownerWithdraw(address payable _recepient) external onlyOwner nonReentrant{
        require(ownerRoyalty > 0,"There are no funds for the owner to claim");
        uint256 _amountToSend = ownerRoyalty;

        ownerRoyalty = 0;
        currentAccountedBalance =  currentAccountedBalance - _amountToSend;
        Address.sendValue(_recepient,_amountToSend);
        
        emit withdraw(_recepient,_amountToSend);


    }
    
    receive() external payable {
    }
    // //@note: Should only be used in the inevitable cases 
    // function emergencyWithdraw(address payable _recepient) external onlyOwner{
    //     Address.sendValue(_recepient,address(this).balance);
    // }
}