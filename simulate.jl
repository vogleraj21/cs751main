include("Traffic.jl")
using .Traffic
using Statistics

"""
Simulate the traffic light strategy.
"""
function simulate(config::Configuration, π; runs=1000, steps=100)
    total_rewards = zeros(runs)
    for run in 1:runs
        state = initial_state
        rewards = 0.0
        for step in 1:steps
            action = π(state)
            rewards += reward(config, state, action)
            state = transition(config, state, action)
        end
        total_rewards[run] = rewards
    end
    return mean(total_rewards)
end

export simulate
