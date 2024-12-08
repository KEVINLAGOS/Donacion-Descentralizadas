// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ClinicaTransfusiones {
    using ECDSA for bytes32;

    address private owner;
    uint256 private usuarioIdCounter;

    struct Usuario {
        string nombre;
        string apellido;
        string direccion;
        uint256 usuarioId;
        string tipoUsuario;
        address clavePublica;
        bytes32 passwordHash;
    }

    mapping(address => Usuario) private usuarios;
    address[] private listaUsuarios;

    modifier soloOwner() {
        require(msg.sender == owner, "Solo el owner puede realizar esta accion");
        _;
    }

    constructor() {
        owner = msg.sender;
        usuarioIdCounter = 1;
    }

    function agregarUsuario(
        string memory _nombre,
        string memory _apellido,
        string memory _direccion,
        string memory _tipoUsuario,
        address _clavePublica,
        string memory _password
    ) public soloOwner {
        require(usuarios[_clavePublica].clavePublica == address(0), "Usuario ya existe");

        if (usuarios[_clavePublica].clavePublica != address(0)) {
            revert("Usuario ya existe, no se realizara la insercion");
        }

        bytes32 passwordHash = keccak256(abi.encodePacked(_password));

        usuarios[_clavePublica] = Usuario({
            nombre: _nombre,
            apellido: _apellido,
            direccion: _direccion,
            usuarioId: usuarioIdCounter,
            tipoUsuario: _tipoUsuario,
            clavePublica: _clavePublica,
            passwordHash: passwordHash
        });

        listaUsuarios.push(_clavePublica);
        usuarioIdCounter++;
    }

    function buscarUsuario(address _clavePublica)
        public
        view
        returns (
            string memory nombre,
            string memory apellido,
            string memory direccion,
            uint256 usuarioId,
            string memory tipoUsuario
        )
    {
        require(usuarios[_clavePublica].clavePublica != address(0), "Usuario no existe");
        Usuario memory usuario = usuarios[_clavePublica];
        return (usuario.nombre, usuario.apellido, usuario.direccion, usuario.usuarioId, usuario.tipoUsuario);
    }

    function eliminarUsuario(address _clavePublica) public soloOwner {
        if (usuarios[_clavePublica].clavePublica == address(0)) {
            revert("Usuario no existe, no se realizara la eliminacion");
        }

        delete usuarios[_clavePublica];

        for (uint256 i = 0; i < listaUsuarios.length; i++) {
            if (listaUsuarios[i] == _clavePublica) {
                listaUsuarios[i] = listaUsuarios[listaUsuarios.length - 1];
                listaUsuarios.pop();
                break;
            }
        }
    }

    function traerTodosLosUsuarios() public view returns (Usuario[] memory) {
        Usuario[] memory result = new Usuario[](listaUsuarios.length);
        for (uint256 i = 0; i < listaUsuarios.length; i++) {
            result[i] = usuarios[listaUsuarios[i]];
        }
        return result;
    }

    function modificarUsuario(
        address _clavePublica,
        string memory _nombre,
        string memory _apellido,
        string memory _direccion,
        string memory _tipoUsuario
    ) public soloOwner {
        if (usuarios[_clavePublica].clavePublica == address(0)) {
            revert("Usuario no existe, no se realizara la modificacion");
        }

        Usuario storage usuario = usuarios[_clavePublica];
        usuario.nombre = _nombre;
        usuario.apellido = _apellido;
        usuario.direccion = _direccion;
        usuario.tipoUsuario = _tipoUsuario;
    }

    function login(address _clavePublica, string memory _password) public view returns (bool) {
        require(usuarios[_clavePublica].clavePublica != address(0), "Usuario no existe");

        bytes32 passwordHash = keccak256(abi.encodePacked(_password));
        require(passwordHash == usuarios[_clavePublica].passwordHash, "Password incorrecto");

        return true; // Login exitoso
    }
}
