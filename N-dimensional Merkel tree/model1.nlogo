globals [
  miners
  current-round
  totalRounds
  rewardCapacity
]
; Attributes associated with every turtle/entity in the simulated environment
turtles-own [
  isMiner
  timeout
  btc
]

; Initialize the simulation environment
to setup
  clear-all
  set totalRounds 200000
  set rewardCapacity 1.0 ; Currently the reward is set to 1BTC for every successful mining round
  
  let num-agents 150
  let num-miners 50 ; Specify the number of miners
  let circle-radius 20
  
  ; Create turtles with different properties
  create-turtles num-agents [
    set shape "person"
    set size 1.5
    
    set timeout random 5 + 1 ; Random timeout between 1 and 5 seconds
    set btc 0
    
    ; Position agents in a circular arrangement for visualization
    let angle random-float 360
    let distance1 random-float circle-radius
    let new-xcor distance1 * sin angle
    let new-ycor distance1 * cos angle
    setxy new-xcor new-ycor
    
    ; Assign properties based on whether the turtle/entity is a miner or not
    ifelse (who <= num-miners)
      [ set color blue
        set isMiner true ]
      [ set color white
        set isMiner false ]
  ]
  
  reset-round
  reset-ticks
end

; Reset the timeout for each turtle/entity at the beginning of a round
to reset-round
  ask turtles [
    set timeout random 5 + 1
  ]
  
  ; set current-round 0 
end

; Main simulation loop
to go
  if current-round <= totalRounds [
    let firstMiner nobody ;A new mining round has just begun
    
    ; Loop through all turtles/entities to simulate mining behavior
    ask turtles [
      if isMiner [
        set timeout timeout - 1
        ; If timeout is reached and this is the first miner, reward BTC
        if timeout <= 0 and firstMiner = nobody [
          set btc btc + rewardCapacity
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
