# TaxiTogether Solidity Application

I'll basicly explain the main usage of the application below.

## Compiler

I used solidity ^0.4.21 version, so the application must be compiled with "0.4.21+commit.dfe3193c"

## Usage

-> I've used function with the contract's name instead of constructor (function TaxiTogether()). That function is called only once when the contract is created and sets the initial values just like a constructor (I had asked if it's okay to do constructor this way and you said no problem).

-> The initial values that I set in the constructor are:
Driver Salary = 5 ether (paid per month)
Car Expenses = 10 ether (paid every six months)
Participant Fee = 100 ether (paid to join the contract)

-> The proposed car ID must be other than '0'. If ownedCar ID is 0, that means the crew currently doesn't have a car.

-> Person must call joinTaxi function with value = 100 ether, otherwise he can not join the crew. Every person can call this function only once (they can not have more share than others in the contract).

-> Car dealer can propose cars with ID, price and validTime. Price is count as ether and validTime is count as days. If car dealer sets these parameters as: 1, 100, 30; means that the car has ID:1, price: 100 ether, and valid for 30 days. It's the same when car dealer calls purchasePropose function. Car dealer can propose different cars but there will be only one car bought by the contract at the same time. Proposed cars are stored in Car struct, owned car's ID is kept in ownedCar variable.

-> If crew members wants their car to be sold, they call approveSellProposal function. They can call only once in valid time. They can see the state in approvalState function, if approval state is higher than half of crew members, dealer can buy the car but these two actions must be done before the valid time.

-> Car dealer must send the price in message value he proposed in purchasePropose while calling sellCar function.

-> paySalary function time starts when manager sets the driver. And it is payable every 30days.

-> carExpenses function time starts when the car is bought. And it is payable every 180 days.

-> payDividend function time starts when the contract is created. And it can be called every 180 days.
