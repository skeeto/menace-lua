--- An implementation of MENACE playing Tic-Tac-Toe

-- While this file only has an implementation for Tic-Tac-Toe, the
-- MENACE implementation can play any game that provides an appropriate
-- "state" interface.

---- Brain

--- A MENACE "brain" is a bunch of matchboxes containing beads
local Brain = {}
Brain.__index = Brain

--- Default Brain configuraition
Brain.default_config = {
    initial_beads = 2  -- number of starting beads for each "color"
}

--- Brain.new([config])
-- Create a new, fresh brain. See Brain.default_config for documentation
-- on the configuration table.
function Brain.new(config)
    local default = Brain.default_config
    if not config then
        config = default
    end
    return setmetatable({
        memory = {},
        initial_beads = config.initial_beads or default.initial_beads
    }, Brain)
end

--- Brain.load(filename [, config])
-- Load a brain previously stored with Brain:dump(), using CONFIG to
-- override options.
function Brain.load(filename, config)
    local loader = loadfile(filename)
    if loader then
        local brain = setmetatable(loader(), Brain)
        if config and config.initial_beads then
            brain.initial_beads = config.initial_beads
        end
        return brain
    end
end

--- Brain:dump([file])
-- Dump the entire brain to a file handle, or to standard output.
function Brain:dump(file)
    file = file or io.output()
    local tokens = {'return {\n'}
    table.insert(tokens, '    initial_beads = ')
    table.insert(tokens, self.initial_beads)
    table.insert(tokens, ',\n    memory = {\n')
    for state, beads in pairs(self.memory) do
        table.insert(tokens, "        ['")
        table.insert(tokens, state)
        table.insert(tokens, "'] = {")
        for j = 1, #beads do
            if j > 1 then
                table.insert(tokens, ', ')
            end
            table.insert(tokens, beads[j])
        end
        table.insert(tokens, '},\n')
    end
    table.insert(tokens, '    }\n}\n')
    file:write(table.concat(tokens))
end

--- Brain.persist(filename)
-- Dump the entire brain to the named file using Brain:dump().
function Brain:persist(filename)
    local file = io.open(filename, 'w')
    self:dump(file)
    file:close()
end

--- Brain:getmoveindex(state)
-- Query the brain for a move for STATE, returning that move's index
-- into the state's option table. The state table must follow the MENACE
-- state protocol.
function Brain:getmoveindex(state)
    local key = tostring(state)
    local beads = self.memory[key]
    if not beads then
        local options = state:options()
        beads = {}
        for i = 1, #options do
            beads[i] = self.initial_beads
        end
        self.memory[tostring(state)] = beads
    end
    local count = 0
    for i = 1, #beads do
        count = count + beads[i]
    end
    if count == 0 then
        print('RESET ' .. tostring(state))
        for i = 1, #beads do
            beads[i] = self.initial_beads
            count = count + self.initial_beads
        end
    end
    local r = math.random(count)
    for i = 1, #beads do
        r = r - beads[i]
        if r <= 0 then
            return i
        end
    end
end

--- Brain:update(state, moveindex, delta)
-- Reward/punish the brain at the given STATE and MOVEINDEX.
function Brain:update(state, moveindex, delta)
    local beads = self.memory[state]
    beads[moveindex] = beads[moveindex] + delta
end

--- run(state, players)
-- Drive a single game to completion given the starting game state and a
-- table of players. The state table must follow the MENACE state
-- protocol. Each player must follow the MENACE player protocol.
function run(state, players)
    local result
    repeat
        local who = state:who()
        local player = players[who]
        local move = player:getmove(state, who)
        state:move(move)
        result = state:result()
    until result
    for who = 1, #players do
        players[who]:finish(state, result, who)
    end
    return result
end

---- Tic-Tac-Toe "state"

--- A Tic-Tac-Toe implementation of the MENACE state protocol.
-- This example also documents the protocol.
local TicTacToe = {}
TicTacToe.__index = TicTacToe

--- Lookup table for the player "names" in both directions.
TicTacToe.names = {'x', 'o'}
TicTacToe.rnames = {x = 1, o = 2}

--- Positions to check for winning conditions.
TicTacToe.checks = {
    1, 2, 3,
    4, 5, 6,
    7, 8, 9,
    1, 4, 7,
    2, 5, 8,
    3, 6, 9,
    1, 5, 9,
    3, 5, 7
}

--- TicTacToe.new()
-- Create a new, empty Tic-Tac-Toe game state.
function TicTacToe.new()
    return setmetatable({
        '.', '.', '.', '.', '.', '.', '.', '.', '.', turn = 0
    }, TicTacToe)
end

--- TicTacToe:options()
-- Returns an array of move values from which a player can choose. One
-- of these values is passed to TicTacToe:move() to advance the game
-- forward one step.
function TicTacToe:options()
    local options = {}
    for i = 1, 9 do
        if self[i] == '.' then
            options[#options + 1] = i
        end
    end
    return options
end

--- TicTacToe:move(movevalue)
-- Advance the state by this move. This value must be one listed in
-- TicTacToe:options().
function TicTacToe:move(n)
    local who = TicTacToe.names[1 + self.turn % 2]
    self.turn = self.turn + 1
    self[n] = who
end

--- TicTacToe:who()
-- Indicate whose turn it is, 1..n.
function TicTacToe:who()
    return 1 + self.turn % 2
end

--- TicTacToe:result()
-- Return the final game result, or nil if the game is not yet finished.
-- A return of 0 indicates a tie, and 1..n is the number of the player
-- who won.
function TicTacToe:result()
    local checks = TicTacToe.checks
    for i = 0, 7 do
        local a = self[checks[1 + i * 3]]
        local b = self[checks[2 + i * 3]]
        local c = self[checks[3 + i * 3]]
        if a ~= '.' and a == b and a == c then
            return TicTacToe.rnames[a]
        end
    end
    for i = 1, 9 do
        if self[i] == '.' then
            return nil
        end
    end
    return 0
end

--- TicTacToe:__tostring()
-- A game state must evaluate to a suitable key for use in a table. This
-- string key must contain the entire game state.
function TicTacToe:__tostring()
    return table.concat(self)
end

--- TicTacToe:pretty([query])
-- Return a nice, human-friendly display of the game state, for use in
-- interactive play. If QUERY is true, it must indicate to the player
-- the available options. This implementation uses ANSI escapes for
-- color.
function TicTacToe:pretty(query)
    local tokens = {'-----\n'}
    for i = 1, 9 do
        local who = self[i]
        local color = '\x1b[0;37m'
        if who == 'x' then
            color = '\x1b[92;1m'
        elseif who == 'o' then
            color = '\x1b[93;1m'
        elseif query then
            who = i
        end
        table.insert(tokens, color)
        table.insert(tokens, who)
        if (i % 3 == 0) then
            table.insert(tokens, '\n')
        else
            table.insert(tokens, ' ')
        end
    end
    table.insert(tokens, '\x1b[0m')
    return table.concat(tokens)
end

---- HumanPlayer

--- Interacts with a human and proves the MENACE player protocol.
local HumanPlayer = {}
HumanPlayer.__index = HumanPlayer

--- HumanPlayer.new()
function HumanPlayer.new()
    return setmetatable({}, HumanPlayer)
end

--- HumanPlayer:getmove(state)
-- Returns the move value selected by the player. The state object is
-- not modified.
function HumanPlayer:getmove(state)
    local options = state:options()
    local valid = {}
    for i = 1, #options do
        valid[options[i]] = true
    end
    local output = io.output()
    local input = io.input()
    output:write(state:pretty(true))
    output:write('>>> ')
    output:flush()
    local move
    repeat
        move = input:read('n')
    until valid[move]
    return move
end

--- HumanPlayer:finish(state, result, me)
-- Indicate to the player that the game has completed, providing the
-- final game state, who won (state:result()), and which player you
-- were. Expects the game state to have a "names" field.
function HumanPlayer:finish(state, result, me)
    io.write(state:pretty())
    if result == 0 then
        print('Game over: tied')
    else
        print('Game over: ' .. state.names[result] .. ' wins')
    end
end

---- BrainPlayer

--- Adaptor for a Brain, providing the MENACE player protocol.
-- When the game is complete, the brain is punished or rewarded
-- according to the result.
local BrainPlayer = {}
BrainPlayer.__index = BrainPlayer

--- BrainPlayer.new(brain)
-- Creates a player that gets its moves from BRAIN.
function BrainPlayer.new(brain)
    return setmetatable({brain = brain, moves = {}}, BrainPlayer)
end

--- BrainPlayer:getmove(state)
function BrainPlayer:getmove(state)
    local moveindex = self.brain:getmoveindex(state)
    local options = state:options()
    table.insert(self.moves, {state = tostring(state), moveindex = moveindex})
    return options[moveindex]
end

--- BrainPlayer:finish(state, result, me)
-- Punishes or rewards the brain according the result.
function BrainPlayer:finish(state, result, me)
    local moves = self.moves
    local delta
    if result == 0 then
        delta = 1
    elseif result ~= me then
        delta = -1
    else
        delta = 3
    end
    for i = 1, #moves do
        local state = moves[i].state
        local moveindex = moves[i].moveindex
        self.brain:update(state, moveindex, delta)
    end
end

---- Option parsing

--- getopt(argv, optstring [, nonoptions])
--
-- Returns a closure suitable in "for ... in" loops. Each time the
-- closure is called, it returns the next (option, optarg). For unknown
-- options, it returns ('?', option). When the optarg is missing,
-- returns (':', option).
--
-- Non-option arguments are accumulated, in order, in the "nonoptions"
-- table.
--
-- The original argv table is unmodified.
function getopt(argv, optstring, nonoptions)
    local optind = 1
    local optpos = 2
    nonoptions = nonoptions or {}
    return function()
        while true do
            local arg = argv[optind]
            if arg == nil or arg == '--' then
                return nil
            elseif arg:sub(1, 1) == '-' then
                local opt = arg:sub(optpos, optpos)
                local start, stop = optstring:find(opt .. ':?')
                if not start then
                    optind = optind + 1
                    optpos = 2
                    return '?', opt
                elseif stop > start and #arg > optpos then
                    local optarg = arg:sub(optpos + 1)
                    optind = optind + 1
                    optpos = 2
                    return opt, optarg
                elseif stop > start then
                    local optarg = argv[optind + 1]
                    optind = optind + 2
                    optpos = 2
                    if optarg == nil then
                        return ':', opt
                    end
                    return opt, optarg
                else
                    optpos = optpos + 1
                    if optpos > #arg then
                        optind = optind + 1
                        optpos = 2
                    end
                    return opt, nil
                end
            else
                optind = optind + 1
                table.insert(nonoptions, arg)
            end
        end
    end
end

---- Main user interface

function usage()
    print('Usage: menace.lua [-hir] [-b BRAIN] [-n COUNT] [-s SEED]')
    print('  -b BRAIN    use brain from the given use')
    print('  -h          print this help message')
    print('  -i          play interactively against the AI')
    print('  -r          read-only: do not save playouts')
    print('  -s SEED     use the given random seed')
    print('  -n          number of games to playout (non-interactive)')
end

local brainfile = 'brain.lua'
local interactive = false
local readonly = false
local ngames = 500000
local seed = os.time()

for opt, arg in getopt(arg, 'b:hirn:') do
    if opt == 'b' then
        brainfile = arg
    elseif opt == 'h' then
        usage()
        os.exit(0)
    elseif opt == 'i' then
        interactive = true
    elseif opt == 'r' then
        readonly = true
    elseif opt == 's' then
        seed = tonumber(arg)
    elseif opt == 'n' then
        ngames = tonumber(arg)
    elseif opt == ':' then
        print('error: missing argument: -' .. arg)
        usage()
        os.exit(1)
    elseif opt == '?' then
        print('error: unknown option: -' .. arg)
        usage()
        os.exit(1)
    end
end

math.randomseed(seed)

if interactive then
    -- Play against a human
    local brain = Brain.load(brainfile)
    if not brain then
        print('brain could not be loaded, creating a new one')
        brain = Brain.new()
    end
    while true do
        local state = TicTacToe.new()
        local players 
        if math.random(2) == 1 then
            players = {BrainPlayer.new(brain), HumanPlayer.new()}
        else
            players = {HumanPlayer.new(), BrainPlayer.new(brain)}
        end
        run(state, players)
        if not readonly then
            brain:persist(brainfile)
        end
    end
else
    -- Play against itself
    local config = {initial_beads = 256}
    local brain = Brain.load(brainfile, config)
    if not brain then
        print('brain could not be loaded, creating a new one')
        brain = Brain.new(config)
    end
    local ratio = {0, 0, 0}
    for i = 1, ngames do
        local state = TicTacToe.new()
        local players = {BrainPlayer.new(brain), BrainPlayer.new(brain)}
        local result = run(state, players)
        ratio[result + 1] = ratio[result + 1] + 1
    end
    print('ties=' .. ratio[1] .. ' x=' .. ratio[2] .. ' y=' .. ratio[3])
    brain:persist(brainfile)
end
