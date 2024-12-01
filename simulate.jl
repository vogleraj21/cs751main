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
        state = initial
        for step in 1:steps
            states[step] = state

            # BEGIN: Policy determines the action
            action = π(state)
            # END

            state = transition(config, state, action)
            rewards[step] = reward(config, state, action)
        end
        total_rewards[run] = finalreturn(rewards, state)/steps
    end
    return mean(total_rewards)
end

# Example policies
function no_policy(s::State)
    return 0 # Always let cars pass in the current direction
end

function random_policy(s::State)
    return rand(0:4) # Randomly decide to let a car pass or change direction
end

function naive_policy(s::State) # Empty current lane then move to next
    if s.queues[s.green_light] > 0
        return 0
    end
    return mod(s.green_light + 1, 4) + 1
end

function most_cars_policy(s::State)
    return argmax(s.queues) # Return the lane with the most cars
end

function amalgam_policy(s::State)
    if s.queues[s.green_light] > 0
        return 0
    end
    return argmax(s.queues)
end

# Run simulations
println("No Policy Average Reward:       \t", simulate(example, no_policy))
println("Random Policy Average Reward:   \t", simulate(example, random_policy))
println("Naive Policy Average Reward:    \t", simulate(example, naive_policy))
println("Most Cars Policy Average Reward:\t", simulate(example, most_cars_policy))
println("Amalgam Policy Average Reward:  \t", simulate(example, amalgam_policy))
