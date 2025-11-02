import SwiftUI

import Combine



struct GameView: View {

    @StateObject var viewModel = GameViewModel()

    @State private var showDifficultyPicker = false

    @State private var showStatsView = false

    @State private var showSettingsView = false

    @State private var showFirstLaunchPrompt = false

    @State private var showNewGameConfirmation = false

    

    @State private var showRulesView = false

    

    // Animation states

    @State private var showHeartsBreakEffect = false

    @State private var showQueenEffect = false

    @State private var showShootMoonEffect = false

    @State private var flashColor: Color? = nil

    @State private var shakeAmount = 0

    

    // New states for highlighting received cards

    @State private var receivedCards: Set<Card> = []

    @State private var showReceivedHighlight = false

    

    var body: some View {

        ZStack {

            // NEW COLOR: Deep teal/navy background - much more inviting than bright green
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.18, blue: 0.22),  // Deep teal
                    Color(red: 0.12, green: 0.24, blue: 0.28)   // Slightly lighter teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            

            if viewModel.isGameOver {

                gameOverScreen

            } else if !viewModel.gameStarted && !viewModel.isPassing {

                roundCompleteScreen

            } else {

                playingAndPassingContent

            }

            

            // --- TOP BAR ---

            if !viewModel.isGameOver {

                ZStack {

                    VStack {

                        HStack(spacing: 8) {

                            Button("New Game") {

                                // Don't allow during processing or animations

                                if !viewModel.isProcessing {

                                    SoundManager.shared.playButtonClickSound()

                                    showNewGameConfirmation = true

                                }

                            }

                            .font(.caption)

                            .padding(8)

                            .background(Color(red: 0.2, green: 0.5, blue: 0.7).opacity(viewModel.isProcessing ? 0.4 : 0.8))

                            .foregroundColor(.white)

                            .cornerRadius(8)

                            .disabled(viewModel.isProcessing)

                            

                            Button(action: {

                                SoundManager.shared.playButtonClickSound()

                                showSettingsView = true

                            }) {

                                Image(systemName: "gearshape.fill")

                                    .font(.caption)

                                    .padding(8)

                                    .background(Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.8))

                                    .foregroundColor(.white)

                                    .cornerRadius(8)

                            }

                            

                            // Rules button

                            Button(action: {

                                SoundManager.shared.playButtonClickSound()

                                showRulesView = true

                            }) {

                                Image(systemName: "questionmark.circle.fill")

                                    .font(.caption)

                                    .padding(8)

                                    .background(Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.8))

                                    .foregroundColor(.white)

                                    .cornerRadius(8)

                            }

                            

                            Spacer()

                        }

                        Spacer()

                    }

                    .padding(.top, 10)

                    .padding(.leading, 10)

                    

                    VStack {

                        HStack(spacing: 8) {

                            Spacer()

                            

                            Button(action: {

                                SoundManager.shared.playButtonClickSound()

                                showStatsView = true

                            }) {

                                Image(systemName: "chart.bar.fill")

                                    .font(.caption)

                                    .padding(8)

                                    .background(Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.8))

                                    .foregroundColor(.white)

                                    .cornerRadius(8)

                            }

                        }

                        Spacer()

                    }

                    .padding(.top, 10)

                    .padding(.trailing, 10)

                }

            }

            

            // Difficulty Picker Overlay

            if showDifficultyPicker {

                Color.black.opacity(0.4)

                    .ignoresSafeArea()

                    .onTapGesture {

                        showDifficultyPicker = false

                    }

                

                VStack(spacing: 20) {

                    Text("AI Difficulty")

                        .font(.title2)

                        .fontWeight(.bold)

                        .foregroundColor(.white)

                    

                    VStack(spacing: 12) {

                        ForEach(DifficultyLevel.allCases, id: \.self) { level in

                            Button(action: {

                                SoundManager.shared.playButtonClickSound()

                                viewModel.difficulty = level

                                showDifficultyPicker = false

                            }) {

                                HStack {

                                    Text(level.description)

                                        .foregroundColor(.white)

                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    

                                    if viewModel.difficulty == level {

                                        Image(systemName: "checkmark.circle.fill")

                                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))

                                    }

                                }

                                .padding()

                                .background(

                                    viewModel.difficulty == level ?

                                    Color(red: 0.2, green: 0.5, blue: 0.7).opacity(0.8) :

                                    Color.gray.opacity(0.6)

                                )

                                .cornerRadius(10)

                            }

                        }

                    }

                    .padding(.horizontal)

                    

                    Button("Close") {

                        SoundManager.shared.playButtonClickSound()

                        showDifficultyPicker = false

                    }

                    .font(.headline)

                    .padding()

                    .background(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.8))

                    .foregroundColor(.white)

                    .cornerRadius(10)

                }

                .padding()

                .background(Color.black.opacity(0.9))

                .cornerRadius(20)

                .frame(width: 300)

            }

            

            // ANIMATION OVERLAYS

            if showHeartsBreakEffect {

                ParticleEffect(type: .hearts)

                    .allowsHitTesting(false)

            }

            

            if showQueenEffect {

                ParticleEffect(type: .sparkles)

                    .allowsHitTesting(false)

            }

            

            if showShootMoonEffect {

                ZStack {

                    ParticleEffect(type: .moonEmoji)

                    ParticleEffect(type: .stars)

                }

                .allowsHitTesting(false)

            }

            

            if let color = flashColor {

                FlashOverlay(color: color)

            }

        }

        .shake(trigger: shakeAmount)

        .onChange(of: viewModel.animationTrigger) { trigger in

            guard let trigger = trigger else { return }

            

            switch trigger {

            case .heartsBroken:

                flashColor = .red

                showHeartsBreakEffect = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

                    showHeartsBreakEffect = false

                    flashColor = nil

                }

                

            case .queenPlayed:

                flashColor = .black

                showQueenEffect = true

                shakeAmount += 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {

                    flashColor = nil

                    showQueenEffect = false

                }

                

            case .queenWon:

                shakeAmount += 2

                

            case .shootMoon:

                showShootMoonEffect = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {

                    showShootMoonEffect = false

                }

                

            case .trickWon:

                break

            }

        }

        // Monitor for pass completion to highlight received cards

        .onChange(of: viewModel.isPassing) { oldValue, newValue in

            if oldValue == true && newValue == false {

                // Passing just completed, highlight received cards

                // Note: You need to add getReceivedCards method to GameViewModel

                if let received = viewModel.getReceivedCards(for: 0) {

                    receivedCards = Set(received)

                    showReceivedHighlight = true

                    

                    // Hide highlight after 3 seconds

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {

                        withAnimation(.easeOut(duration: 0.3)) {

                            showReceivedHighlight = false

                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {

                            receivedCards.removeAll()

                        }

                    }

                }

            }

        }

        .sheet(isPresented: $showStatsView) {

            StatsView()

        }

        .sheet(isPresented: $showSettingsView) {

            SettingsView()

        }

        .sheet(isPresented: $showRulesView) {

            RulesView()

        }

        .alert("Start New Game?", isPresented: $showNewGameConfirmation) {

            Button("Cancel", role: .cancel) {

                SoundManager.shared.playButtonClickSound()

            }

            Button("New Game", role: .destructive) {

                SoundManager.shared.playButtonClickSound()

                

                // Reset any ongoing states before starting new game

                viewModel.isPassing = false

                viewModel.selectedCardsToPass.removeAll()

                viewModel.playedCards.removeAll()

                viewModel.isProcessing = false

                

                // Clear any animation states

                showHeartsBreakEffect = false

                showQueenEffect = false

                showShootMoonEffect = false

                flashColor = nil

                receivedCards.removeAll()

                showReceivedHighlight = false

                

                // Now safe to start new game

                viewModel.startNewGame()

            }

        } message: {

            Text("This will end your current game. Are you sure?")

        }

        .fullScreenCover(isPresented: $showFirstLaunchPrompt) {

            FirstLaunchNamePrompt(isPresented: $showFirstLaunchPrompt)

                .onDisappear {

                    updatePlayerName()

                }

        }

        .onAppear {

            if GameSettings.shared.isFirstLaunch {

                showFirstLaunchPrompt = true

            }

            updatePlayerName()

        }

    }

    

    private func updatePlayerName() {

        viewModel.updatePlayerName()

    }

    

    // MARK: - Game Over Screen

    var gameOverScreen: some View {

        VStack(spacing: 30) {

            Text("Game Over!")

                .font(.system(size: 50, weight: .bold))

                .foregroundColor(.white)

            

            let winner = viewModel.players.min(by: { $0.score < $1.score })!

            

            Text("\(winner.name) Wins!")

                .font(.largeTitle)

                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))

                .glow(color: Color(red: 1.0, green: 0.84, blue: 0.0), radius: 20)

                .bounceIn()

            

            VStack(spacing: 15) {

                Text("Final Scores:")

                    .font(.title2)

                    .foregroundColor(.white)

                

                ForEach(viewModel.players.sorted(by: { $0.score < $1.score }), id: \.name) { player in

                    HStack {

                        Text(player.name)

                            .foregroundColor(.white)

                            .frame(width: 100, alignment: .leading)

                        

                        Spacer()

                        

                        Text("\(player.score) points")

                            .foregroundColor(.white)

                            .font(.title3)

                    }

                    .padding(.horizontal, 40)

                }

            }

            

            VStack(spacing: 10) {

                Text("AI Difficulty for Next Game")

                    .font(.headline)

                    .foregroundColor(.white)

                

                Picker("Difficulty", selection: $viewModel.difficulty) {

                    ForEach(DifficultyLevel.allCases, id: \.self) { level in

                        Text(level.rawValue).tag(level)

                    }

                }

                .pickerStyle(SegmentedPickerStyle())

                .padding(.horizontal, 40)

            }

            .padding(.top, 10)

            

            Button("New Game") {

                SoundManager.shared.playButtonClickSound()

                

                // Clear animation states

                showHeartsBreakEffect = false

                showQueenEffect = false

                showShootMoonEffect = false

                flashColor = nil

                receivedCards.removeAll()

                showReceivedHighlight = false

                

                viewModel.startNewGame()

            }

            .font(.title2)

            .padding()

            .background(Color(red: 0.4, green: 0.8, blue: 0.6))

            .foregroundColor(.white)

            .cornerRadius(10)

            .padding(.top, 20)

        }

    }

    

    // MARK: - Round Complete Screen

    var roundCompleteScreen: some View {

        VStack(spacing: 20) {

            Text("Round \(viewModel.roundNumber) Complete!")

                .font(.largeTitle)

                .foregroundColor(.white)

            

            if let moonShooter = viewModel.players.first(where: { $0.shotTheMoon }) {

                Text("\(moonShooter.name) SHOT THE MOON! 🌙")

                    .font(.title)

                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))

                    .glow(color: Color(red: 1.0, green: 0.84, blue: 0.0), radius: 15)

                    .padding()

                    .background(Color.black.opacity(0.5))

                    .cornerRadius(10)

            }

            

            VStack(spacing: 10) {

                ForEach(0..<viewModel.players.count, id: \.self) { i in

                    HStack(spacing: 15) {

                        Text(viewModel.players[i].name)

                            .foregroundColor(.white)

                            .frame(width: 80, alignment: .leading)

                        

                        Text("This Round: +\(viewModel.players[i].lastRoundScore)")

                            .foregroundColor(viewModel.players[i].shotTheMoon ? Color(red: 0.4, green: 0.8, blue: 0.6) : Color(red: 1.0, green: 0.84, blue: 0.0))

                            .frame(width: 150, alignment: .leading)

                        

                        Text("Total: \(viewModel.players[i].score)")

                            .foregroundColor(.white)

                            .font(.title3)

                            .frame(width: 80, alignment: .leading)

                    }

                    .padding(.horizontal, 20)

                    .bounceIn()

                }

            }

            

            Button("Start Next Round") {

                SoundManager.shared.playButtonClickSound()

                viewModel.setupGame()

            }

            .font(.title2)

            .padding()

            .background(Color(red: 0.2, green: 0.5, blue: 0.7))

            .foregroundColor(.white)

            .cornerRadius(10)

            .padding(.top, 20)

        }

    }

    

    // MARK: - Playing and Passing Content

    var playingAndPassingContent: some View {

        let playerHand = viewModel.players[0].sortedHand

        let totalCardsInHand = playerHand.count

        

        let isFirstTrick = RuleValidator.isFirstTrick(players: viewModel.players)

        let legalCards = RuleValidator.getLegalCards(

            hand: playerHand,

            playedCards: viewModel.playedCards,

            heartsBroken: viewModel.heartsBroken,

            isFirstTrick: isFirstTrick

        )

        

        return VStack(spacing: 0) {

            ZStack {

                Circle()

                    .fill(Color.black.opacity(0.3))

                    .frame(width: 280, height: 280)

                

                playerInfoView(index: 1, position: .left)

                    .position(x: 40, y: 225)

                playerInfoView(index: 2, position: .top)

                    .position(x: 196, y: 50)

                playerInfoView(index: 3, position: .right)

                    .position(x: 342, y: 225)

                playerInfoView(index: 0, position: .bottom)

                    .position(x: 196, y: 400)

                

                if !viewModel.isPassing {

                    ForEach(Array(viewModel.playedCards.enumerated()), id: \.element.playerIndex) { index, play in

                        let position = getTrickCardPosition(for: play.playerIndex)

                        let isFirstCard = index == 0

                        

                        VStack(spacing: 4) {

                            CardView(card: play.card)

                                .overlay(

                                    RoundedRectangle(cornerRadius: 8)

                                        .stroke(isFirstCard ? Color.red : Color.clear, lineWidth: 3)

                                )

                        }

                        .offset(x: position.x, y: position.y)

                    }

                }

                

                if viewModel.isPassing {

                    VStack(spacing: 15) {

                        Spacer()

                        

                        Button("Confirm Pass (\(viewModel.selectedCardsToPass.count)/3)") {

                            viewModel.submitPass()

                        }

                        .font(.title2)

                        .padding()

                        .background(viewModel.selectedCardsToPass.count == 3 ? Color(red: 0.2, green: 0.5, blue: 0.7) : Color.gray)

                        .foregroundColor(.white)

                        .cornerRadius(10)

                        .disabled(viewModel.selectedCardsToPass.count != 3)

                        .padding(.bottom, 20)

                    }

                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    .background(Color.black.opacity(0.4))

                    .edgesIgnoringSafeArea(.all)

                }

            }

            .frame(height: 450)

            

            if viewModel.isPassing {

                let recipientIndex = viewModel.getPassRecipient(from: 0)

                let recipientName = viewModel.players[recipientIndex].name

                

                Text("Round \(viewModel.roundNumber): Select 3 cards to pass to \(recipientName)")

                    .font(.headline)

                    .foregroundColor(viewModel.selectedCardsToPass.count == 3 ? Color(red: 1.0, green: 0.84, blue: 0.0) : .white)

                    .padding(.vertical, 10)

            } else {

                Spacer()

            }

            

            GeometryReader { geometry in

                ZStack {

                    ForEach(Array(playerHand.enumerated()), id: \.element.id) { index, card in

                        let centerIndex = CGFloat(totalCardsInHand - 1) / 2

                        let normalizedIndex = CGFloat(index) - centerIndex

                        

                        // Better spacing based on card count and screen width

                        let availableWidth = geometry.size.width - 100 // Leave some margin

                        let maxSpacing: CGFloat = 35 // Maximum spacing between cards

                        let minSpacing: CGFloat = 20 // Minimum spacing

                        let optimalSpacing = min(maxSpacing, max(minSpacing, availableWidth / CGFloat(totalCardsInHand)))

                        

                        // Simple horizontal offset with slight curve

                        let xOffset = normalizedIndex * (viewModel.isPassing ? optimalSpacing * 1.2 : optimalSpacing)

                        

                        // Add a gentle arc effect - cards at edges are slightly lower

                        let curveIntensity: CGFloat = 0.8

                        let yOffset = abs(normalizedIndex) * abs(normalizedIndex) * curveIntensity

                        

                        // Rotation for fan effect

                        let rotationAngle = normalizedIndex * (viewModel.isPassing ? 3 : 4)

                        

                        let isSelectedForPassing = viewModel.isPassing && viewModel.selectedCardsToPass.contains(card)

                        let isLegalToPlay = legalCards.contains(card)

                        let isPlayable = viewModel.currentPlayerIndex == 0 && isLegalToPlay

                        let isReceivedCard = receivedCards.contains(card) && showReceivedHighlight



                        CardView(card: card)

                            // Reasonable scaling

                            .scaleEffect(

                                isSelectedForPassing ? 1.1 :

                                (isReceivedCard ? 1.05 : 1.0)

                            )

                            // Keep cards in natural order, with only slight adjustments

                            .zIndex(

                                isSelectedForPassing ? Double(index) + 0.5 :  // Small bump, maintains relative order

                                (isReceivedCard ? Double(index) + 0.3 : Double(index))

                            )

                            // Apply the card-specific overlay

                            .overlay(

                                Group {

                                    if isSelectedForPassing {

                                        // Selection highlight that follows the card

                                        RoundedRectangle(cornerRadius: 8)

                                            .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 4)

                                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0), radius: 3)

                                    } else if isReceivedCard {

                                        // Highlight for received cards

                                        RoundedRectangle(cornerRadius: 8)

                                            .stroke(Color(red: 0.4, green: 0.8, blue: 0.6), lineWidth: 3)

                                            .shadow(color: Color(red: 0.4, green: 0.8, blue: 0.6), radius: 5)

                                            .scaleEffect(isReceivedCard ? 1.0 : 0.95)

                                            .animation(

                                                .easeInOut(duration: 0.6)

                                                .repeatCount(3, autoreverses: true),

                                                value: showReceivedHighlight

                                            )

                                    } else if isPlayable && !viewModel.isPassing {

                                        RoundedRectangle(cornerRadius: 8)

                                            .stroke(Color.white, lineWidth: 2)

                                    }

                                }

                            )

                            // Apply rotation for fan effect

                            .rotationEffect(.degrees(rotationAngle))

                            // Apply position - cards still move up when selected

                            .offset(

                                x: xOffset,

                                y: yOffset + (isSelectedForPassing ? -25 : (isReceivedCard ? -15 : 0))

                            )

                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelectedForPassing)

                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isReceivedCard)

                            .disabled(viewModel.isProcessing || (viewModel.isPassing && !viewModel.players[0].isHuman) || (!viewModel.isPassing && !isPlayable))

                            .opacity(viewModel.isPassing || isPlayable ? 1.0 : 0.4)

                            .onTapGesture {

                                if viewModel.isPassing {

                                    // Add haptic feedback for better touch response

                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                                    viewModel.toggleCardSelection(card)

                                } else if isPlayable {

                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                                    viewModel.playCard(card)

                                }

                            }

                    }

                }

                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            }

            .frame(height: 200)

            .padding(.horizontal, 20)

        }

    }

    

    enum PlayerPosition {

        case left, top, right, bottom

    }

    

    func playerInfoView(index: Int, position: PlayerPosition) -> some View {

        let player = viewModel.players[index]

        let isLastWinner = viewModel.lastTrickWinner == index

        

        return VStack(spacing: 2) {

            Text(player.name)

                .foregroundColor(.white)

                .font(.headline)

            Text("Round: +\(player.roundScore)")

                .foregroundColor(.white)

                .font(.caption)

            Text("Total: \(player.score)")

                .foregroundColor(.white)

                .font(.caption)

            Text("\(player.hand.count) cards")

                .foregroundColor(.white)

                .font(.caption2)

        }

        .padding(8)

        .background(

            isLastWinner && !viewModel.isPassing ? Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.7) : Color(red: 0.15, green: 0.35, blue: 0.45).opacity(0.7)

        )

        .cornerRadius(8)

    }

    

    func getTrickCardPosition(for playerIndex: Int) -> CGPoint {

        switch playerIndex {

        case 0: return CGPoint(x: 0, y: 80)

        case 1: return CGPoint(x: -80, y: 0)

        case 2: return CGPoint(x: 0, y: -80)

        case 3: return CGPoint(x: 80, y: 0)

        default: return CGPoint(x: 0, y: 0)

        }

    }

}



// IMPORTANT: Add this to your GameViewModel class:

/*

extension GameViewModel {

    // Add this method to track and return received cards

    func getReceivedCards(for playerIndex: Int) -> [Card]? {

        // You'll need to track these during the card passing phase

        // Store them when cards are exchanged and return them here

        // For example:

        // return receivedCardsForPlayer[playerIndex]

        

        // Temporary implementation - replace with actual tracking

        return nil

    }

}

*/
