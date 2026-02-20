//
//  Whist_ScoresTests.swift
//  Whist ScoresTests
//
//  Created by Tony Buffard on 2025-04-03.
//

import Testing
@testable import Whist_Scores

struct Whist_ScoresTests {

    @Test func normalizedTricks_firstRound_clampsAndComputesRemaining() {
        let gameManager = GameManager()
        gameManager.players = ["gg", "dd", "toto"]
        gameManager.currentRound = 0 // 1 card
        
        let normalized = gameManager.normalizedTricksForCurrentRound(from: [
            "gg": 0,
            "dd": 7,
            "toto": 0
        ])
        
        #expect(normalized["gg"] == 0)
        #expect(normalized["dd"] == 1)
        #expect(normalized["toto"] == 0)
    }
    
    @Test func normalizedTricks_firstRound_limitsSecondWhenFirstTakesAll() {
        let gameManager = GameManager()
        gameManager.players = ["gg", "dd", "toto"]
        gameManager.currentRound = 2 // still 1 card
        
        let normalized = gameManager.normalizedTricksForCurrentRound(from: [
            "gg": 1,
            "dd": 1,
            "toto": 1
        ])
        
        #expect(normalized["gg"] == 1)
        #expect(normalized["dd"] == 0)
        #expect(normalized["toto"] == 0)
    }
    
    @Test func submitTricks_usesNormalizedValuesBeforeScoring() {
        let gameManager = GameManager()
        gameManager.players = ["gg", "dd", "toto"]
        gameManager.currentRound = 0
        gameManager.phase = .scoreInput
        gameManager.playerBets = [
            "gg": [0],
            "dd": [0],
            "toto": [1]
        ]
        
        gameManager.submitTricks(tricks: [
            "gg": 0,
            "dd": 9,
            "toto": 0
        ])
        
        #expect(gameManager.playerTricks["gg"]?.first == 0)
        #expect(gameManager.playerTricks["dd"]?.first == 1)
        #expect(gameManager.playerTricks["toto"]?.first == 0)
    }
    
    @Test func assignBonusCards_tieForFirst_stillGivesTwoToLastWhenUnderHalf() {
        let gameManager = GameManager()
        gameManager.players = ["gg", "dd", "toto"]
        gameManager.currentRound = 4
        gameManager.dealer = "gg"
        gameManager.scores = [
            "gg": [40],
            "dd": [100],
            "toto": [100]
        ]
        
        gameManager.assignBonusCards()
        
        #expect(gameManager.bonusCards["gg"] == 2)
    }

}
