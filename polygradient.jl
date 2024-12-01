using CSV
using DataFrames
using Random
using LinearAlgebra
using Serialization

# Load the dataset

# Q-learning parameters
γ = 0.99  # Discount factor
α = 0.01  # Learning rate
episodes = 100  # Number of episodes

# Train Policy
println("Loading or generating data...")
data = CSV.read("traffic_samples.csv", DataFrame)
# Define possible actions (e.g., switching light directions)
actions = unique(data[:, :Action])

# Extract the state from a data row
function extract_state(row)
    queues = parse.(Int, split(strip(row[:Queues], ['[', ']']), ","))
    return (row[:GreenLight], queues)
end

# Feature vector function (example features based on queues and green light state)
function feature_vector(state)
    green_light, queues = state
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

# Action Selection Using the Policy
function select_action(state, weights)
    probs = policy(state, weights)
    return rand(Categorical(probs)) - 1
end

# REINFORCE Algorithm from lecture
function reinforce(data, γ, α, episodes)
    println("reinforcing!")
    # Initialize policy parameters (random initialization)
    n_features = 6
    weights = randn(n_features, length(actions))

    for episode in 1:episodes
        # shuffle the data for better generalization
        shuffled_data = data[shuffle(1:size(data, 1)), :]

        for row in eachrow(shuffled_data)
            # Extract state and action
            state = extract_state(row)
            action = row.Action
            reward = row.Reward

            # Compute probabilities using the policy
            probs = policy(state, weights)

            # Compute the gradient of the log-policy
            green_light, queues = state # extract the state
            features = [1.0, green_light, queues[1], queues[2], queues[3], queues[4]]
            gradient = zeros(size(weights))
            for a in actions
                if a == action
                    gradient[:, a] += (1 - probs[a]) * features
                else
                    gradient[:, a] -= probs[a] * features
                end
            end

            # discount reward
            G = reward * γ 

            # Update weights
            weights += α * G * gradient
        end
    end

    return weights
end


println("Training policy using Policy Gradient method...")
trained_weights = reinforce(data, γ, α, episodes)

# Save Policy
println("Saving the trained policy weights...")
serialize("policy_gradient.jls", (trained_weights, actions))
println("Policy saved as policy_gradient.jls")