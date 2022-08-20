// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";
// From world-id-contracts
import "./IWorldID.sol";
import "./ByteHasher.sol";

contract HumanToken is ERC20 {
  using ByteHasher for bytes;

  mapping(address => uint8) public accountBallots;
  uint64[32] public ballotBuckets;
  uint public ballotCount;
  uint8 public ballotMedian;

  IWorldId public worldId;
  uint public groupId;
  uint public actionId;
  uint public epochDuration;

  mapping(uint256 => bool) internal nullifierHashes;

  mapping(address => uint) public lastCollected;

  constructor(
    IWorldId _worldId,
    uint256 _groupId,
    string memory _actionId,
    uint _epochDuration
  ) {
    worldId = _worldId;
    groupId = _groupId;
    actionId = abi.encodePacked(_actionId).hashToField();
    epochDuration = _epochDuration;
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

  function updateMedian() internal {
  }

  function submitBallot(uint8 value) external {
    require(lastCollected[msg.sender] != 0);
    // 0 value is reserved for not
    require(value > 0 && value < 33);

  }

  function amountAvailable(address account) public view returns(uint) {
    require(lastCollected[account] != 0);

  }
}
