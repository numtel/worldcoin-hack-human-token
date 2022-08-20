const assert = require('assert');

exports.canJoin = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT,
}) {
  const mockWorldId = await deployContract(accounts[0], 'MockWorldID');
  const token = await deployContract(accounts[0], 'HumanToken',
    mockWorldId.options.address,
    1, // groupId
    "test", // actionId
    30 // epochDuration
  );

  await mockWorldId.sendFrom(accounts[0]).setValid(1);

  await token.sendFrom(accounts[0]).join(
    1, // root
    2, // nullifierHash
    [0,0,0,0,0,0,0,0], // proof
    3 // initBallot
  );

  const ballotValue = await token.methods.accountBallots(accounts[0]).call();
  assert.strictEqual(Number(ballotValue), 3);
}

