include("Traffic.jl")
using Statistics
using .Traffic

"""
Simulate the traffic light control problem.
"""
function simulate(config::Configuration, π; runs=1000, steps=100)
    total_rewards = zeros(runs)
    for run in 1:runs
        rewards = zeros(steps)
        states = Vector{State}(undef, steps)
        state = initial_state
        for step in 1:steps
            states[step] = state

            # BEGIN: Policy determines the action
            action = π(state)
            # END

            state = transition(config, state, action)
            rewards[step] = reward(config, state, action)
        end
        total_rewards[run] = finalreturn(rewards, state)
    end
    return mean(total_rewards)
end

# Example policies
function example_policy_1(s::State)
    return 1  # Always let cars pass in the current direction
end

function example_policy_2(s::State)
    return rand(1:2)  # Randomly let a car pass or change direction
end

# Run simulations
println("Example Policy 1 Average Reward: ", simulate(example_config, example_policy_1))
println("Example Policy 2 Average Reward: ", simulate(example_config, example_policy_2))
