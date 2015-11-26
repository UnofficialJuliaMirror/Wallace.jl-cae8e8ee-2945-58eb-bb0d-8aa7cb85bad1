"""
Two ways of implementing options:

<something, ?> OR ?[<something> and <something else>]

The latter is more powerful, but a bit trickier to parse.
For now we'll go with the former, since you can express a more complex optional
section as a separate rule.
"""

const rule_regex = r"<[\w_]+(,\s*[\?|\+|\*])?>"

#grammar(max_wraps = 2) do g
#  # Should retreive <val> from grammar, rather than fetching rule each time
#  # it's called.
#  rule(g, "exp", "(<exp>)", "<val>", "<op>")
#  rule(g, "op", "<exp> * <exp>", "<exp> - <exp>", "<exp> + <exp>")
#  rule(g, "val", "x", "y", "<num>")
#  rule(g, "num", "<digit, +>") # this one is the trickiest to deal with.
#end

"""
The base type for all grammar rules.
"""
abstract Rule

type Grammar
  rules::Dict{AbstractString, Rule}

  Grammar() = new(Dict{AbstractString, Rule}())
end

"""
Parses a single option for a grammar rule and returns a Rule object encoding
that rule.
"""
function rule(r::AbstractString)
  if search(r, rule_regex) != 0:-1
    NonTerminalRule(r)
  else
    TerminalRule(parse(r))
  end
end

function rule(g::Grammar, name::AbstractString, options...)

end

"""
An OR rule allows a given grammar rule to be interpreted in a number of
different ways.
"""
immutable OrRule <: Rule
  num_rules::Int
  rules::Vector{Rule}
end

"""
The ONE-OR-MORE rule (<x, +>) allows a grammar rule to be applied more than
once and at least once.
"""
immutable OneOrMoreRule <: Rule
  rule::Rule
end

"""
The ZERO-OR-MORE rule (<x, *>) allows a grammar rule to be applied
an arbitrary number of times, or not applied at all.
"""
immutable ZeroOrMoreRule <: Rule
  rule::Rule
end

"""
The OPTIONAL rule (<x, ?>) allows a grammar rule to be optionally applied at
most once.
"""
immutable OptionalRule <: Rule
  rule::Rule
end

"""
Due to Julia's current implementation of anonymous functions, this type isn't
quite as efficient as it could be.
"""
immutable NonTerminalRule <: Rule
  builder::Function # (Grammar, Task) -> Expr
end

immutable TerminalRule <: Rule
  value

  TerminalRule(val) = new(val)
end

"""
Selects an interpretation of a given OR rule according to an index provided by
a given codon sequence.
"""
derive(g::Grammar, r::OrRule, nxt::Task) =
  derive(g, g.rules[(consume(nxt) % num_rules) + 1], nxt)

derive(g::Grammar, r::TerminalRule, nxt::Task) =
  r.value

derive(g::Grammar, r::NonTerminalRule, nxt::Task) =
  r.builder(g, nxt)

derive(g::Grammar, nxt::Task) =
  derive(g, g.rules[:root], codons)

"""
Derives a Julia expression (in the form of an Expr) using a provided sequence
of codons, a maximum number of wrappings, and a given grammar.
"""
function derive(g::Grammar, r::Rule, nxt::Task)
  i1 = derive(g, g.rules[:num], nxt)
  i2 = derive(g, g.rules[:num], nxt)
  Expr(:call, :add, i1, i2)
end

function parse_non_terminal_rule(r::AbstractString)

end

# Find and replace @num with placeholder symbol.
function inject_placeholder(r::AbstractString)
  # Create an arrray to hold the non-terminal symbols within the given rule.
  tags = AbstractString[]

  # Replace each grammar symbol in the given string with an associated
  # placeholder tag.
  function replacer(tag::AbstractString)
    push!(tags, string(tag))
    "__WALLACE_GRAMMAR_TAG_$(length(tags))__"
  end
  r = replace(r, r"<(\w+)>", replacer)

  # Now parse the rule definition to a Julia expression and then back into
  # Julia code (in the form a string).
  r = expr_to_def_s(parse(r))

  # Replace each placeholder with a call to the appropriate function.
  for (i, tag) in enumerate(tags)
    r = replace(r, ":__WALLACE_GRAMMAR_TAG_$(i)__", "derive(g, NT[$(i)], nxt)")
  end

  println(r)
end

# Converts a given Expr into Julia code capable of reproducing that Expr.
expr_to_def_s(ex::Expr) =
  "Expr($(join(vcat([":$(ex.head)"], map(expr_to_def_s, ex.args)), ", ")))"
expr_to_def_s(sym::Symbol) = ":$(sym)"
expr_to_def_s(a::Any) = string(a)



"""
TESTING!
"""
example = "add(<num>, <num>)"
inject_placeholder(example)