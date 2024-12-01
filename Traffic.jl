module Traffic

using Distributions

"""
Configuration of the traffic light problem.
"""
struct Configuration
    arrival_probabilities :: Vector{Float64}  # Probabilities of cars arriving in each direction
    change_penalty :: Float64                 # Penalty for changing the green light

    function Configuration(arrival_probabilities, change_penalty)
        length(arrival_probabilities) == 4 || error("There must be 4 arrival probabilities.")
        new(arrival_probabilities, change_penalty)
    end
end

export Configuration

# 0.0804: probability for only one car to be expected to enter the intersection at a time step
const example = Configuration([.2, .2, .2, .2], 1.0)

export example

"""
State of the intersection.
"""
struct State
    green_light :: Int
    queues :: Vector{Int}

    function State(green_light, queues)
        (1 ≤ green_light ≤ 4) || error("Green light index must be between 1 and 4.")
        length(queues) == 4 || error("There must be 4 queue values.")
        all(q -> q ≥ 0, queues) || error("Queue values must be non-negative.")
        new(green_light, queues)
    end
end

export State

const initial = State(1, [0, 0, 0, 0])
export initial

"""
Reward function.
"""
function reward(config::Configuration, s::State, action::Int)
    # Penalty for waiting cars
    waiting_penalty = -sum(s.queues)
    # Additional penalty for changing the green light
    #change_penalty = (action != 0 && action != s.green_light) ? -config.change_penalty : 0
    # positive reward for empty intersection
    intersection_reward = waiting_penalty == 0 ? 1 : 0
    return waiting_penalty + intersection_reward # + change_penalty 
end

export reward

"""
Transition function.
"""
function transition(config::Configuration, s::State, action::Int)
    new_queues = copy(s.queues)
    green_light = s.green_light

    if action == 0 || action == green_light
        # Let a car pass in the current green light direction
        new_queues[green_light] = max(0, new_queues[green_light] - 1)
    elseif action in 1:4
        # Change the green light to the specified direction
        green_light = action
    else
        error("Invalid action. Action must be 0 (let car through) or 1-4 (change green light).")
    end

    # Simulate car arrivals
    for i in 1:4
        if rand() < config.arrival_probabilities[i]
            new_queues[i] += 1
        end
    end

    return State(green_light, new_queues)
end



export transition

"""
Final return function (if needed).
"""
function finalreturn(rewards::Vector{Float64}, finalstate::State)
    -sum(rewards)
end

export finalreturn

end

