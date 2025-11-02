import Foundation

// NOTE: The Card, Suit, and Rank types must be defined in your main project files
// for this passing strategy implementation to compile and function correctly.

class AIPassingStrategy {
    
    /**
     Choose up to 3 cards to pass based on a heuristic focused on dumping points,
     especially high spades and high hearts, while preserving low "escape" cards.
     
     - Parameter hand: The AI player's current 13-card hand.
     - Returns: An array of up to 3 cards to be passed.
     */
    static func selectCardsToPass(hand: [Card]) -> [Card] {
        guard !hand.isEmpty else { return [] }
        
        // --- Helper Functions (relying on external Card/Rank/Suit) ---
        func isQSpade(_ c: Card) -> Bool { c.rank == .queen && c.suit == .spades }
        // J, Q, K, A (High value cards)
        func isHigh(_ c: Card) -> Bool { c.rank.value >= Rank.jack.value }
        // 2, 3, 4, 5 (Good "escape" cards to lose lead)
        func isLow(_ c: Card) -> Bool { c.rank.value <= 5 }

        // Count suits for tactical analysis
        let suitCounts = Dictionary(grouping: hand, by: { $0.suit }).mapValues { $0.count }
        
        // Score each card (higher score = more desirable to pass)
        var scores: [(card: Card, score: Int)] = hand.map { ($0, 0) }

        for i in 0..<scores.count {
            var score = 0
            let c = scores[i].card

            // 1) Queen of Spades (Base Danger Score)
            if isQSpade(c) {
                let spadeCount = suitCounts[.spades] ?? 0
                // Massive score (350). Reduced if the player has 5+ spades (strong protection).
                score += (spadeCount >= 5) ? 100 : 350
            }

            // 2) Dangerous Spades (A/K protection cards)
            if c.suit == .spades && !isQSpade(c) {
                switch c.rank {
                case .ace: score += 180 // Extremely dangerous to hold without Q
                case .king: score += 140
                default: break
                }
            }

            // 3) Hearts (Point Cards)
            if c.suit == .hearts {
                // Score proportional to rank (A is 14 points, 2 is 2 points)
                score += c.rank.value * 10
            }

            // 4) High Off-Suit Cards (Clubs/Diamonds) to create Voids
            if (c.suit == .clubs || c.suit == .diamonds) && isHigh(c) {
                let count = suitCounts[c.suit] ?? 0
                // Score based on rank + huge bonus if short suit (<= 2 cards)
                score += 50 + (c.rank.value - 10) * 12
                score += (count <= 2) ? 80 : 0
            }

            // 5) Singleton Bonus (Aggressively seeking voids for sloughing)
            let countInSuit = suitCounts[c.suit] ?? 0
            if countInSuit == 1 {
                // Big bonus for non-spade singletons, slightly less for spades (need control)
                score += (c.suit == .spades) ? 40 : 100
            }
            
            // 6) Penalize passing low "safe" cards
            if isLow(c) {
                // Keep the lowest 2s/3s/4s for safe leading and ducking
                score -= 50
            }

            // 7) Tie-breaker: higher rank -> slight bonus
            score += c.rank.value

            scores[i].score = score
        }

        // Sort descending by score
        let ordered = scores.sorted { $0.score > $1.score }.map { $0.card }

        // --- Final Selection Logic: Limit defensive passes ---
        
        var picks: [Card] = []
        var nonQSpadesPicked = 0
        // Limit the number of non-Q♠ high spades (A/K) we pass, as they are crucial protection
        let maxNonQSpadesToPass = 1

        for c in ordered {
            if picks.count == 3 { break }

            let isCurrentQSpade = isQSpade(c)
            let isCurrentHighSpade = c.suit == .spades && c.rank.value >= Rank.king.value

            if c.suit == .spades {
                if isCurrentQSpade {
                    // Always pass Q♠ if it ranks highly
                    picks.append(c)
                } else if isCurrentHighSpade && nonQSpadesPicked < maxNonQSpadesToPass {
                    // Pass A/K of Spades only if we haven't hit the limit
                    picks.append(c)
                    nonQSpadesPicked += 1
                } else if !isCurrentHighSpade {
                    // Pass medium/low spades freely if slots are available
                    picks.append(c)
                }
            } else {
                // Always pick non-spade cards (Hearts, Clubs, Diamonds)
                picks.append(c)
            }
        }
        
        // Fallback: If we couldn't find 3 highly-scored cards (e.g., due to the spade limit),
        // fill the remaining slots with the next best available cards.
        while picks.count < 3 {
            if let nextCard = ordered.first(where: { !picks.contains($0) }) {
                picks.append(nextCard)
            } else {
                break
            }
        }
        
        return Array(picks.prefix(3))
    }
}
