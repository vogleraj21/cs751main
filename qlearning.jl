
using CSV
using DataFrames
using LinearAlgebra
using Serialization

# Load the dataset
data = CSV.read("traffic_samples.csv", DataFrame)

# Q-learning parameters
γ = 0.99  # Discount factor
α = 0.01  # Learning rate
ε = 1  # Exploration rate
episodes = 100  # Number of episodes

# Define possible actions (e.g., switching light directions)
actions = unique(data[:, :Action])

# Feature vector function (example features based on queues and green light state)
function feature_vector(state, action)
    green_light, queues = state
    return [1.0, green_light, sum(queues), sum(queues)^2, (sum(queues) + green_light)^2, (green_light)^2]
    #return [1.0, green_light, queues[1], queues[2], queues[3], queues[4]]  # Example feature vector
end

# Q-value approximation using weights and feature vector
function Q_value(state, action, weights)
    φ = feature_vector(state, action)
    return dot(weights, φ)
end

# Initialize weights for Q-value approximation
n_features = length(feature_vector((0, [0, 0, 0, 0]), actions[1]))
weights = zeros(n_features)

# Extract the state from a data row
function extract_state(row)
    queues = parse.(Int, split(strip(row[:Queues], ['[', ']']), ","))
    return (row[:GreenLight], queues)
end

# Q-learning algorithm with value function approximation
function q_learning(data, episodes, γ, α, ε)
    for episode in 1:episodes
        for i in 1:(size(data, 1) - 1)  # Ensure we don't go out of bounds
            # Current state and action
            current_row = data[i, :]
            next_row = data[i + 1, :]
            state = extract_state(current_row)
            action = current_row[:Action]
            reward = current_row[:Reward]
            next_state = extract_state(next_row)

            # ε-greedy action selection
            if rand() < ε
                selected_action = rand(actions)  # Exploration
            else
                selected_action = argmax(a -> Q_value(state, a, weights), actions)  # Exploitation
            end

            # Compute the TD error
            φ = feature_vector(state, action)
            best_next_Q = maximum([Q_value(next_state, a, weights) for a in actions])
            td_error = reward + γ * best_next_Q - Q_value(state, action, weights)

            # Update weights
            weights .+= α * td_error .* φ
        end
    end
    return weights
end

# Train the Q-learning algorithm
final_weights = q_learning(data, episodes, γ, α, ε)

# Save the weights for later use
open("weights.jlso", "w") do file
    Serialization.serialize(file, final_weights)
end
