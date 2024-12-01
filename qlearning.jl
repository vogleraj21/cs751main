module Qlearning

include("traffic.jl")


using .Traffic
using CSV
using DataFrames

# Load the dataset
function load_data(filepath::String)
    return CSV.read(filepath, DataFrame)
end

states = [(l, a, b, c, d) for l in 1:4, a in 0:10, b in 0:10, c in 0:10, d in 0:10]
export states

actions = 0:4
export actions

# Convert balance to 1 of 6 states
function discretize(green::Int, queues::Vector)
    return (green, 
        queues[1] > 10 ? 10 : queues[1], 
        queues[2] > 10 ? 10 : queues[2], 
        queues[3] > 10 ? 10 : queues[3], 
        queues[4] > 10 ? 10 : queues[4])
end

export discretize

# Extract policy
function extract_policy(Q)
    policy = Dict()
    for s in states
        best_action = argmax([Q[(s, a)] for a in actions])
        policy[s] = actions[best_action]
    end
    return policy
end

# Prints a policy
function print_policy(policy::Dict)
    for s in states
        println(s," => ",policy[s])
    end
end

export print_policy

# Q Learning
function q_learning(; step = 0.1, discount = 0.9, iterations = 10)
    Q = Dict()

    for s in states
        for a in actions
            Q[(s, a)] = 0.0
        end
    end

    data = load_data("traffic_samples.csv")

    for _ in 1:iterations
        for i in 1:nrow(data) - 1

            # Skip transition from last step of a run
            if data.Step[i] == 100
                continue  
            end

            # Get balance of current and next state
            balance = discretize(data.GreenLight[i], parse.(Int, split(strip(data.Queues[i], ['[', ']']), ",")))
            next_balance = discretize(data.GreenLight[i+1], parse.(Int, split(strip(data.Queues[i+1], ['[', ']']), ",")))

            # Get reward and action of this state
            action, reward = data.Action[i], data.Reward[i]
            
            # Q-value update
            max_q_next = maximum(Q[(next_balance, a)] for a in actions)
            Q[(balance, action)] += step * (reward + discount * max_q_next - Q[(balance, action)])
        end
    end

    # Get the policy
    policy = extract_policy(Q)

    return policy
end

export q_learning

end