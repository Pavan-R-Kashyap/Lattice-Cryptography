globals [
  miners
  current-round
  totalRounds
  rewardCapacity
]

turtles-own [
  isMiner
  isVerifier
  verifierIndex
  timeout
  btc
]

; Initialize the simulation environment
to setup
  clear-all
  set totalRounds 2000
  set rewardCapacity 1.0 ; The reward capacity for every mining round remains the same for the second model too
  
  let num-agents 2000
  let num-miners 50 ; Specify the number of miners
  let num-verifiers 1550 ; Specify the number of verifiers
  let num-regular num-agents - (num-miners + num-verifiers)
  let circle-radius 20
  
  ; Create turtles with different properties
  create-turtles num-agents [
    set shape "person"
    set size 1.5
    
    set timeout random 5 + 1 ; Random timeout between 1 and 5 seconds
    set btc 0
    
    ; Position agents in a circular arrangement
    let angle random-float 360
    let distance1 random-float circle-radius
    let new-xcor distance1 * sin angle
    let new-ycor distance1 * cos angle
    
    ; Assign properties based on whether the turtle is a miner or not
    ifelse (who <= num-miners)
      [ set color pink 
        set isMiner true
        set isVerifier false
        set verifierIndex -1 ; Miners are not verifiers
      ]
      [ ifelse (who <= num-miners + num-verifiers)
        [ set color blue 
          set isMiner false
          set isVerifier true
          set verifierIndex floor (who / (num-verifiers / 5)) ; Assign verifier index
        ]
        [ set color white
          set isMiner false
          set isVerifier false
          set verifierIndex -1 ; Regular entities are not verifiers
        ]
      ]
    
    setxy new-xcor new-ycor
  ]
  
  reset-round
  reset-ticks
end

; Reset the timeout for each turtle at the beginning of a round
to reset-round
  ask turtles [
    set timeout random 5 + 1
  ]
end

; Main simulation loop
to go
  if current-round <= totalRounds [
    let firstMiner nobody ; A new mining round has just begun 
    
    ask turtles [
      if isMiner [
        set timeout timeout - 1
        ; If timeout is reached and this is the first miner, reward BTC
        if timeout <= 0 and firstMiner = nobody [
          let selectedIndex (random 5) ; Randomly select a verifier index
          
          ; Define reward proportions based on verifier index
          let rewardProportions [0.20 0.30 0.50 0.60 0.80] ; 5 verifier indexes each having their reward proportions
          let indexRewardProportion item selectedIndex rewardProportions
          
          set btc btc + ((1 - indexRewardProportion) * rewardCapacity) ; Miner's reward
          
          ; Find verifiers with the selected index and distribute rewards accordingly
          let selectedVerifiers n-of 62 turtles with [isVerifier and verifierIndex = selectedIndex]
          let verifierReward (indexRewardProportion * rewardCapacity) / 62
          ask selectedVerifiers [ set btc btc + verifierReward ]
          
          set firstMiner self  ; Store the first miner
        ]
      ]
    ]
    
    ; Reset the round for miners that didn't mine in this round
    ask turtles with [isMiner] [
      if timeout <= 0 and self != firstMiner [
        reset-round
      ]
    ]
    
    set current-round current-round + 1
    tick
  ]
  
  ; At the end of the simulation, calculate and print the Gini index and total wealth
  if current-round > totalRounds [
    calculate-gini
    stop
  ]
end

; Calculate the Gini index to measure wealth inequality
to calculate-gini
  let wealth-list sort [btc] of turtles
  let n count turtles
  let cumulative-wealths reduce [ [a b] -> a + b ] wealth-list
  let total-wealth sum wealth-list
  
  let gini-sum-numerator 0
  let gini-sum-denominator 0
  let i 0
  
  ; Calculate the Gini index using the formula
  while [i < n] [
    let xi item i wealth-list
    set gini-sum-numerator gini-sum-numerator + (2 * (i + 1) - n - 1) * xi
    set gini-sum-denominator gini-sum-denominator + xi
    set i i + 1
  ]
  
  let gini-index (gini-sum-numerator / (n * gini-sum-denominator))
  print (word "Gini index: " gini-index)
  print (word "Total wealth: " total-wealth)
end
