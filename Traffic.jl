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

const example = Configuration([0.3, 0.3, 0.3, 0.3], 2.0)

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
    waiting_penalty = -sum(s.queues)
    change_penalty = (action == 2) ? -config.change_penalty : 0
    return waiting_penalty + change_penalty
end

export reward

"""
Transition function.
"""
function transition(config::Configuration, s::State, action::Int)
    new_queues = copy(s.queues)  # Copy queues to modify
    green_light = s.green_light

    if action == 1
        # Let a car pass in the current green light direction
        new_queues[s.green_light] = max(0, new_queues[s.green_light] - 1)
    elseif action == 2
        # Change the green light to a different direction
        green_light = mod(s.green_light, 4) + 1
    else
        error("Invalid action. Action must be 1 or 2.")
    end

    # Simulate car arrivals
    for i in 1:4
        if rand() < config.arrival_probabilities[i]
            new_queues[i] += 1
        end
    end

    # Return a new state
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

