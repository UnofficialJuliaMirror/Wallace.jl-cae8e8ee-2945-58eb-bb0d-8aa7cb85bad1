using state, breeder, evaluator, logger, replacement, criterion, initialiser,
      population

"""
Builder for algorithm.genetic.
"""
type GeneticAlgorithmDefinition
  replacement::Replacement
  loggers::Vector{Logger}
  termination::Dict{AbstractString, Criterion}
  population::PopulationDefinition
  evaluator::Evaluator

  GeneticAlgorithmDefinition() =
    new(replacement.generational(), [], Dict())
end

type GeneticAlgorithm <: Algorithm
  state::State
  evaluator::Evaluator
  replacement::Replacement
  termination::Dict{AbstractString, Criterion}
  loggers::Vector{Logger}
  initialiser::Initialiser
  output::AbstractString

  GeneticAlgorithm() = new()
end

"""
Composes an `algorithm.genetic` instance from information provided within a
supplied builder.
"""
function compose!(b::GeneticAlgorithmDefinition)
  alg = GeneticAlgorithm()
  pop = population.compose!(b.population)
  alg.state = State(pop)
  alg.evaluator = b.evaluator
  alg.replacement = b.replacement
  alg.termination = b.termination
  alg.initialiser = DefaultInitialiser()
  alg.output = abspath(alg.output)
  alg
end

"""
TODO: Explain algorithm.genetic
"""
function genetic(def::Function)
  d = GeneticAlgorithmDefinition()
  def(d)
  d
end

function run!(a::GeneticAlgorithm)
  reset!(a.state)
  prepare!(a.loggers, a.output)
  initialise!(a.initializer, a.state.population)
  evaluate!(a.evaluator, a.state)
  scale!(a.state.population)

  # Record the best individual from the population.
  #pbest = gbest = best(a.state.population)

  prepare!(a.state.population)

  while !any(c -> is_satisfied(c, a.state), values(a.termination))
    breed!(a.state.population)
    evaluate!(a.evaluator, a.state)
    scale!(a.state.population)

    # Record the best individual from the population.
    # --- What does this mean for co-evolution?
    #pbest = best(a.state.population)
    #gbest = best([pbest, gbest])

    replace!(a.replacement, a.state)
    scale!(a.state.population)
    call!(a.loggers, a.state)
    a.state.iterations += 1
  end
  close!(a.loggers)
end
