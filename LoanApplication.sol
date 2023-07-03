// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoanApplication {
    struct Loan {
        string fullName;
        string addressInfo;
        string phoneNumber;
        string emailAddress;
        uint256 amountRequesting;
        uint256 periodInYears;
        uint256 paymentRequestedDate;
        uint256 amountToAutoDebit;
        uint256 interestRate; // Represented in percentage (e.g., 1.5% as 150)
        bool isApproved;
        bool isPaid;
    }

    mapping(address => Loan) public loans;
    uint256 public loanCount;

    event LoanRequested(address indexed userAddress, uint256 indexed loanId);
    event LoanApproved(address indexed userAddress, uint256 indexed loanId);

    constructor() {
        loanCount = 0;
    }

    function requestLoan(
        string memory _fullName,
        string memory _addressInfo,
        string memory _phoneNumber,
        string memory _emailAddress,
        uint256 _amountRequesting,
        uint256 _periodInYears,
        uint256 _paymentRequestedDate
    ) external {
        require(_amountRequesting > 0, "Loan amount must be greater than 0");

        loans[msg.sender] = Loan(
            _fullName,
            _addressInfo,
            _phoneNumber,
            _emailAddress,
            _amountRequesting,
            _periodInYears,
            _paymentRequestedDate,
            0,
            150, // 1.5% interest rate
            false,
            false
        );

        loanCount++;
        emit LoanRequested(msg.sender, loanCount);
    }

    function approveLoan(address _userAddress, uint256 _amountToAutoDebit) external {
        require(loans[_userAddress].amountRequesting > 0, "Loan not found");
        require(!loans[_userAddress].isApproved, "Loan already approved");

        loans[_userAddress].amountToAutoDebit = _amountToAutoDebit;
        loans[_userAddress].isApproved = true;

        emit LoanApproved(_userAddress, loanCount);
    }

    function calculateInterest(uint256 _amount, uint256 _interestRate) internal pure returns (uint256) {
        return (_amount * _interestRate) / 10000;
    }

    function getInterestAmount(address _userAddress) public view returns (uint256) {
        return calculateInterest(loans[_userAddress].amountRequesting, loans[_userAddress].interestRate);
    }

    function makePayment() external payable {
        Loan storage loan = loans[msg.sender];
        require(loan.isApproved, "Loan not approved");
        require(!loan.isPaid, "Loan already paid");
        require(msg.value == loan.amountToAutoDebit, "Incorrect payment amount");

        uint256 interestAmount = getInterestAmount(msg.sender);
        require(msg.value >= interestAmount, "Insufficient payment amount");

        loan.isPaid = true;

        // Transfer the loan amount to the user
        payable(msg.sender).transfer(loan.amountRequesting);

        // Return any excess payment (interest)
        if (msg.value > loan.amountRequesting) {
            payable(msg.sender).transfer(msg.value - loan.amountRequesting);
        }
    }
}
