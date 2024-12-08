// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BloodDonationHistory {

    // Estructura para almacenar cada transacción de transfusión
    struct Transfusion {
        uint256 transactionId;
        address donor;
        address recipient;
        uint256 amount; // Cantidad en wei (equivalente al ml)
        uint256 timestamp; // Marca de tiempo de la transacción
    }

    // Array de transfusiones realizadas
    Transfusion[] public transfusions;

    // Evento para registrar una nueva transfusión
    event TransfusionRecorded(uint256 transactionId, address indexed donor, address indexed recipient, uint256 amount, uint256 timestamp);

    // Función para añadir una nueva transfusión al historial
    function recordTransfusion(uint256 _transactionId, address _donor, address _recipient, uint256 _amount) external {
        transfusions.push(Transfusion({
            transactionId: _transactionId,
            donor: _donor,
            recipient: _recipient,
            amount: _amount,
            timestamp: block.timestamp
        }));

        emit TransfusionRecorded(_transactionId, _donor, _recipient, _amount, block.timestamp);
    }

    // Nueva función: Obtener el historial de transfusiones por dirección de donante o receptor
    function getTransfusionHistoryByAddress(address _address) external view returns (Transfusion[] memory) {
        uint256 count = 0;

        // Contar las transfusiones que involucran la dirección solicitada
        for (uint256 i = 0; i < transfusions.length; i++) {
            if (transfusions[i].donor == _address || transfusions[i].recipient == _address) {
                count++;
            }
        }

        // Crear un nuevo array para almacenar las transfusiones que coincidan
        Transfusion[] memory result = new Transfusion[](count);
        uint256 index = 0;

        // Rellenar el array con las transfusiones que coincidan
        for (uint256 i = 0; i < transfusions.length; i++) {
            if (transfusions[i].donor == _address || transfusions[i].recipient == _address) {
                result[index] = transfusions[i];
                index++;
            }
        }

        return result;
    }
}
