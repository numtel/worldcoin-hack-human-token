// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract MockWorldID {
  mapping(uint => bool) validRoots;

  function setValid(uint root) external {
    validRoots[root] = true;
  }

  function verifyProof(
      uint256 root,
      uint256 groupId,
      uint256 signalHash,
      uint256 nullifierHash,
      uint256 externalNullifierHash,
      uint256[8] calldata proof
  ) external view {
    require(validRoots[root]);
  }
}
