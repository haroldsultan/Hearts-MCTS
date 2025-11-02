import Foundation

// NOTE: The Card, Suit, Rank, Player, and relevant properties (isTwoOfClubs, points)
// MUST be defined in your main project files.
// Card must be Comparable for the Hashable implementation to be stable.

// MARK: - HeartsGameState
// This is the model the MCTS uses internally for simulation.
struct HeartsGameState: Equatable, Hashable {
    
    // Assumed Helper: RuleValidator.getLegalCards
    class RuleValidator {
        /**
         Calculates the set of cards legal to play based on the current trick state.
         The logic here MUST be accurate to ensure MCTS simulations are valid.
         */
        static func getLegalCards(hand: [Card], playedCards: [(playerIndex: Int, card: Card)], heartsBroken: Bool, isFirstTrick: Bool) -> [Card] {
            guard !hand.isEmpty else { return [] }

            // --- 1. Leading the Trick ---
            if playedCards.isEmpty {
                
                if isFirstTrick && hand.contains(where: { $0.isTwoOfClubs }) {
                    return hand.filter { $0.isTwoOfClubs }
                }
                
                let canLeadHearts = heartsBroken || hand.allSatisfy { $0.suit == .hearts }
                let nonHeartLeads = hand.filter { $0.suit != .hearts }
                
                if canLeadHearts {
                    return hand
                } else {
                    if nonHeartLeads.isEmpty {
                        return hand.filter { $0.suit == .hearts }
                    }
                    return nonHeartLeads
                }
            }

            // --- 2. Following the Trick ---
            
            let leadSuit = playedCards[0].card.suit
            let followSuit = hand.filter { $0.suit == leadSuit }

            if !followSuit.isEmpty {
                return followSuit // Must follow suit
            } else {
                // Void in suit (Sloughing)
                if isFirstTrick {
                    let pointCards = hand.filter { $0.points > 0 }
                    if hand.count == pointCards.count {
                        return hand
                    }
                    let nonPointCards = hand.filter { $0.points == 0 }
                    return nonPointCards
                }
                return hand // Otherwise, any card is legal to slough
            }
        }
    }


    var playersHands: [[Card]]
    var playedCardsThisRound: [Card]
    var currentTrick: [(playerIndex: Int, card: Card)]
    var heartsBroken: Bool
    var currentPlayer: Int
    var wonCards: [[Card]]

    // MARK: - Equatable & Hashable (Only uses critical game flow elements)
    static func == (lhs: HeartsGameState, rhs: HeartsGameState) -> Bool {
        let tricksEqual = lhs.currentTrick.elementsEqual(rhs.currentTrick) { t1, t2 in
            return t1.playerIndex == t2.playerIndex && t1.card == t2.card
        }
        return lhs.playersHands == rhs.playersHands &&
            tricksEqual &&
            lhs.heartsBroken == rhs.heartsBroken &&
            lhs.currentPlayer == rhs.currentPlayer
    }

    func hash(into hasher: inout Hasher) {
        for hand in playersHands {
            for card in hand.sorted() {
                hasher.combine(card)
            }
        }
        for (index, card) in currentTrick { hasher.combine(index); hasher.combine(card) }
        hasher.combine(heartsBroken)
        hasher.combine(currentPlayer)
    }

    func legalMoves() -> [Card] {
        guard !playersHands[currentPlayer].isEmpty else { return [] }
        let isFirstTrick = playedCardsThisRound.isEmpty && currentTrick.isEmpty
        
        return RuleValidator.getLegalCards(
            hand: playersHands[currentPlayer],
            playedCards: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: isFirstTrick
        )
    }

    func playCard(_ card: Card) -> HeartsGameState {
        var nextHands = playersHands
        nextHands[currentPlayer].removeAll { $0 == card }

        var nextTrick = currentTrick
        nextTrick.append((currentPlayer, card))

        var nextPlayer = (currentPlayer + 1) % 4
        var nextWonCards = wonCards
        var nextPlayedCards = playedCardsThisRound

        var nextHeartsBroken = heartsBroken
        
        if !nextHeartsBroken && card.suit == .hearts {
            nextHeartsBroken = true
        }

        if nextTrick.count == 4 {
            let leadSuit = nextTrick[0].card.suit
            
            let winnerTuple = nextTrick
                .filter { $0.card.suit == leadSuit }
                .max { $0.card.rank.value < $1.card.rank.value }!

            let winnerIndex = winnerTuple.playerIndex
            let trickCards = nextTrick.map { $0.card }
            
            nextWonCards[winnerIndex].append(contentsOf: trickCards)
            nextPlayedCards.append(contentsOf: trickCards)
            
            nextTrick = []
            nextPlayer = winnerIndex
        }

        return HeartsGameState(
            playersHands: nextHands,
            playedCardsThisRound: nextPlayedCards,
            currentTrick: nextTrick,
            heartsBroken: nextHeartsBroken,
            currentPlayer: nextPlayer,
            wonCards: nextWonCards
        )
    }
    
    func isTerminal() -> Bool {
        return playersHands.allSatisfy { $0.isEmpty }
    }
    
    func score(for playerIndex: Int, rawPoints: [Int], moonShooter: Int?) -> Int {
        let totalPossiblePoints = 26
        
        if let shooterIndex = moonShooter {
            if shooterIndex == playerIndex {
                // If this player shot the moon, they score 0
                return 0
            } else {
                // If any other player shot the moon, this player scores 26
                return totalPossiblePoints
            }
        } else {
            // Standard scoring: score is simply the points taken
            return rawPoints[playerIndex]
        }
    }
}

// MARK: - MCTS Node
class MCTSNode {
    let state: HeartsGameState
    weak var parent: MCTSNode?
    var children: [MCTSNode] = []
    var visits: Int = 0
    var totalScore: Double = 0.0
    var untriedMoves: [Card]

    init(state: HeartsGameState, parent: MCTSNode? = nil) {
        self.state = state
        self.parent = parent
        self.untriedMoves = state.legalMoves()
    }

    /** The UCT Value calculation. */
    func uctValue(totalParentVisits: Int, exploration: Double = 0.7) -> Double {
        guard visits > 0 else { return Double.infinity }
        return (totalScore / Double(visits)) + exploration * sqrt(log(Double(totalParentVisits)) / Double(visits))
    }

    func bestChild() -> MCTSNode? {
        return children.max { $0.uctValue(totalParentVisits: visits) < $1.uctValue(totalParentVisits: visits) }
    }
    
    func bestMove() -> Card? {
        return children.max { ($0.totalScore / Double($0.visits)) < ($1.totalScore / Double($1.visits)) }?
            .state.currentTrick.last?.card
    }
}

// MARK: - Hearts MCTS AI (Balanced Strategy)
class AIPlayingStrategy {

    static var MCTSCache: [HeartsGameState: MCTSNode] = [:]
    static var terminalCache: [HeartsGameState: Double] = [:]

    // --- STATE CREATION (ROOT NODE) ---
    private static func createRootState(
        playerIndex: Int,
        players: [Player],
        playedCardsThisRound: [Card],
        currentTrick: [(playerIndex: Int, card: Card)],
        heartsBroken: Bool,
        difficulty: DifficultyLevel
    ) -> HeartsGameState {
        
        var handsForRoot: [[Card]] = Array(repeating: [], count: 4)

        if difficulty == .hard {
            // Hard: Perfect information. Use the hands exactly as provided.
            handsForRoot = players.map { $0.hand }
        } else {
            // Easy/Medium: Impersonal information (AI knows its hand, others are scrambled)
            
            var opponentCards: [Card] = []
            var opponentInfo: [(index: Int, size: Int)] = []

            for i in 0..<4 {
                if i == playerIndex {
                    // AI's hand is accurate
                    handsForRoot[i] = players[i].hand
                } else {
                    // Collect all opponent cards for scrambling
                    opponentCards.append(contentsOf: players[i].hand)
                    opponentInfo.append((index: i, size: players[i].hand.count))
                }
            }
            
            // Scramble all opponent cards
            opponentCards.shuffle()
            
            // Redistribute the scrambled cards back into the opponent slots, maintaining hand sizes
            var currentCardIndex = 0
            for info in opponentInfo {
                let opponentHand = Array(opponentCards[currentCardIndex..<(currentCardIndex + info.size)])
                handsForRoot[info.index] = opponentHand
                currentCardIndex += info.size
            }
        }
        
        return HeartsGameState(
            playersHands: handsForRoot,
            playedCardsThisRound: playedCardsThisRound,
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            currentPlayer: playerIndex,
            wonCards: players.map { $0.wonCards }
        )
    }
    
    private static func selectBiasedUntriedMove(moves: [Card]) -> Card? {
        guard !moves.isEmpty else { return nil }

        let scores = moves.map { card -> (card: Card, weight: Double) in
            let rawScore = Double(card.points * 10 + card.rank.value)
            // Weight favors lower score (safer cards)
            let weight = 1.0 / (1.0 + rawScore)
            return (card: card, weight: weight)
        }

        let totalWeight = scores.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return moves.randomElement() }
        
        var randomValue = Double.random(in: 0.0...totalWeight)

        for score in scores {
            randomValue -= score.weight
            if randomValue <= 0 {
                return score.card
            }
        }
        return moves.randomElement()
    }
    
    // --- MAIN AI STRATEGY ---
    static func selectCard(playerIndex: Int,
                             players: [Player],
                             currentTrick: [(playerIndex: Int, card: Card)],
                             heartsBroken: Bool,
                             playedCardsThisRound: [Card],
                             iterations: Int, // Retained but overridden by difficulty
                             difficulty: DifficultyLevel = .hard) -> Card? {
            
        let legalMoves = HeartsGameState.RuleValidator.getLegalCards(
            hand: players[playerIndex].hand,
            playedCards: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: playedCardsThisRound.isEmpty && currentTrick.isEmpty
        )
            
        guard let firstMove = legalMoves.first, legalMoves.count > 1 else { return legalMoves.first }
            
        // Clear caches for the current high-level move
        MCTSCache = [:]
        terminalCache = [:]

        // Create the single, deterministic/simulated state based on difficulty
        let rootState = createRootState(
            playerIndex: playerIndex,
            players: players,
            playedCardsThisRound: playedCardsThisRound,
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            difficulty: difficulty
        )
        
        let root = MCTSNode(state: rootState)
        MCTSCache[rootState] = root

        let effectiveIterations = difficulty.iterations
        
        for _ in 0..<effectiveIterations {
            // --- SELECTION ---
            var node = root
            while node.untriedMoves.isEmpty && !node.children.isEmpty {
                if let bestChild = node.bestChild() {
                    node = bestChild
                } else {
                    break
                }
            }
                
            var state = node.state
            var move: Card? = nil

            // --- EXPANSION ---
            if let untriedMove = selectBiasedUntriedMove(moves: node.untriedMoves) {
                move = untriedMove
                state = state.playCard(move!)
                
                let child: MCTSNode
                if let cachedChild = MCTSCache[state] {
                    child = cachedChild
                } else {
                    child = MCTSNode(state: state, parent: node)
                    MCTSCache[state] = child
                }
                
                node.children.append(child)
                node.untriedMoves.removeAll { $0 == move }
                node = child
            }

            // --- SIMULATION & BACKPROPAGATION ---
            let reward = rollout(state: node.state)
            var backNode: MCTSNode? = node
            while let current = backNode {
                current.visits += 1
                current.totalScore += reward
                backNode = current.parent
            }
        }
            
        // 3. Select the move with the best average score (highest reward/lowest score)
        return root.bestMove() ?? legalMoves.randomElement() ?? firstMove
    }

    // --- ROLLOUT & REWARD FUNCTION ---

    /**
     The rollout policy for opponents in the simulation. This must be competitive (avoid points)
     for the simulation to accurately model the outcome of a move.
     */
    private static func rolloutCompetitiveMove(state: HeartsGameState, legalMoves: [Card]) -> Card {
        // --- 1. Leading the Trick ---
        if state.currentTrick.isEmpty {
            // Conservative lead: play the lowest non-point card, otherwise play the lowest card overall.
            let nonPointMoves = legalMoves.filter { $0.points == 0 }
            
            if !nonPointMoves.isEmpty {
                // Play the lowest non-point card to conserve high cards
                return nonPointMoves.min { $0.rank.value < $1.rank.value }!
            }
            // Forced to lead with a point card or only high cards. Play the lowest available.
            return legalMoves.min { $0.rank.value < $1.rank.value }!
        }
        
        // --- 2. Following the Trick ---
        
        let leadSuit = state.currentTrick[0].card.suit
        
        // Check if points are in the trick OR if the player is forced to play a point card (e.g., sloughing)
        let trickHasPoints = state.currentTrick.contains { $0.card.points > 0 } || legalMoves.contains(where: { $0.suit == leadSuit && $0.points > 0 })
        
        // Find the winning rank among played cards of the lead suit
        let winningRankValue = state.currentTrick
            .filter { $0.card.suit == leadSuit }
            .map { $0.card.rank.value }
            .max() ?? 0

        // Separate legal moves into winning and non-winning (ducking) cards
        let winningCards = legalMoves.filter { $0.rank.value > winningRankValue }
        let duckingCards = legalMoves.filter { $0.rank.value <= winningRankValue }
        
        
        // Rule 1: If points are present, try aggressively to duck!
        if trickHasPoints {
            if !duckingCards.isEmpty {
                // Can duck: play the HIGHEST ducking card. This is smart because it saves the lowest cards
                // for later, more critical ducking situations.
                return duckingCards.max { $0.rank.value < $1.rank.value }!
            } else {
                // Forced to win (all legal cards beat the current winner). Play the lowest winner to save high cards.
                return winningCards.min { $0.rank.value < $1.rank.value }!
            }
        }
        
        // Rule 2: If no points are present: Play the lowest card.
        // This is the most conservative play to conserve high cards and possibly win the lead safely.
        return legalMoves.min { $0.rank.value < $1.rank.value }!
    }

    /**
    The reward is now the DIFFERENCE: (Human's Score) - (AI Player's Score).
    Maximizing this difference means the AI is trying to:
    1. Increase the Human's Score (Adversarial).
    2. Decrease its own Score (Self-Interested).
    
    We assume Human Player Index is always 0.
    */
    private static func rollout(state: HeartsGameState) -> Double {
        var state = state
        let playerIndex = state.currentPlayer // The player whose turn it is at the root of the rollout
        let humanIndex = 0 // Assuming human is always player 0 for the AI's adversarial focus

        // 1. CHECK CACHE
        if let cachedScore = terminalCache[state] {
            return cachedScore
        }
        
        var rolloutSteps = 0
        let maxRolloutSteps = 100

        // 2. Playout: use the fast competitive move until terminal state is reached
        let initialState = state // Save the state before rollout starts
        while !state.isTerminal() && rolloutSteps < maxRolloutSteps {
            let legal = state.legalMoves()
            if legal.isEmpty { break }
            
            let move = rolloutCompetitiveMove(state: state, legalMoves: legal)
            state = state.playCard(move)
            rolloutSteps += 1
        }
        
        // 3. Calculate Final Score for all players
        let rawPoints = state.wonCards.map { $0.reduce(0) { $0 + $1.points } }
        let totalPossiblePoints = 26
        
        var moonShooterIndex: Int? = nil
        for i in 0..<rawPoints.count {
            if rawPoints[i] == totalPossiblePoints {
                moonShooterIndex = i
                break
            }
        }
        
        // 4. Determine the final scores for both the AI and the Human
        var finalScores: [Int] = []
        for i in 0..<rawPoints.count {
            finalScores.append(state.score(for: i, rawPoints: rawPoints, moonShooter: moonShooterIndex))
        }

        let humanScore = finalScores[humanIndex]
        let aiScore = finalScores[playerIndex]
        
        // 5. REWARD: Balanced Score Difference (Maximize Human Score relative to AI Score)
        let reward = Double(humanScore - aiScore)

        // 6. CACHE RESULT
        if state.isTerminal() {
            terminalCache[initialState] = reward
        }
        return reward
    }
}
