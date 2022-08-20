// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";
// From world-id-contracts
import "./IWorldID.sol";
import "./ByteHasher.sol";

contract HumanToken is ERC20 {
  string public name = "Human Token";
  string public symbol = "HUM";
  uint8 public decimals = 6;

  using ByteHasher for bytes;

  mapping(address => uint8) public accountBallots;
  uint64[32] public ballotBuckets;
  uint public ballotCount;

  IWorldID public worldId;
  uint public groupId;
  uint public actionId;
  uint public epochDuration;
  uint public initTime;

  struct EpochMedian {
    uint128 epochNumber;
    uint8 median;
  }
  EpochMedian[] public epochs;

  mapping(uint256 => bool) internal nullifierHashes;

  mapping(address => uint) public lastCollected;

  constructor(
    IWorldID _worldId,
    uint256 _groupId, // always 1
    string memory _actionId,
    uint _epochDuration
  ) {
    worldId = _worldId;
    groupId = _groupId;
    actionId = abi.encodePacked(_actionId).hashToField();
    epochDuration = _epochDuration;
    initTime = block.timestamp;
  }

  function join(
    uint256 root,
    uint256 nullifierHash,
    uint256[8] calldata proof,
    uint8 initBallot
  ) external {
    require(nullifierHashes[nullifierHash] == false);
    //Effects before actions (would worldId cause reentrancy?)
    nullifierHashes[nullifierHash] = true;
    lastCollected[msg.sender] = block.timestamp;

    require(initBallot > 0 && initBallot < 33);
    accountBallots[msg.sender] = initBallot;
    ballotBuckets[initBallot]++;
    ballotCount++;
    updateMedian();

    worldId.verifyProof(
      root,
      groupId,
      abi.encodePacked(msg.sender).hashToField(),
      nullifierHash,
      actionId,
      proof
    );
  }

  function updateBallot(uint8 value) external {
    require(lastCollected[msg.sender] != 0);
    // 0 value is reserved for some reason?
    require(value > 0 && value < 33);
    // No change, get out!
    if(accountBallots[msg.sender] == value) return;

    // Remove old ballot from the bucket
    ballotBuckets[accountBallots[msg.sender]]--;

    // Add new ballot to bucket
    ballotBuckets[value]++;
    accountBallots[msg.sender] = value;

    updateMedian();

  }

  function updateMedian() internal {
    uint128 curEpoch = uint128((block.timestamp - initTime) / epochDuration);


    // Calculate the median from all the buckets
    uint8 curBucket;
    uint medianPos = ballotCount / 2;
    bool countIsEven = ballotCount % 2 == 0;
    uint soFar;
    uint8 otherBucket;
    while(soFar <= medianPos) {
      soFar += ballotBuckets[curBucket];
      curBucket++;
      if(countIsEven && soFar == medianPos && otherBucket == 0) {
        // Median is between 2 buckets
        otherBucket = curBucket;
      }
    }
    if(otherBucket > 0) {
      curBucket = (otherBucket + curBucket) / 2;
    }


    if(epochs.length > 0 && epochs[epochs.length - 1].epochNumber == curEpoch) {
      // This epoch already has an entry
      epochs[epochs.length - 1].median = curBucket - 1;
    } else {
      // The median has not changed in this epoch yet
      epochs.push(EpochMedian(curEpoch, curBucket - 1));
    }

  }

  function amountAvailable(address account) public view returns(uint) {
    require(lastCollected[account] != 0);

  }
}
