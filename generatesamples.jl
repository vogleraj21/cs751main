include("Traffic.jl")
using .Traffic
using CSV
using DataFrames

"""
Generate samples from the simulation.
"""
function sample(config::Configuration, π; runs=100, steps=50)
    data = DataFrame(Step=Int[], GreenLight=Int[], Queues=Array{Int, 1}[], Reward=Float64[], Action=Int[])

    for run in 1:runs
        state = initial_state
        for step in 1:steps
            action = π(state)
            r = reward(config, state, action)
            data = vcat(data, DataFrame(Step=[step], GreenLight=[state.green_light], 
                                        Queues=[copy(state.queues)], Reward=[r], Action=[action]))
            state = transition(config, state, action)
        end
    end
    return data
end

samples = sample(example_config, s -> 1)  # Example: Always let cars pass
CSV.write("traffic_samples.csv", samples)
