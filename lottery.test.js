const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const { interface, bytecode } = require('../compile'); //requiring an object that has the interface and bytecode properties

let lottery; //holds the instance of the contract
let accounts; //holds a list of all the different accounts that are automatically generated and unlocked as a part of the ganache-cli

beforeEach(async () => {
    accounts = await web3.eth.getAccounts();

    lottery = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode})
    .send({ from: accounts[0], gas: '1000000' });
});

describe('Lottery Contract', () => {
    it('deploys a contract', () => { //verifies if the contract was successfully deployed to the local network
        assert.ok(lottery.options.address) //makes sure some value was defined
    });

    it("allows one account to enter", async () => {
        await lottery.methods.enter().send({
          from: accounts[0],
          value: web3.utils.toWei("0.02", "ether"),
        });
    
        const players = await lottery.methods.getPlayers().call({
          from: accounts[0],
        });
    
        assert.equal(accounts[0], players[0]);
        assert.equal(1, players.length);
      });

      it("allows multiple accounts to enter", async () => {
        await lottery.methods.enter().send({
          from: accounts[0],
          value: web3.utils.toWei("0.02", "ether"),
        });
        await lottery.methods.enter().send({
          from: accounts[1],
          value: web3.utils.toWei("0.02", "ether"),
        });
        await lottery.methods.enter().send({
          from: accounts[2],
          value: web3.utils.toWei("0.02", "ether"),
        });
    
        const players = await lottery.methods.getPlayers().call({
          from: accounts[0],
        });
    
        assert.equal(accounts[0], players[0]);
        assert.equal(accounts[1], players[1]);
        assert.equal(accounts[2], players[2]);
        assert.equal(3, players.length);
      });

    it("requires a minimum amount of ether to enter", async () => { // try-catch assertions
        try{
        await lottery.methods.enter().send({
            from: accounts[0],
            value: 0
        });
        assert(false); //will always fail the test no matter what
        } catch (err) {
            assert.ok(err);
        }
    });

    it("only manager can call pickWinner", async () => { //testing function modifiers
       try{
        await lottery.methods.pickWinner.send({
            from: accounts[1]
        });
        assert(false);
       } catch (err) {
        assert(err);
       }
    });

    it("sends money to the winner and resets the player's array", async () => { //end to end test
        await lottery.methods.enter().send({
            from: accounts[0],
            value: web3.utils.toWei("2", "ether")
        });

        const initialBalance = await web3.eth.getBalance(accounts[0]); //returns the amount of ether in units of wei that a given account controls
        await lottery.methods.pickWinner().send({ from: accounts[0] });
        const finalBalance = await web3.eth.getBalance(accounts[0]);
        const difference = finalBalance - initialBalance;
        console.log(finalBalance - initialBalance); //sees how much was spent on gas

        assert(difference > web3.utils.toWei("1.8", "ether"));
    });
});
