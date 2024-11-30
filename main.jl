include("Traffic.jl")
include("simulate.jl")
include("generatesamples.jl")
using .Traffic

# Example policy: Always let cars through in the current green light direction.
function example_policy(s::State)
    return 1
end

# Run the simulation with the example policy
println("Average reward:", simulate(example_config, example_policy))

# Generate and save samples
samples = sample(example_config, example_policy)
println("Samples saved to traffic_light_samples.csv.")
