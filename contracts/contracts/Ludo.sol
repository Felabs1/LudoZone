// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract LudoZone {
    struct Player {
        address addr;
        uint8[4] pieces; // Positions of the 4 pieces for each player
        bool isActive;
    }

    struct Game {
        Player[4] players;
        uint8 currentTurn;
        bool isActive;
        uint256 lastRollBlock; // New field to store the block number of the last roll
    }

    mapping(uint256 => Game) public games;
    uint256 public gameCount;

    event GameCreated(uint256 gameId);
    event PlayerJoined(uint256 gameId, address player);
    event MoveMade(uint256 gameId, address player, uint8 pieceIndex, uint8 newPosition);
    event GameEnded(uint256 gameId, address winner);

    function createGame() external {
        gameCount++;
        Game storage newGame = games[gameCount];
        newGame.isActive = true;
        newGame.currentTurn = 0;
        newGame.lastRollBlock = block.number;
        
        Player storage creator = newGame.players[0];
        creator.addr = msg.sender;
        creator.isActive = true;

        emit GameCreated(gameCount);
    }

    function joinGame(uint256 _gameId) external {
        require(_gameId <= gameCount && _gameId > 0, "Invalid game ID");
        Game storage game = games[_gameId];
        require(game.isActive, "Game is not active");

        uint8 playerCount = 0;
        for (uint8 i = 0; i < 4; i++) {
            if (game.players[i].isActive) {
                playerCount++;
            } else {
                game.players[i].addr = msg.sender;
                game.players[i].isActive = true;
                emit PlayerJoined(_gameId, msg.sender);
                return;
            }
        }

        require(playerCount < 4, "Game is full");
    }

    function rollDice(uint256 _gameId) internal returns (uint8) {
        Game storage game = games[_gameId];
        require(block.number > game.lastRollBlock, "Wait for the next block to roll again");
        
        game.lastRollBlock = block.number;
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, game.lastRollBlock))) % 6) + 1;
    }

    function makeMove(uint256 _gameId, uint8 _pieceIndex) external {
        Game storage game = games[_gameId];
        require(game.isActive, "Game is not active");
        require(msg.sender == game.players[game.currentTurn].addr, "It's not your turn");
        require(_pieceIndex < 4, "Invalid piece index");

        uint8 diceRoll = rollDice(_gameId);
        uint8 newPosition = game.players[game.currentTurn].pieces[_pieceIndex] + diceRoll;

        // Implement game logic here (e.g., checking for captures, reaching home, etc.)

        game.players[game.currentTurn].pieces[_pieceIndex] = newPosition;
        emit MoveMade(_gameId, msg.sender, _pieceIndex, newPosition);

        // Check for win condition
        if (checkWinCondition(game.players[game.currentTurn])) {
            game.isActive = false;
            emit GameEnded(_gameId, msg.sender);
        } else {
            game.currentTurn = (game.currentTurn + 1) % 4;
        }
    }

    function checkWinCondition(Player storage _player) internal view returns (bool) {
        // Implement win condition logic here
        // For simplicity, let's say a player wins if all pieces reach position 57 or higher
        for (uint8 i = 0; i < 4; i++) {
            if (_player.pieces[i] < 57) {
                return false;
            }
        }
        return true;
    }
}