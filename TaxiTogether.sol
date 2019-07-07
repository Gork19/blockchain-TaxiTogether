pragma solidity ^0.4.21;
contract TaxiTogether {

    //Participants and their balances
	struct Participant {
		uint pBalance;
		uint isJoined;
		uint canVote;
	}
	//map their addresses to pay dividend money
	struct ParticpntID {
	    address pID;
	}
	//Car info
	struct Car {
	    uint32 ID;
	    uint price;
	    uint sellPrice;
	    uint sellApproved;
	    uint validTime;
	    uint isBought;
	}
	
	mapping(address => Participant) participants;
	mapping(uint => ParticpntID) partcpntIDs;
	mapping(uint32 => Car) cars;
	
	//Variables
	uint totalBalance;
	uint partcpntCount; //must be less than 100
	uint driverBalance;
	uint driverSalary; //set in constructor
	uint expenses; //set in constructor
	uint partcptnFee; //set in constructor
	uint32 ownedCar; //ID of the car
	uint approvalState; //must have majority of votes to set sellApproved state of the car
	uint carExpensesTimer; //every 6 months
	uint driverSalaryTimer; //every 1 month
	uint payDividendTimer; //every 6 months
	address public manager;
	address public taxiDriver;
	address public carDealer;
	
	//Status notification
	event Status(string msg, address user, uint time);

    //Modifiers
	modifier OnlyManager {
	    require(msg.sender == manager);
	    _;
	}
	modifier OnlyDealer {
	    require(msg.sender == carDealer);
	    _;
	}
	modifier OnlyDriver {
	    require(msg.sender == taxiDriver);
	    _;
	}

    //Constructor to set initial values
    function TaxiTogether() public {
        manager = msg.sender;
        partcpntCount = 0;
        totalBalance = 0 ether;
        driverBalance = 0 ether;
        driverSalary = 5 ether;
        expenses = 10 ether;
        partcptnFee = 100 ether;
        carExpensesTimer = block.timestamp;
	    driverSalaryTimer = block.timestamp;
	    payDividendTimer = block.timestamp;
	    emit Status('Contract is created', msg.sender, block.timestamp);
    }
    
    //Function to join the contract
	function joinTaxi() payable public{
	    //The crew is full
	    require(partcpntCount<100);
	    //The person already joined
	    require(participants[msg.sender].isJoined != 1);
	    //Need to pay participant fee
	    require(msg.value==partcptnFee);
	    partcpntIDs[partcpntCount].pID = msg.sender;
	    partcpntCount = partcpntCount + 1;
		participants[msg.sender].pBalance = 0 ether;
		participants[msg.sender].isJoined = 1;
		totalBalance += msg.value;
		emit Status('There is a new crew member joined TaxiTogether', msg.sender, block.timestamp);
	}
	
	//Shows total balance in the contract
	function getTotalBalance() view public returns(uint) {
        return totalBalance;
	}
	
	//Shows the persons balance
	function getMyBalance() view public returns(uint) {
	    return participants[msg.sender].pBalance;
	}
	
	//Manager sets the car dealer
	function setCarDealer(address dealerAddr) OnlyManager public {
	    carDealer = dealerAddr;
	    emit Status('Manager has set a new car dealer', carDealer, block.timestamp);
	}
	
	//Car dealer proposes a new car, valid time is days long such as if the input is 60 it is valid for the next 60days
	function carPropose(uint32 _ID, uint _price, uint _validTime) OnlyDealer public {
	    //Proposed car is the owned car
	    require(_ID != ownedCar);
	    cars[_ID].ID = _ID;
	    cars[_ID].price = (_price * 1 ether);
	    cars[_ID].validTime = now + (_validTime * 1 days);
	    cars[_ID].isBought = 0;
	    emit Status('A new car is proposed by the dealer', carDealer, block.timestamp);
	}
	
	//Manager can buy a proposed car
	function purchaseCar(uint32 _ID) OnlyManager payable public {
	    //The car has already been bought
	    require(cars[_ID].isBought != 1);
	    //Validity time has expired
	    require(cars[_ID].validTime >= now);
	    //Balance is not enough
	    require(totalBalance >= cars[_ID].price);
        totalBalance = totalBalance - cars[_ID].price;
        carDealer.transfer(cars[_ID].price);
        cars[_ID].isBought = 1;
        cars[_ID].sellApproved = 0;
        cars[_ID].validTime = block.timestamp;
        carExpensesTimer = block.timestamp; //car expenses start when the car is bought
        ownedCar = _ID;
        emit Status('Manager has bought a new car', msg.sender, block.timestamp);
	}
	
	//Dealer can propose for a car that the contract has
	function purchasePropose(uint32 _ID, uint _price, uint _validTime) OnlyDealer public {
	    //this car hasn't been bought
	    require(cars[_ID].isBought!=0);
        cars[_ID].sellPrice = (_price * 1 ether);
        cars[_ID].validTime = now + (_validTime * 1 days);
        //Generate states for voting
        approvalState = 0;
        cars[_ID].sellApproved = 0;
        for(uint i=0; i<partcpntCount; i++) {
            participants[partcpntIDs[i].pID].canVote = 1;
        }
        emit Status('Car dealer has proposed for a car', msg.sender, block.timestamp);
	}
	
	//Crew members vote for the car propose
	function approveSellProposal() public {
	    //Crew member has voted before
	    require(participants[msg.sender].canVote==1);
	    //Validity time has passed
	    require(cars[ownedCar].validTime > now);
	    //The car has already been approved
	    require(cars[ownedCar].sellApproved==0);
	    approvalState = approvalState + 1;
	    participants[msg.sender].canVote = 0;
	    if(approvalState > (partcpntCount/2)) {
	        cars[ownedCar].sellApproved = 1;
	    }
	}
	
	//Shows the approval state
	function showApprovalState() view public returns(string, uint, string, uint) {
	    return("Approved count: ", approvalState, " Total members: ", partcpntCount);
	}
	
	//Dealer can buy the car he proposed for if the sell is approved
	function sellCar() OnlyDealer payable public {
	    //The car has not been approved to be sold
	    require(cars[ownedCar].sellApproved == 1);
	    //Validity time has expired
	    require(cars[ownedCar].validTime >= now);
	    //The given value is equal to proposed value
	    require(msg.value == cars[ownedCar].sellPrice);
	    totalBalance = totalBalance + msg.value;
        cars[ownedCar].isBought = 0;
        ownedCar = 0;
        carExpensesTimer = block.timestamp; //dont pay expenses for sold car
        emit Status('The car has been sold to the car dealer', msg.sender, block.timestamp);
	}
	
	//Manager set a taxi driver
	function setDriver(address driverAddr) OnlyManager public {
	    require(driverAddr != taxiDriver);
	    taxiDriver = driverAddr;
	    driverSalaryTimer = block.timestamp;
	    emit Status('Manager has set a new taxi driver', taxiDriver, block.timestamp);
	}
	
	//Customers pay for the contract after they use the taxi
	function getCharge() payable public {
	    totalBalance += msg.value;
	    emit Status('A customer has paid for the taxi', msg.sender, block.timestamp);
	}
	
	//Manager pays the salary of taxi driver every month
	function paySalary() OnlyManager public {
	    //Salary time has not come yet
	    require(now >= driverSalaryTimer + 30 days);
        //The contract can not afford to pay the salary
        require(totalBalance >= driverSalary);
        driverSalaryTimer = driverSalaryTimer + 30 days;
        driverBalance = driverBalance + driverSalary;
        totalBalance = totalBalance - driverSalary;
        emit Status('Driver salary has been paid', msg.sender, block.timestamp);
	}
	
	//Driver can transfer his balance to his own account
	function getSalary() OnlyDriver payable public {
	    require(driverBalance > 0 ether);
	    msg.sender.transfer(driverBalance);
	    driverBalance = 0 ether;
	    emit Status('Driver has transferred his money', msg.sender, block.timestamp);
	}
	
	//Manager pays the car expenses every 6 months
	function carExpenses() OnlyManager payable public {
	    //The crew does not have a car
	    require(ownedCar!=0);
	    //Expenses time has not come yet
	    require(now >= carExpensesTimer + 180 days);
	    //The contract can not afford to pay the expenses
	    require(totalBalance >= expenses);
        carExpensesTimer = carExpensesTimer + 180 days;
        carDealer.transfer(expenses);
        totalBalance = totalBalance - expenses;
        emit Status('Car expenses have been paid', msg.sender, block.timestamp);
	}

    //Manager pays the dividend money every 6 months
    function payDividend() OnlyManager public {
        //Dividend pay time has not come yet
        require(now >= payDividendTimer + 180 days);
        //Should pay the expenses first
        require(now < carExpensesTimer + 180 days);
        //Should pay driver salary first
        require(now < driverSalaryTimer + 30 days);
        payDividendTimer = payDividendTimer + 180 days;
        uint dividendMoney;
        dividendMoney = totalBalance / partcpntCount;
        for(uint i=0; i<partcpntCount; i++) {
            participants[partcpntIDs[i].pID].pBalance = participants[partcpntIDs[i].pID].pBalance + dividendMoney;
        }
        totalBalance = 0 ether;
        emit Status('The crew members have got their cut', msg.sender, block.timestamp);
    }

    //Contract member transfer his balance to his account
    function getDividend() payable public {
        require(participants[msg.sender].pBalance > 0 ether);
        msg.sender.transfer(participants[msg.sender].pBalance);
        participants[msg.sender].pBalance = 0 ether;
        emit Status('A crew member has transferred his money', msg.sender, block.timestamp);
    }
    
    //Manager can delegate a new manager
    function setManager(address _newMngr) OnlyManager public {
        require(manager != _newMngr);
        manager = _newMngr;
        emit Status('The contract has a new manager', manager, block.timestamp);
    }
    
    //Fallback function
    function () external{
        revert();
    }

}
