const assert = require('assert');

exports.canJoin = async function({
  web3, accounts, deployContract, loadContract, throws, BURN_ACCOUNT, increaseTime,
}) {
  const EPOCH_DURATION = 30;

  const mockWorldId = await deployContract(accounts[0], 'MockWorldID');
  const token = await deployContract(accounts[0], 'HumanToken',
    mockWorldId.options.address,
    1, // groupId
    "test", // actionId
    EPOCH_DURATION // epochDuration
  );

  await mockWorldId.sendFrom(accounts[0]).setValid(1);

  // First user joins
  await token.sendFrom(accounts[0]).join(
    1, // root
    2, // nullifierHash
    [0,0,0,0,0,0,0,0], // proof
    3 // initBallot
  );

  const ballotValue = await token.methods.accountBallots(accounts[0]).call();
  assert.strictEqual(Number(ballotValue), 3);

  let curEpoch = await token.methods.epochs(0).call();
  assert.strictEqual(Number(curEpoch.median), 3);

  // Cannot reuse nullifierHash
  assert.strictEqual(await throws(() =>
    token.sendFrom(accounts[1]).join(
      1, // root
      2, // nullifierHash
      [0,0,0,0,0,0,0,0], // proof
      5 // initBallot
    )), true);

  // Second user joins
  await token.sendFrom(accounts[1]).join(
    1, // root
    3, // nullifierHash
    [0,0,0,0,0,0,0,0], // proof
    5 // initBallot
  );

  // Median is updated
  curEpoch = await token.methods.epochs(0).call();
  assert.strictEqual(Number(curEpoch.median), 4);

  // Third user joins
  await token.sendFrom(accounts[2]).join(
    1, // root
    4, // nullifierHash
    [0,0,0,0,0,0,0,0], // proof
    9 // initBallot
  );

  curEpoch = await token.methods.epochs(0).call();
  assert.strictEqual(Number(curEpoch.median), 5);

  await increaseTime(EPOCH_DURATION + 1);

  // Fourth user joins
  await token.sendFrom(accounts[3]).join(
    1, // root
    5, // nullifierHash
    [0,0,0,0,0,0,0,0], // proof
    9 // initBallot
  );

  // Previous epoch stays the same
  const prevEpoch = await token.methods.epochs(0).call();
  assert.strictEqual(Number(prevEpoch.median), 5);
  // New epoch is recorded
  curEpoch = await token.methods.epochs(1).call();
  assert.strictEqual(Number(curEpoch.median), 7);

  // Second user changes their ballot
  await token.sendFrom(accounts[1]).updateBallot(11);
  curEpoch = await token.methods.epochs(1).call();
  assert.strictEqual(Number(curEpoch.median), 9);
}

