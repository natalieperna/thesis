This repository contains the raw source files of my Master's thesis.

[Download PDF](https://macsphere.mcmaster.ca/handle/11375/22177)

# (Re-)Creating sharing in Agda's GHC backend
**Author**: Natalie Perna\
**Supervisor**: Dr. Wolfram Kahl\
**Institution**: McMaster Univeristy, Department of Computing and Software

## Abstract
Agda is a dependently-typed programming language and theorem prover, supporting proof construction in a functional programming style. Due to its incredibly flexible concrete syntax and support for Unicode identifiers, Agda can be used to construct elegant and expressive proofs in a format that is understandable even to those unfamiliar with the tool. However, the semantics of Agda is lacking resource guarantees of the kind that Haskell programmers are used to with lazy evaluation, where multiple uses of function arguments and let-bound variables still result in the corresponding expressions to be evaluated at most once. With the current compiler backends of Agda, a mathematically-natural way to structure programs therefore frequently results in inefficient compiled programs, where the run-time complexity can be exponentional in cases where corresponding Haskell code executes in linear time. This makes a highly-optimised compiler backend a particularly essential tool for practical development with Agda. The main contributions of this thesis are a series of compiler optimisations that inlines simple projections, removes some expressions with trivial evaluations that can be statically inferred, and reduces the need for repeated evaluations of the same expressions by increasing sharing. We developed transformations that focus on the inherent “loss” of sharing that is frequently the result of compiling Agda programs. Where an Agda developer may imagine that value sharing should exist in the generated Haskell code, it often does not. We present several optimising transformations that re-introduce some of this “lost” sharing without affecting the type-theoretic semantics, then apply these optimisations to several typical Agda applications to examine the memory allocation and execution time effects. In measuring the effects of these optimisations on Agda code we show that overall improvements in runtime on the order of 10-20% are possible. We hope that the development and discussion of these optimisations is useful to the Agda developer community, and may be helpful for future contributors interested in implementing new optimisations for Agda.

**Keywords**: Compiler optimizations; Functional programming; Dependent types; Computer science
