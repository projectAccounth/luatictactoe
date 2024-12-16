local ticTacToe = {};
ticTacToe.__index = ticTacToe;

local MIN_BOARD_SIZE = 3;

-- Helper function for string formatting
function f(str)
   local outer_env = _ENV
   return (str:gsub("%b{}", function(block)
      local code = block:match("{(.*)}")
      local exp_env = {}
      setmetatable(exp_env, { __index = function(_, k)
         local stack_level = 5
         while debug.getinfo(stack_level, "") ~= nil do
            local i = 1
            repeat
               local name, value = debug.getlocal(stack_level, i)
               if name == k then
                  return value
               end
               i = i + 1
            until name == nil
            stack_level = stack_level + 1
         end
         return rawget(outer_env, k)
      end })
      local fn, err = load("return "..code, "expression `"..code.."`", "t", exp_env)
      if fn then
         return tostring(fn())
      else
         error(err, 0)
      end
   end))
end
-- Helper function for filling the board
function fillBoard(boardSizeX, boardSizeY)
	if boardSizeX < MIN_BOARD_SIZE then boardSizeX = MIN_BOARD_SIZE; end
	if boardSizeY < MIN_BOARD_SIZE then boardSizeY = MIN_BOARD_SIZE; end
	local board = {};
	for y = 1, boardSizeX do
		board[y] = {};
		for x = 1, boardSizeY do
			board[y][x] = 0;
		end
	end
	return board;
end
-- Checking the rows and columns for wins
function checkLines(cGame, symbol, matchLength)
	local size = #cGame
	for i = 1, size do
		local rowMatch = 0
		local colMatch = 0
		for j = 1, size do
			if cGame[i][j] == symbol then
				rowMatch = rowMatch + 1
				if rowMatch == matchLength then return true end
			else
				rowMatch = 0
			end

			if cGame[j][i] == symbol then
				colMatch = colMatch + 1
				if colMatch == matchLength then return true end
			else
				colMatch = 0
			end
		end
	end
	return false
end
-- Checking diagonals for wins
function checkDiagonals(cGame, symbol, matchLength)
	local size = #cGame
	for i = 1, size - matchLength + 1 do
		for j = 1, size - matchLength + 1 do
			local mainDiagMatch = 0
			local antiDiagMatch = 0

			for k = 0, matchLength - 1 do
				-- Main diagonal
				if cGame[i + k][j + k] == symbol then
					mainDiagMatch = mainDiagMatch + 1
					if mainDiagMatch == matchLength then return true end
				else
					mainDiagMatch = 0
				end
				if cGame[i + k][j + matchLength - k - 1] == symbol then
					antiDiagMatch = antiDiagMatch + 1
					if antiDiagMatch == matchLength then return true end
				else
					antiDiagMatch = 0
				end
			end
		end
	end
	return false
end

--[[
Creates a new tic-tac-toe game. Player 1 will be X, Player 2 will be O.

Parameters:

boardSizeX: The number of columns.
boardSizeY: The number of rows.
matchLength: The number of length that is required for a player to win a game.

Members:

board: 2D array representing the current position.
isGameOver: Whether the game is over or not.
isXTurn: Whether it is X's turn or not.
isOTurn: Whether it is O's turn or not.
isPositionInvalid: Whether the position is invalid or not.
isDraw: Whether the game is a draw or not.
winner: The winner of the game.
boardSizeX: The number of columns.
boardSizeY: The number of rows.
matchLength: The number of length that is required for a player to win a game.

Member methods:

new: Creates a new game.
checkXWin: Checks whether X has won or not. Included in checkGameState()
checkOWin: Checks whether O has won or not. Included in checkGameState()
move: Make a move for the player.
ascii: Represents the board in text format (ASCII).
checkGameState: Checks the current state of the game.

]]
function ticTacToe:new(boardSizeX, boardSizeY, matchLength)
	if (boardSizeX < MIN_BOARD_SIZE) then boardSizeX = MIN_BOARD_SIZE; end
	if (boardSizeY < MIN_BOARD_SIZE) then boardSizeY = MIN_BOARD_SIZE; end
	if (matchLength < 3) then matchLength = 3; end
	local obj = {
		board = fillBoard(boardSizeX, boardSizeY),
		isGameOver = false,
		isXTurn = true,
		isOTurn = false,
		isPositionInvalid = false,
		isDraw = false,
		winner = "",
		boardSizeX = boardSizeX,
		boardSizeY = boardSizeY,
		matchLength = matchLength,
		previousPositions = {fillBoard(boardSizeX, boardSizeY)},
		previousMoves = {}
	};
	if (obj.boardSizeX < matchLength or obj.boardSizeY < matchLength) then error("Invalid match length") end
	setmetatable(obj, ticTacToe);
	return obj;
end

-- Member function to check whether X wins or not. Recommended to use checkGameState(), if you don't want to implement your own function.
function ticTacToe:checkXWin()
	return checkDiagonals(self.board, 2, self.matchLength) or checkLines(self.board, 2, self.matchLength);
end
-- Member function to check whether O wins or not. Recommended to use checkGameState(), if you don't want to implement your own function.
function ticTacToe:checkOWin()
	return checkDiagonals(self.board, 1, self.matchLength) or checkLines(self.board, 1, self.matchLength);
end

-- Void function that determines the current state of the game. Updates everything in the game, but does not return anything.
function ticTacToe:checkGameState()
	if self:checkOWin() and self:checkXWin() then self.isPositionInvalid = true; return; end
	if self:checkXWin() or self:checkOWin() then self.isGameOver = true; end
	if self:checkXWin() then self.winner = "X" end
	if self:checkOWin() then self.winner = "O" end
	local emptyCells = self.boardSizeX * self.boardSizeY;
	for i = 1, self.boardSizeY do
		for j = 1, self.boardSizeX do
			if (self.board[i][j] ~= 0) then emptyCells = emptyCells - 1; end
		end
	end
	if emptyCells == 0 then self.isDraw = true; self.isGameOver = true; end
end
--[[
Makes a move for the current side. You can check the current side with the isXTurn and isOTurn booleans.
The move will only be made if one of the boolean is true, the other one is false.

Parameters:
positionX: The X position your piece will be placed at. Raises an error if the input is out of range.
positionY: The Y position your piece will be placed at. Raises an error if the input is out of range.
]]
function ticTacToe:move(positionX, positionY)
	if (self.isXTurn and self.isOTurn) or (not (self.isXTurn) and not (self.isOTurn)) then error("Both players cannot have the same turn || cannot have no turns"); end
	if (positionX > self.boardSizeX) or (positionY > self.boardSizeY) or (positionX < 1) or (positionY < 1) then
		warn("Invalid input given: ", positionX, " ", positionY);
		return;
	end
	self:checkGameState();
	if self.isGameOver then warn("Game is already over"); return; end
	if self.isPositionInvalid then warn("Position is invalid"); return; end
	if self.board[positionY][positionX] ~= 0 then print("Occupied cell"); return; end
	if self.isXTurn then
		self.board[positionY][positionX] = 2;
		self.isXTurn = not self.isXTurn;
		self.isOTurn = not self.isOTurn;
		table.insert(self.previousPositions, self.board);
		table.insert(self.previousMoves, {positionX, positionY});
	elseif self.isOTurn then
		self.board[positionY][positionX] = 1;
		self.isXTurn = not self.isXTurn;
		self.isOTurn = not self.isOTurn;
		table.insert(self.previousPositions, self.board);
		table.insert(self.previousMoves, {positionX, positionY});
	end
	self:checkGameState();
end

--[[
Resets the game to its default state.
If you have already created a board in workspace, you have to recreate them by calling boardToRealWorld() manually.
]]
function ticTacToe:reset()
	self.board = fillBoard(self.boardSizeX, self.boardSizeY);
	self.isGameOver = false;
	self.isXTurn = true;
	self.isOTurn = false;
	self.isPositionInvalid = false;
	self.isDraw = false;
	self.winner = "";
	self.previousPositions = {fillBoard(self.boardSizeX, self.boardSizeY)};
	self:checkGameState();
end

function ticTacToe:makeMove(move, player)
    self.board[move[2]][move[1]] = player
end

function ticTacToe:undoMove(move)
    self.board[move[2]][move[1]] = 0
end

function ticTacToe:getAvailableMoves()
    local moves = {}
    for y = 1, self.boardSizeY do
        for x = 1, self.boardSizeX do
            if self.board[y][x] == 0 then
                table.insert(moves, {x, y})
            end
        end
    end
    return moves
end

--[[
Evaluates the current board.
If the position is bad for the evaluated side, a negative scored is returned, and the other way around.

Parameter:
forX: A boolean, indicates whether the position is evaluated for X or for O. If true, the position is evaluated in X's perspective. Otherwise, the position is evaluated in O's perspective.

]]
function ticTacToe:evaluatePosition(forX)
    local opponent = (forX) and 1 or 2
    local score = 0

    -- Helper to evaluate a single line
    local function evaluateLine(line)
        local playerCount = 0
        local opponentCount = 0

        for _, cell in ipairs(line) do
            if cell == player then
                playerCount = playerCount + 1
            elseif cell == opponent then
                opponentCount = opponentCount + 1
            end
        end

        if opponentCount > 0 and playerCount > 0 then
            return 0 -- Blocked line
        elseif playerCount > 0 then
            -- Score based on playerCount
            return 10 ^ (playerCount - 1)
        elseif opponentCount > 0 then
            -- Penalize based on opponentCount
            return -(10 ^ (opponentCount - 1))
        end

        return 0 -- Empty line
    end

    -- Evaluate all rows
    for i = 1, self.boardSizeX do
        for j = 1, (self.boardSizeX - self.matchLength + 1) do
            local line = {}
            for k = 0, self.matchLength - 1 do
                table.insert(line, self.board[i][j + k])
            end
            score = score + evaluateLine(line)
        end
    end

    -- Evaluate all columns
    for j = 1, self.boardSizeX do
        for i = 1, self.boardSizeX - self.matchLength + 1 do
            local line = {}
            for k = 0, self.matchLength - 1 do
                table.insert(line, self.board[i + k][j])
            end
            score = score + evaluateLine(line)
        end
    end

    -- Evaluate main diagonals
    for i = 1, self.boardSizeX - self.matchLength + 1 do
        for j = 1, self.boardSizeX - self.matchLength + 1 do
            local line = {}
            for k = 0, self.matchLength - 1 do
                table.insert(line, self.board[i + k][j + k])
            end
            score = score + evaluateLine(line)
        end
    end

    -- Evaluate anti-diagonals
    for i = 1, self.boardSizeX - self.matchLength + 1 do
        for j = self.matchLength, self.boardSizeX do
            local line = {}
            for k = 0, self.matchLength - 1 do
                table.insert(line, self.board[i + k][j - k])
            end
            score = score + evaluateLine(line)
        end
    end

    return score
end

function ticTacToe:minimax(depth, isMaximizing, alpha, beta)
    -- Base case: Check if the game is over or the depth limit is reached
    if self:checkXWin() then
        return 1000 - depth -- Prioritize quicker wins for X
    elseif self:checkOWin() then
        return -1000 + depth -- Penalize quicker losses for X
    elseif self.isDraw then
        return 0 -- Draw
    elseif depth == 0 then
        return self:evaluatePosition(isMaximizing)
    end

    -- Recursive case: Maximize or minimize the score
    local bestScore
    if isMaximizing then
        bestScore = -math.huge
        for _, move in ipairs(self:getAvailableMoves()) do
            self:makeMove(move, 2) -- X makes a move
            local score = self:minimax(depth - 1, false, alpha, beta)
            self:undoMove(move)
            bestScore = math.max(bestScore, score)
            alpha = math.max(alpha, score)
            if beta <= alpha then break end -- Alpha-beta pruning
        end
    else
        bestScore = math.huge
        for _, move in ipairs(self:getAvailableMoves()) do
            self:makeMove(move, 1) -- O makes a move
            local score = self:minimax(depth - 1, true, alpha, beta)
            self:undoMove(move)
            bestScore = math.min(bestScore, score)
            beta = math.min(beta, score)
            if beta <= alpha then break end -- Alpha-beta pruning
        end
    end
    return bestScore
end

function ticTacToe:getBestMove(forX, depth)
    local bestMove = nil
    local bestScore = forX and -math.huge or math.huge
    local alpha = -math.huge
    local beta = math.huge

    for _, move in ipairs(self:getAvailableMoves()) do
        self:makeMove(move, forX and 2 or 1) -- Simulate move
        local score = self:minimax(depth - 1, not forX, alpha, beta)
        self:undoMove(move)

        if forX then
            if score > bestScore then
                bestScore = score
                bestMove = move
            end
            alpha = math.max(alpha, bestScore)
        else
            if score < bestScore then
                bestScore = score
                bestMove = move
            end
            beta = math.min(beta, bestScore)
        end

        if beta <= alpha then break end -- Alpha-beta pruning
    end

    return bestMove
end

function ticTacToe:ascii()
	local boardSize = #self.board;
    local asciiBoard = "";

    for i = 1, boardSize do
        for j = 1, boardSize do
            local cell = self.board[i][j];
            if cell == 0 then
                asciiBoard = asciiBoard .. " "; -- Empty cell
            elseif cell == 1 then
                asciiBoard = asciiBoard .. "O"; -- Player O
            elseif cell == 2 then
                asciiBoard = asciiBoard .. "X"; -- Player X
            end

            if j < boardSize then
                asciiBoard = asciiBoard .. "|"; -- Column separator
            end
        end

        if i < boardSize then
            asciiBoard = asciiBoard .. "\n" .. string.rep("-", boardSize * 2 - 1) .. "\n"; -- Row separator
        end
    end

    return asciiBoard;
end

--[[
Gets the result of the game, similiar to chess's PGN notation, with moves indexing. 1-0 indicates X win, 0-1 indicates O win, and 1/2-1/2 indicates a draw (if the game is over).

Notation:

<moveNumber>. <moveX>-<moveY>

Returns a string.
]]
function ticTacToe:getResult()
	if #self.previousMoves == 0 then return ""; end
	local moveArray = {};
	local result = "";
	for i = 1, #self.previousMoves, 2 do
		if i + 1 <= #self.previousMoves then
			local k1 = f"{self.previousMoves[i][1]}-{self.previousMoves[i][2]}";
			local k2 = f"{self.previousMoves[i + 1][1]}-{self.previousMoves[i + 1][2]}";
			table.insert(moveArray, f"{k1} {k2}");
		else
			local k1 = f"{self.previousMoves[i][1]}-{self.previousMoves[i][2]}";
			table.insert(moveArray, f"{k1}");
		end
	end
	for i = 1, #moveArray do
		result = result .. tonumber(i) .. ". " .. moveArray[i] .. '\n';
	end
	if (self.isGameOver) then
		if (self.winner == "X") then
			result = result .. "1-0";
		elseif (self.winner == "O") then
			result = result .. "0-1";
		else
			result = result .. "1/2-1/2";
		end
	end
	return result;
end

return ticTacToe
