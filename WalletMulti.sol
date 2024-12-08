// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBloodDonationHistory {
    function recordTransfusion(uint256 _transactionId, address _donor, address _recipient, uint256 _amount) external;
}

contract BloodDonationMultiSig {
    address[] public owners;
    uint public requiredApprovals;
    mapping(address => bool) public isOwner;
    IBloodDonationHistory public bloodDonationHistory; 

    enum TransactionState { Pending, Approved, Executed }

    struct Transaction {
        address to; // Destinatario
        uint amount; // Cantidad en Wei (representando la donación de sangre)
        uint approvalCount; // Número de aprobaciones
        bool executed; // Estado de la transacción
        TransactionState state; // Estado de la transacción
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals; 
    event TransactionSubmitted(uint transactionId, address indexed to, uint amount);
    event TransactionApproved(uint transactionId, address indexed owner);
    event TransactionExecuted(uint transactionId, address indexed to, uint amount);
    event Deposit(address indexed sender, uint amount);

    constructor(address[] memory _owners, uint _requiredApprovals, address _bloodDonationHistoryAddress) {
        require(_owners.length > 0, "Debe haber al menos un owner");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "Numero invalido de aprobaciones");
        require(_bloodDonationHistoryAddress != address(0), "Direccion de historial invalida");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Direccion de owner invalida");
            require(!isOwner[owner], "Owner duplicado");

            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredApprovals = _requiredApprovals;
        bloodDonationHistory = IBloodDonationHistory(_bloodDonationHistoryAddress);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "No es un owner");
        _;
    }

    function submitTransaction(address _to, uint _amount) public onlyOwner {
        transactions.push(Transaction({
            to: _to,
            amount: _amount,
            approvalCount: 0,
            executed: false,
            state: TransactionState.Pending
        }));

        emit TransactionSubmitted(transactions.length - 1, _to, _amount);
    }

    function approveTransaction(uint _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(!transaction.executed, "La transaccion ya fue ejecutada");
        require(!approvals[_transactionId][msg.sender], "Ya aprobaste esta transaccion");

        approvals[_transactionId][msg.sender] = true;
        transaction.approvalCount += 1;

        if (transaction.approvalCount >= requiredApprovals) {
            transaction.state = TransactionState.Approved;
        }

        emit TransactionApproved(_transactionId, msg.sender);
    }

    function executeTransaction(uint _transactionId) public onlyOwner {
        Transaction storage transaction = transactions[_transactionId];
        require(transaction.state == TransactionState.Approved, "No se han aprobado suficientes transacciones");
        require(!transaction.executed, "La transaccion ya fue ejecutada");

        transaction.executed = true;
        transaction.state = TransactionState.Executed;

        (bool success, ) = transaction.to.call{value: transaction.amount}("");
        require(success, "Fallo en la transferencia de fondos");

        emit TransactionExecuted(_transactionId, transaction.to, transaction.amount);

        bloodDonationHistory.recordTransfusion(_transactionId, msg.sender, transaction.to, transaction.amount);
    }

    function deposit() public payable {
        require(msg.value > 0, "Debe enviar un valor mayor a 0");
        emit Deposit(msg.sender, msg.value);
    }

    function getTransaction(uint _transactionId) public view returns (address to, uint amount, uint approvalCount, bool executed, TransactionState state) {
        Transaction storage transaction = transactions[_transactionId];
        return (transaction.to, transaction.amount, transaction.approvalCount, transaction.executed, transaction.state);
    }

    function getTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }
}
