include("Traffic.jl")
using Statistics
using .Traffic
using Serialization
using LinearAlgebra
using Distributions
using DataFrames
using CSV

"""
Simulate the traffic light control problem.
"""
# Simulate the traffic light control problem.
function simulate(config::Configuration, π, file_name::String=nothing; runs=1000, steps=100)
    total_rewards = zeros(runs)
    data = DataFrame(Step=Int[], GreenLight=Int[], Queues=String[], Reward=Float64[], Action=Int[])
    
    for run in 1:runs
        rewards = zeros(steps)
        states = Vector{State}(undef, steps)
        state = initial
        for step in 1:steps
            states[step] = state

            # Policy determines the action
            action = π(state)
            
            # Record the data for CSV output
            queues_str = "[" * join(state.queues, ",") * "]"
            r = reward(config, state, action)
            data = vcat(data, DataFrame(
                Step=[step], GreenLight=[state.green_light], Queues=[queues_str], Reward=[r], Action=[action]
            ))
            
            state = transition(config, state, action)
            rewards[step] = r
        end
        total_rewards[run] = finalreturn(rewards, state) / steps
    end
    
    # Write the CSV file if file_name is provided
    if file_name !== nothing
        CSV.write(file_name, data)
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
    else
        return mod(s.green_light + 1, 4) + 1
    end
end

function most_cars_policy(s::State)
    return argmax(s.queues) # Return the lane with the most cars
end

# Run simulations
println("No Policy Average Reward:       \t", simulate(example, no_policy, "nopoly.csv"))
println("Random Policy Average Reward:   \t", simulate(example, random_policy, "ranpoly.csv"))
println("Naive Policy Average Reward:    \t", simulate(example, naive_policy, "naive.csv"))
println("Most Cars Policy Average Reward:\t", simulate(example, most_cars_policy, "most.csv"))

## Q LEARNING SIMULATION

# Load the learned weights
weights = open("weights.jlso", "r") do file
    Serialization.deserialize(file)
end

# Define the learned policy
function learned_policy(state::State)
    actions = 1:4  # Adjust based on your action space
    feature_vector(state, action) = [1.0, state.green_light, sum(state.queues), sum(state.queues)^2, (sum(state.queues) + state.green_light)^2, (state.green_light)^2]
    # [1.0, state.green_light, sum(state.queues), action]  # Example feature vector
    Q_value(state, action, weights) = dot(weights, feature_vector(state, action))

    # Return the action with the highest Q-value
    return argmax(a -> Q_value(state, a, weights), actions)
end

# Run simulations with the learned policy
println("Learned Q-Learning Policy Average Reward: ", simulate(example, learned_policy, "qlearn.csv"))

## DOUBLE Q LEARNING SIMULATION

# Load the learned weights
weights1 = open("weights1.jlso", "r") do file
    Serialization.deserialize(file)
end

weights2 = open("weights2.jlso", "r") do file
    Serialization.deserialize(file)
end

# Define the learned policy for Double Q-Learning
function learned_policy_double_q(state::State)
    actions = 0:4  # Adjust based on your action space
    feature_vector(state, action) = [1.0, state.green_light, state.queues[1], state.queues[2], state.queues[3], state.queues[4], sin(state.queues[1]), cos(state.queues[2]), -sin(state.queues[3]), -cos(state.queues[4])]
    Q_value(state, action, weights) = dot(weights, feature_vector(state, action))

    # Average Q-values from both Q-functions
    return argmax(a -> (Q_value(state, a, weights1) + Q_value(state, a, weights2)) / 2, actions)
end

# Run simulations with the learned Double Q-Learning policy
println("Learned Double Q-Learning Policy Average Reward: ", simulate(example, learned_policy_double_q, "doubleqlearn.csv"))


## POLICY GRADIENT SIMULATION

# Load Policy Gradient Weights and Actions
policy_gradient_components = deserialize("policy_gradient.jls")
weights, actions = policy_gradient_components

# Feature vector function (example features based on queues and green light state)
function feature_vector(state)
    green_light, queues = state.green_light, state.queues
    return [1.0, green_light, queues[1], queues[2], queues[3], queues[4]]  # Example feature vector
end

# Softmax over parameterized weights
function policy(state, weights)
    features = feature_vector(state)
    preferences = [dot(weights[:, a], features) for a in actions]
    exp_preferences = exp.(preferences .- maximum(preferences)) 
    probs = exp_preferences / sum(exp_preferences)
    return probs
end

# Reconstruct Policy
function reconstruct_policy_gradient(weights, actions)
    return function (state::State)
        probs = policy(state, weights)
        return rand(Categorical(probs)) - 1  # Sample an action
    end
end

# Reconstruct and Simulate Policy Gradient Policy
policy_gradient = reconstruct_policy_gradient(weights, actions)

policy_gradient_result = simulate(example, policy_gradient, "polygrad.csv")
println("Learned Policy Gradient Policy Average Reward: ", policy_gradient_result)