include("Traffic.jl")
using CSV
using DataFrames
using .Traffic

"""
Generate samples from the simulation.
"""
function sample(config::Configuration, π; runs=10, steps=10000)
    data = DataFrame(
        Step=Int[],
        GreenLight=Int[],
        Queues=Array{Int, 1}[],
        Reward=Float64[],
        Action=Int[]
    )

    for run in 1:runs
        state = initial
        for step in 1:steps
            action = π(state)  # Use policy to decide action
            r = reward(config, state, action)
            data = vcat(data, DataFrame(
                Step=[step],
                GreenLight=[state.green_light],
                Queues=[copy(state.queues)],
                Reward=[r],
                Action=[action]
            ))
            state = transition(config, state, action)
        end
    end
    return data
end

# example policy for generating samples
samples = sample(example, s -> argmax(s.queues))  # Randomly select actions (0 for passing, 1-4 for changing light)
CSV.write("traffic_samples.csv", samples)
println("Samples saved to traffic_samples.csv")
