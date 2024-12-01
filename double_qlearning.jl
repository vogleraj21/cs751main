
using CSV
using DataFrames
using LinearAlgebra
using Serialization

# Load the dataset
data = CSV.read("traffic_samples.csv", DataFrame)

# Double Q-learning parameters
γ = 0.99  # Discount factor
α = 0.01  # Learning rate
ε = 0.1  # Exploration rate
episodes = 100  # Number of episodes

# Define possible actions (e.g., switching light directions)
actions = unique(data[:, :Action])

# Feature vector function (example features based on queues and green light state)
function feature_vector2(state, action)
    green_light, queues = state
    return [1.0, green_light, queues[1], queues[2], queues[3], queues[4], action]  # Example feature vector
end

function feature_vector1(state, action)
    green_light, queues = state
    return [1.0, green_light, queues[1], queues[2], queues[3], queues[4], sin(queues[1]), cos(queues[2]), -sin(queues[3]), -cos(queues[4])]  
end

# Q-value approximation using weights and feature vector
function Q_value(state, action, weights)
    φ = feature_vector1(state, action)
    return dot(weights, φ)
end

# Initialize weights for Double Q-learning
n_features = length(feature_vector1((0, [0, 0, 0, 0]), actions[1]))
weights1 = zeros(n_features)
weights2 = zeros(n_features)

# Extract the state from a data row
function extract_state(row)
    queues = parse.(Int, split(strip(row[:Queues], ['[', ']']), ","))
    return (row[:GreenLight], queues)
end

# Double Q-learning algorithm
function double_q_learning(data, episodes, γ, α, ε)
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
                selected_action = argmax(a -> (Q_value(state, a, weights1) + Q_value(state, a, weights2)) / 2, actions)  # Exploitation
            end

            # Choose randomly which Q-function to update
            if rand() < 0.5
                # Update Q1
                best_next_action = argmax(a -> Q_value(next_state, a, weights1), actions)
                td_error = reward + γ * Q_value(next_state, best_next_action, weights2) - Q_value(state, action, weights1)
                φ = feature_vector1(state, action)
                weights1 .+= α * td_error .* φ
            else
                # Update Q2
                best_next_action = argmax(a -> Q_value(next_state, a, weights2), actions)
                td_error = reward + γ * Q_value(next_state, best_next_action, weights1) - Q_value(state, action, weights2)
                φ = feature_vector1(state, action)
                weights2 .+= α * td_error .* φ
            end
        end
    end
    return weights1, weights2
end

# Train the Double Q-learning algorithm
final_weights1, final_weights2 = double_q_learning(data, episodes, γ, α, ε)

# Save the weights for later use
open("weights1.jlso", "w") do file
    Serialization.serialize(file, final_weights1)
end
open("weights2.jlso", "w") do file
    Serialization.serialize(file, final_weights2)
end

